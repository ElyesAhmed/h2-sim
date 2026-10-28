classdef MicrobialChemotaxis < StateFunction
    % Volume-filling chemotactic coefficient in the liquid phase.
    %
    % SYNOPSIS:
    %   d = MicrobialChemotaxis(model)
    %   d = MicrobialChemotaxis(model, 'pn', pv, ...)
    %
    % DESCRIPTION:
    %   Returns chi_i * phi * max(S_l, 0) * theta_i * (1-theta_i), where
    %   theta_i = max(0, min(nbact_i/bact_maxProp, 1)). The coefficient
    %   xch_seuil supplies chi_i; the volume-filling factor suppresses
    %   migration at empty and capped populations. ChemotaxisBactFlux
    %   applies its transmissibility to the dissolved-H2 mole-fraction jump.
    %   Zero coefficients are returned when chemotaxisEffect is false.
    %   Non-positive chi_i retains the existing warning and arithmetic.
    %
    % RETURNS:
    %   dN - One cell-centered effective coefficient per population [m^2/s].
    %
    % SEE ALSO:
    %   ChemotaxisTransmissibility, ChemotaxisBactFlux, MicrobialDiffusivity

    methods

        % -----------------------------------------------------------------%
        function md = MicrobialChemotaxis(model, varargin)
            md@StateFunction(model, varargin{:});
            md = merge_options(md, varargin{:});

            % Dependencies: pressure, saturation, and nbact (for dynamic porosity)
            md = md.dependsOn({'s', 'pressure', 'nbact'}, 'state');
            md.label = 'D_{chemot}^{eff}';
        end

        % -----------------------------------------------------------------%
        function dN = evaluateOnDomain(~, model, state)
            bcrm = model.biochemFluid;
            nbioreact = bcrm.nbioreact;
            % Fetch primary state variables
            [s, nbact, p] = model.getProps(state, 's', 'nbact', 'pressure');

            % Porosity - dynamic (bio-clogging) or static
            if isprop(model, 'rock') && isa(model.rock.poro, 'function_handle')
                nbactArray = model.extractBactValues(nbact);
                phi = model.rock.poro(p, nbactArray{:}); % Pressure/population-dependent porosity.
            else
                phi = model.rock.poro;
            end

            % Liquid saturation
            L_ix = model.getLiquidIndex();
            if iscell(s)
                sL = s{L_ix};
            else
                sL = s(:, L_ix);
            end

            liquidSaturation = max(sL, 0);

            % One effective coefficient per microbial population.
            dN = cell(1, nbioreact);
            [dN{:}] = deal(0);

            % Effective microbial chemotaxis
            for i = 1:nbioreact
                if iscell(nbact)
                    nbacti = nbact{i};
                else
                    nbacti = nbact(:, i);
                end
                % Effective microbial chemotaxis (volume-filling term)
                if model.chemotaxisEffect
                    if model.biochemFluid.xch_seuil(i) <= 0
                        warning(['MicrobialChemotaxis: chemotaxisEffect flag enabled but ' ...
                            'xch_seuil coefficient is zero or negative for species %d. ' ...
                            'Chemotaxis will be inactive.'], i);
                    end
                    populationFraction = max(0, min(nbacti ./ model.bact_maxProp, 1));
                    dN{i} = model.biochemFluid.xch_seuil(i) .* phi .* liquidSaturation .* ...
                        populationFraction .* (1.0 - populationFraction);
                else
                    dN{i} = 0;
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
