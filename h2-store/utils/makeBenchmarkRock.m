function rock = makeBenchmarkRock(G, deck)
    % MAKEBENCHMARKROCK Map benchmark deck properties to active grid cells.
    %
    % SYNOPSIS:
    %   rock = makeBenchmarkRock(G, deck)
    %
    % deck must be converted to SI units. PERMX, PERMY, PERMZ, PORO and SATNUM
    % contain one value per logical deck cell. G.cells.indexMap selects the
    % corresponding values in active-cell order. Permeability is diagonal,
    % porosity is dimensionless and saturation-region IDs retain their deck values.
    %
    % SEE ALSO:
    %   modelForUHSModifiedBenchmark, makeRock, convertDeckUnits

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
    cells = G.cells.indexMap;
    permeability = [deck.GRID.PERMX, deck.GRID.PERMY, deck.GRID.PERMZ];
    rock = makeRock(G, permeability(cells, :), deck.GRID.PORO(cells));
    rock.regions.saturation = deck.REGIONS.SATNUM(cells);
end
