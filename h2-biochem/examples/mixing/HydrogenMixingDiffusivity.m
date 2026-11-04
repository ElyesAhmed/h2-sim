classdef HydrogenMixingDiffusivity < StateFunction
    % HYDROGENMIXINGDIFFUSIVITY Constant binary diffusivity with unit tortuosity.
    % Used only by the closed hydrogen-methane mixing demonstration. The
    % returned conductivity is porosity * phase saturation * D [m^2/s].
    properties (SetAccess = private)
        diffusionCoefficient
    end
    methods

        function sf = HydrogenMixingDiffusivity(model, coefficient)
            sf@StateFunction(model);
            sf.diffusionCoefficient = coefficient;
            sf = sf.dependsOn('s', 'state');
        end

        function coefficients = evaluateOnDomain(sf, model, state)
            phaseNames = model.getPhaseNames();
            coefficients = cell(model.getNumberOfComponents(), ...
                model.getNumberOfPhases());
            for phase = 1:model.getNumberOfPhases()
                saturation = model.getProp(state, ['s', phaseNames(phase)]);
                conductivity = model.rock.poro .* saturation .* ...
                    sf.diffusionCoefficient;
                for component = 1:model.getNumberOfComponents()
                    coefficients{component, phase} = conductivity;
                end
            end
        end

    end
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
