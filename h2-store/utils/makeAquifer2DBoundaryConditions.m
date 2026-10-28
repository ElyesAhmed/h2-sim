function bc = makeAquifer2DBoundaryConditions(G, fluid, options)
%MAKEAQUIFER2DBOUNDARYCONDITIONS Pressure boundaries for the 50 m aquifer.
%
% SYNOPSIS:
%   bc = makeAquifer2DBoundaryConditions(G, fluid, options)
%
% PARAMETERS:
%   G       - Grid with geometry in meters. Boundary faces at x = 0 and
%             x = 50 are selected using an absolute tolerance of eps.
%   fluid   - Black-oil fluid with brine surface density rhoOS [kg/m^3].
%   options - Structure with initPres [Pa] and initSat, the inflow composition
%             in black-oil phase order (brine is the oil phase).
%
% RETURNS:
%   bc - MRST pressure boundary conditions, ordered left faces then right
%        faces. Pressure is initPres + 3 bar + rhoOS*(centroid*gravityVector).
%        Other boundary faces have no explicit condition (closed boundaries).
%
% On a 2D grid, gravityVector is [0, -norm(gravity)], so pressure decreases
% with increasing y. On a 3D grid, the current MRST gravity vector is used.
%
% SEE ALSO:
%   modelForSimple2DAquifer, addBC, gravity

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
    if G.griddim < 3
        gravityVector = [0, -norm(gravity)];
    else
        gravityVector = gravity;
    end
    boundary = boundaryFaces(G);
    left = boundary(abs(G.faces.centroids(boundary, 1)) < eps);
    right = boundary(abs(G.faces.centroids(boundary, 1) - 50) < eps);
    referencePressure = options.initPres + 3 * barsa();
    bc = [];
    for faces = {left, right}
        selected = faces{1};
        pressure = referencePressure + fluid.rhoOS .* ...
            (G.faces.centroids(selected, :) * reshape(gravityVector, [], 1));
        bc = addBC(bc, selected, 'pressure', pressure, 'sat', options.initSat);
    end
end
