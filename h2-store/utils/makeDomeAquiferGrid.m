function [G, layers] = makeDomeAquiferGrid(horizontalCells)
%MAKEDOMEAQUIFERGRID Build the corner-point grid and geological layer masks.
%
% SYNOPSIS:
%   [G, layers] = makeDomeAquiferGrid()
%   [G, layers] = makeDomeAquiferGrid([nx, ny])
%
% The default horizontal resolution is [51, 51] over a 5000 m square. Two
% initial vertical cells are padded by 100 m at each end, then subdivided
% eightfold to produce 32 layers. A 100 m Gaussian dome of width 500 m is
% centered at [2500, 2500]. Depth offsets are -300 m before padding and
% -450 m after refinement. Coordinates and geometry use meters.
%
% layers contains logical column masks: underrock (layers 1:8), bedrock
% (9:12), caprock (20:24), toprock (25:32), and the remaining aquifer cells.
% Grid construction does not create figures.
%
% Requires the MRST deckformat and vemmech modules (padGrdecl).
%
% SEE ALSO:
%   modelForDome3DAquifer, dome3DModel, makeDomeAquiferRock

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}
    require deckformat vemmech;
    if nargin == 0
        horizontalCells = [51, 51];
    end
    validateattributes(horizontalCells, {'numeric'}, ...
        {'vector', 'numel', 2, 'integer', 'positive', 'finite'});
    resolution = [reshape(horizontalCells, 1, []), 2];
    dimensions = [5000, 5000, 100];
    grdecl = simpleGrdecl(resolution, 0, 'undisturbed', true, 'flat', true);
    grdecl.COORD(1:3:end) = grdecl.COORD(1:3:end)*dimensions(1);
    grdecl.COORD(2:3:end) = grdecl.COORD(2:3:end)*dimensions(2);
    grdecl.COORD(3:3:end) = grdecl.COORD(3:3:end)*dimensions(3);
    grdecl.ZCORN = grdecl.ZCORN*dimensions(3)*2;
    [X, Y, Z] = buildCornerPtNodes(grdecl);
    Z = Z + 100.*exp(-(X - 2500).^2/(2*500^2) - (Y - 2500).^2/(2*500^2));
    grdecl.ZCORN = reshape(Z - 300, 1, []);
    grdecl = padGrdecl(grdecl, [0, 0, 1], [0, 0; 0, 0; 100, 100]);
    grdecl = refineGrdecl(grdecl, [1, 1, 8]);
    G = processGRDECL(grdecl);
    G.nodes.coords(:, 3) = G.nodes.coords(:, 3) - 450;
    G = computeGeometry(G);
    [~, ~, k] = ind2sub(G.cartDims, G.cells.indexMap);
    layers.underrock = ismember(k, 1:8);
    layers.bedrock = ismember(k, 9:12);
    layers.toprock = ismember(k, 25:32);
    layers.caprock = ismember(k, 20:24);
    layers.aquifer = ~layers.bedrock & ~layers.caprock & ...
        ~layers.underrock & ~layers.toprock;
end
