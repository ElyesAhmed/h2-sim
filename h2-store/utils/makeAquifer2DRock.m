function rock = makeAquifer2DRock(G)
%MAKEAQUIFER2DROCK Assign reservoir, bedrock and caprock properties.
%
% SYNOPSIS:
%   rock = makeAquifer2DRock(G)
%
% PARAMETERS:
%   G - Grid for the 50 m by 50 m aquifer, with geometry in meters.
%
% RETURNS:
%   rock - Reservoir permeability is 10 mD in both directions and porosity
%          is 0.25. Bedrock (y < 5 m) has 0.01 mD permeability. Caprock lies
%          inside the polygon above the sampled curve
%          y = 25.1 + 5*sin(pi*x/50), with 100 samples across the domain.
%          Caprock permeability is 0.0001 mD. Both sealing layers have 0.1
%          porosity. Saturation regions are reservoir=1, bedrock=2, caprock=3.
%
% SEE ALSO:
%   modelForSimple2DAquifer, makeRock

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
    x = linspace(0, 1);
    y = 25 + 5*sin(pi*x);
    y = y + 0.1;
    polygon = [[0, 50]; [50.*x', y']; [50, 50]];
    coordinates = G.cells.centroids;
    caprock = inpolygon(coordinates(:, 1), coordinates(:, 2), ...
        polygon(:, 1), polygon(:, 2));
    bedrock = find(coordinates(:, 2) < 5);
    rock = makeRock(G, [10*milli*darcy, 10*milli*darcy], 0.25);
    rock.perm(caprock, :) = 1e-4*milli*darcy;
    rock.perm(bedrock, :) = 1e-2*milli*darcy;
    rock.poro(caprock) = 0.1;
    rock.poro(bedrock) = 0.1;
    rock.regions.saturation = ones(G.cells.num, 1);
    rock.regions.saturation(bedrock) = 2;
    rock.regions.saturation(caprock) = 3;
end
