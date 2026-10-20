function x = dimensionlessCellDistance(G)
% Cell-center x/L measured from the left domain boundary, not first cell.
bounds = [min(G.nodes.coords(:,1)), max(G.nodes.coords(:,1))];
assert(all(isfinite(bounds)) && bounds(2)>bounds(1), ...
    'The grid must have a positive finite extent in x.');
x = (G.cells.centroids(:,1)-bounds(1))/(bounds(2)-bounds(1));
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).

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
