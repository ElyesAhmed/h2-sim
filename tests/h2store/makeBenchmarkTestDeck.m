function deck = makeBenchmarkTestDeck()
    % MAKEBENCHMARKTESTDECK Synthetic Cartesian benchmark grid with bundled fluid tables.
    %   The 61-by-61-by-12 grid accommodates the fixed benchmark completions and
    %   radii. Permeability is in mD for the metric deck; lengths are in meters.
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    file = fullfile(root, 'h2-store', 'examples', 'data', ...
        'Aquifer2D', 'H2STORAGE_RS.DATA');
    deck = readEclipseDeck(file);
    % Fixed benchmark completions require at least 43,101 cells.
    grid = cartesianGrdecl(0:100:6100, 0:100:6100, 1100:10:1220);
    count = prod(grid.cartDims);
    grid.PERMX = repmat(100, count, 1);
    grid.PERMY = grid.PERMX;
    grid.PERMZ = grid.PERMX;
    grid.PORO = repmat(0.25, count, 1);
    deck.GRID = grid;
    deck.RUNSPEC.DIMENS = grid.cartDims;
    deck.REGIONS = struct('SATNUM', ones(count, 1));
    deck.EDIT = struct();
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of h2sim.

h2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

h2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with h2sim.  If not, see <http://www.gnu.org/licenses/>.
%}
