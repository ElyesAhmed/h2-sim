function bc = makeBenchmarkBoundaryConditions(G, options)
    % MAKEBENCHMARKBOUNDARYCONDITIONS Set prescribed benchmark boundary pressures.
    %
    % SYNOPSIS:
    %   bc = makeBenchmarkBoundaryConditions(G, options)
    %
    % G is a three-dimensional grid. Boundary faces whose area-weighted normal
    % has a vertical component greater than 2.48 are excluded. This criterion
    % includes downward-facing boundaries and depends on face area.
    % Pressure is options.initPres [Pa] plus 998 kg/m^3 times the scalar product
    % of (face centroid - [1140, 1140, 1140]) [m] and the current gravity vector.
    % options.initSat supplies oil/gas saturations; brine occupies the oil phase.
    % The helper reads the current gravity setting without changing it.
    %
    % SEE ALSO:
    %   modelForUHSModifiedBenchmark, boundaryFaces, addBC

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
    faces = boundaryFaces(G);
    faces = faces(~(G.faces.normals(faces, 3) > 2.48));
    displacement = bsxfun(@minus, G.faces.centroids(faces, :), 1140);
    pressure = options.initPres + 998 .* (displacement * reshape(gravity, [], 1));
    bc = addBC([], faces, 'pressure', pressure, 'sat', options.initSat);
end
