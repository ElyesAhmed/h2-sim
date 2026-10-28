function cells = findDomeAquiferWellCells(G)
%FINDDOMEAQUIFERWELLCELLS Select the first two dome storage completions.
%   cells = findDomeAquiferWellCells(G) returns the first two cells in grid
%   order with abs(x - 2500) < 0.45 m, abs(y - 2500) < 0.2 m and z > -600 m.
%   At least two matches are required; cells are not reordered by depth.

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
    coordinates = G.cells.centroids;
    cells = find(abs(coordinates(:, 1) - 2500) < 0.45 & ...
        abs(coordinates(:, 2) - 2500) < 0.2 & coordinates(:, 3) > -600);
    assert(numel(cells) >= 2, 'h2sim:h2store:DomeWellCells', ...
        'The dome grid must contain at least two cells in the completion window.');
    cells = cells(1:2);
end
