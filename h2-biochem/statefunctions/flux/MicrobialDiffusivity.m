classdef MicrobialDiffusivity < StateFunction
    % Compute the effective microbial diffusivity in the liquid phase.
    %
    % SYNOPSIS:
    %   d = MicrobialDiffusivity(model)
    %   d = MicrobialDiffusivity(model, 'pn', pv, ...)
    %
    % DESCRIPTION:
    %   Evaluates the effective cell-centered microbial diffusivity [m^2/s]
    %   as phi * S_l * D_b, where D_b is the bacterial diffusion coefficient
    %   (`model.biochemFluid.bactdiff`) and phi is the current porosity
    %   (possibly dynamic due to bio-clogging). If bacterial diffusion is
    %   disabled, zero coefficients are returned. Non-positive configured
    %   coefficients emit the existing warning; this class still evaluates
    %   the configured formula and does not clamp negative values.
    %
    % REQUIRED PARAMETERS:
    %   model - Model instance, must have fields `bactDiffusion` (logical)
    %           and `biochemFluid.bactdiff` (positive numeric).
    %
    % OPTIONAL PARAMETERS (property/value pairs):
    %   (none defined in this base class; can be extended via `merge_options`)
    %
    % RETURNS:
    %   dN - Cell-centered effective diffusivity (ncells x 1), units m^2/s.
    %
    % SEE ALSO:
    %   StateFunction, DynamicFlowTransmissibility

    methods

        % -----------------------------------------------------------------%
        function md = MicrobialDiffusivity(model, varargin)
            md@StateFunction(model, varargin{:});
            md = merge_options(md, varargin{:});

            % Dependencies: pressure, saturation, and nbact (for dynamic porosity)
            md = md.dependsOn({'s', 'pressure', 'nbact'}, 'state');
            md = md.dependsOn('PoreVolume', 'PVTPropertyFunctions');
            md.label = 'D_{bact}^{eff}';
        end

        % -----------------------------------------------------------------%
        function dN = evaluateOnDomain(~, model, state)
            bcrm = model.biochemFluid;
            nbioreact = bcrm.nbioreact;
            % Fetch primary state variables
            [s, p, nbact] = model.getProps(state, 's', 'pressure', 'nbact');

            % Porosity - dynamic (bio-clogging) or static
            if isprop(model, 'rock') && isa(model.rock.poro, 'function_handle')
                nbactArray = model.extractBactValues(nbact);
                phi = model.rock.poro(p, nbactArray{:}); % Pressure/population-dependent porosity.
            else
                phi = model.rock.poro;
            end

            % One effective coefficient per microbial population.
            dN = cell(1, nbioreact);
            [dN{:}] = deal(0);

            % Liquid saturation is common to all microbial populations.
            L_ix = model.getLiquidIndex();
            if iscell(s)
                sL = s{L_ix};
            else
                sL = s(:, L_ix);
            end
            liquidSaturation = max(sL, 0);

            for i = 1:nbioreact
                % Effective microbial diffusivity
                if model.bactDiffusion
                    if model.biochemFluid.bactdiff(i) <= 0
                        warning(['MicrobialDiffusivity: bactDiffusion flag enabled but ' ...
                            'bactdiff coefficient is zero or negative for species %d. ' ...
                            'Diffusion will be inactive.'], i);
                    end
                    dN{i} = model.biochemFluid.bactdiff(i) .* phi .* liquidSaturation;
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
