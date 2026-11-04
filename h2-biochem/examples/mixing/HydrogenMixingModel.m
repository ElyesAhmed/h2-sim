classdef HydrogenMixingModel < GenericOverallCompositionModel
    % HYDROGENMIXINGMODEL Binary compositional flow with constant diffusion.
    % Uses MRST's component-mass convergence scaling and H2sim's diffusive
    % flux state functions. No microbial equations or chemistry are added.
    properties (SetAccess = private)
        molecularDiffusion = false
        molecularDispersion = false
        diffusionCoefficient = 0
    end
    methods

        function model = HydrogenMixingModel(G, rock, fluid, mixture, coefficient)
            model@GenericOverallCompositionModel(G, rock, fluid, mixture, ...
                'water', false, 'AutoDiffBackend', DiagonalAutoDiffBackend());
            model.molecularDiffusion = coefficient > 0;
            model.diffusionCoefficient = coefficient;
        end

        function model = setupStateFunctionGroupings(model, varargin)
            model = setupStateFunctionGroupings@GenericOverallCompositionModel( ...
                model, varargin{:});
            if model.molecularDiffusion
                flux = model.FlowDiscretization;
                flux = flux.setStateFunction('ComponentTotalFlux', ...
                    ComponentTotalFluxForBio(model));
                flux = flux.setStateFunction('DispersiveDiffusivity', ...
                    HydrogenMixingDiffusivity(model, model.diffusionCoefficient));
                flux = flux.setStateFunction('DispersiveTransmissibility', ...
                    DispersiveTransmissibility(model));
                flux = flux.setStateFunction('ComponentPhaseDispFlux', ...
                    ComponentPhaseDispFlux(model));
                flux = flux.setStateFunction('ComponentTotalDispFlux', ...
                    ComponentTotalDispFlux(model));
                model.FlowDiscretization = flux;
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
