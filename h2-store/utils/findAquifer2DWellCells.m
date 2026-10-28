function cells = findAquifer2DWellCells(G, rock)
    % FINDAQUIFER2DWELLCELLS Locate completions beneath the 2D aquifer crest.
    %
    % SYNOPSIS:
    %   cells = findAquifer2DWellCells(G, rock)
    %
    % PARAMETERS:
    %   G    - Grid from modelForSimple2DAquifer, with cell centroids in meters.
    %   rock - Rock structure with one porosity per cell.
    %
    % RETURNS:
    %   cells - Column vector of cell indices with abs(x - 25) < 0.1 and
    %           25 < abs(y) < 29.5. All geometric matches are returned in grid
    %           order. If none match, select the cell with porosity > 0.1 nearest
    %           to [25, 28.5]. A distance tie selects the first eligible cell.
    %
    % The fallback supports coarse grids that miss the narrow completion window.
    % It raises h2sim:h2store:NoWellCells if there are no eligible reservoir cells.
    %
    % SEE ALSO:
    %   modelForSimple2DAquifer, addWell

    %{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

MRST is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with MRST. If not,
see <http://www.gnu.org/licenses/>.
%}
    coordinates = G.cells.centroids;
    cells = find(abs(coordinates(:, 1) - 25) < 0.1 & ...
        abs(coordinates(:, 2)) > 25 & ...
        abs(coordinates(:, 2)) < 29.5);
    if isempty(cells)
        candidates = find(rock.poro > 0.1);
        assert(~isempty(candidates), 'h2sim:h2store:NoWellCells', ...
            'No completion cells or reservoir cells with porosity > 0.1 were found.');
        distances = sum((coordinates(candidates, :) - [25, 28.5]).^2, 2);
        [~, closest] = min(distances);
        cells = candidates(closest);
    end
end
