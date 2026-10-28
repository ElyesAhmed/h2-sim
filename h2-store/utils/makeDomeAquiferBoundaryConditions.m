function bc = makeDomeAquiferBoundaryConditions(G, fluid, options)
    % MAKEDOMEAQUIFERBOUNDARYCONDITIONS Scaled pressure profile on the x=0 boundary.
    %
    % SYNOPSIS:
    %   bc = makeDomeAquiferBoundaryConditions(G, fluid, options)
    %
    % G is a grid with face geometry in meters. fluid.rhoOS is the brine surface
    % density [kg/m^3]. options supplies initPres [Pa] and initSat in oil/gas
    % order. Only boundary faces with abs(x) < eps receive pressure conditions.
    %
    % For a face coordinate vector c, pressure is
    %   initPres + 0.5 bar - rhoOS * ((c - (-100))/15 * g(:)).
    % The -100 m reference is subtracted from every coordinate component; the
    % divisor 15 scales the pressure gradient. These are the dome case's prescribed
    % boundary settings. In 3D, g is the current MRST gravity vector. In 2D it is
    % [0, -norm(gravity)]. Other boundaries have no explicit condition.
    %
    % SEE ALSO:
    %   modelForDome3DAquifer, addBC, gravity

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
    if G.griddim < 3
        gravityVector = [0, -norm(gravity)];
    else
        gravityVector = gravity;
    end
    boundary = boundaryFaces(G);
    faces = boundary(abs(G.faces.centroids(boundary, 1)) < eps);
    displacement = bsxfun(@minus, G.faces.centroids(faces, :), -100) / 15;
    pressureDrop = fluid.rhoOS .* (displacement * reshape(gravityVector, [], 1));
    pressure = options.initPres + 0.5 * barsa() - pressureDrop;
    bc = addBC([], faces, 'pressure', pressure, 'sat', options.initSat);
end
