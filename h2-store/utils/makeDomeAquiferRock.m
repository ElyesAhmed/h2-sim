function rock = makeDomeAquiferRock(G, layers)
%MAKEDOMEAQUIFERROCK Assign permeability, porosity and saturation regions.
%
% Reservoir permeability is [1000, 1000, 100] mD and porosity is 0.25.
% Caprock and bedrock porosities are 0.1, with isotropic permeabilities
% 0.0001 mD and 0.01 mD. Underrock and toprock have porosity 0.15 and
% permeability 0.001 mD. Saturation regions are aquifer=1,
% bedrock/underrock=2 and caprock/toprock=3.
%
% G and layers are the outputs of makeDomeAquiferGrid.

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
    rock = makeRock(G, [1000, 1000, 100]*milli*darcy, 0.25);
    rock.poro(layers.caprock) = 0.1;
    rock.poro(layers.bedrock) = 0.1;
    rock.poro(layers.underrock) = 0.15;
    rock.poro(layers.toprock) = 0.15;
    rock.perm(layers.caprock, :) = 1e-4*milli*darcy;
    rock.perm(layers.bedrock, :) = 1e-2*milli*darcy;
    rock.perm(layers.toprock, :) = 1e-3*milli*darcy;
    rock.perm(layers.underrock, :) = 1e-3*milli*darcy;
    rock.regions.saturation = ones(G.cells.num, 1);
    rock.regions.saturation(layers.bedrock) = 2;
    rock.regions.saturation(layers.toprock) = 3;
    rock.regions.saturation(layers.caprock) = 3;
    rock.regions.saturation(layers.underrock) = 2;
end
