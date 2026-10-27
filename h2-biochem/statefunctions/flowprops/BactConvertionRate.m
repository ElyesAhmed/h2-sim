classdef BactConvertionRate < StateFunction
    % Bacterial conversion rate model for compositional simulations.
    %
    % SYNOPSIS:
    %   bcr = BactConvertionRate(model)
    %   bcr = BactConvertionRate(model, 'pn', pv, ...)
    %
    % DESCRIPTION:
    %   Accumulates mass-weighted EOS conversion coefficients for MET,
    %   ACE, and SRB. For each reaction i and EOS component c:
    %
    %       qbase = growth_i .* BacterialMass_i ./ Y_H2_i
    %       gamma_norm = nbactMax_i .* gamma_i .* molarMass ./ abs(gamma_H2)
    %       qbiot{c} = qbiot{c} + gamma_norm(c) .* qbase
    %
    %   These coefficients retain the legacy model normalization. The
    %   reservoir model inserts qbiot{c}/rhoL into its component balance;
    %   SRBTracerConvRate uses the same density factor for molar tracer
    %   sources. Do not compare raw qbiot directly with mol/s tracer rates.
    %
    %   SRB sulfate is an aqueous tracer, so it need not be an EOS
    %   component. Only the volatile fraction of generated sulfide enters
    %   the EOS H2S source; the complementary HS- source is handled by
    %   SRBTracerConvRate. MET/ACE use the carbon-limited growth coefficient
    %   on BiochemistryPhreeqcModel, and the ordinary coefficient on the
    %   base model. The compositional PHREEQC backend owns its reactions
    %   externally, so this property returns zero in that mode.
    %
    % RETURNS:
    %   qbiot - One cell per EOS component, containing the accumulated
    %           coefficient for each reservoir cell (negative for sinks).
    %
    % SEE ALSO:
    %   CarbonLimitedGrowthRate, SRBTracerConvRate, BiochemistryModel

    methods
        %-----------------------------------------------------------------%
        function bcr = BactConvertionRate(model, varargin)
            % Constructor for bacterial conversion rate calculator.
            %
            % PARAMETERS:
            %   model - Compositional model with bacterial physics
            %   varargin - Optional property/value pairs
            %
            % RETURNS:
            %   bcr - BactConvertionRate instance

            bcr@StateFunction(model, varargin{:});

            % This state function is also registered on the facility model.
            rm = model;
            if isprop(model, 'ReservoirModel') && ~isempty(model.ReservoirModel)
                rm = model.ReservoirModel;
            end
            if isa(rm, 'BiochemistryPhreeqcModel')
                growthRateName = 'CarbonLimitedGrowthRate';
            else
                growthRateName = 'PsiGrowthRate';
            end
            bcr = bcr.dependsOn(growthRateName, 'state');
            if isprop(model, 'phreeqcTimestepCoupling') && model.phreeqcTimestepCoupling
                bcr = bcr.dependsOn('phreeqcPH', 'state');
            end

            bcr.label = 'Q_biot';
        end

        %-----------------------------------------------------------------%
        function qbiot = evaluateOnDomain(~, model, state)
            % Compute bacterial conversion rate for each component.
            %
            % PARAMETERS:
            %   model - Compositional model instance
            %   state - Reservoir state structure
            %
            % RETURNS:
            %   qbiot - Cell array qbiot{c} containing conversion rates
            %           for component c, before model density scaling.

            % Get reservoir model and number of components
            if isprop(model, 'ReservoirModel') && ~isempty(model.ReservoirModel)
                rm = model.ReservoirModel;
            else
                rm = model;
            end
            ncomp = rm.EOSModel.getNumberOfComponents();

            % Initialize output with zeros
            qbiot = cell(ncomp, 1);
            [qbiot{:}] = deal(0);

            % Early return if bacterial model is not active
            if ~(rm.bacteriamodel && rm.liquidPhase)
                return;
            end
            if ismethod(rm, 'isSequentialCompositionalPhreeqcBackend') && ...
                    rm.isSequentialCompositionalPhreeqcBackend()
                % The compositional PHREEQC COM split owns MET/ACE/SRB chemistry after
                % convergence. Keep the MRST transport equations, but do
                % not apply their microbial component sources as well.
                return;
            end

            % Get biochemical fluid properties
            bcrm = rm.biochemFluid;
            nbioreact = bcrm.nbioreact;

            validateMetabolicReactions(bcrm, nbioreact);

            % Get component names
            compNames = rm.EOSModel.getComponentNames();

            % Get primary state variables directly (avoids redundant Density calculations)
            bmass = rm.PVTPropertyFunctions.get(rm, state, 'BacterialMass');
            if isa(rm, 'BiochemistryPhreeqcModel')
                growthRateName = 'CarbonLimitedGrowthRate';
            else
                growthRateName = 'PsiGrowthRate';
            end
            psigrowth = model.getProps(state, growthRateName);
            % Get model parameters
            Y_H2 = bcrm.Y_H2;                      % Reaction yield scales
            gamma = rm.gammak;                     % Stoichiometric coefficients (nbioreact x ncomp)
            nbactMax = bcrm.nbactMax;              % Population scales
            mc = rm.EOSModel.CompositionalMixture.molarMass;  % Component molar masses [kg/mol]

            % Calculate conversion rate for each reactor and component
            for i = 1:nbioreact
                rxn = bcrm.metabolicReaction{i};
                isSRB = strcmp(rxn, 'SulfateReducingBacteria');

                % Find indices for this reactor's H2 and substrate
                [idxH2, idxprod] = reactionComponentIndices( ...
                    compNames, bcrm, i, isSRB);

                % Get bacterial mass and growth rate for this reactor
                if iscell(bmass)
                    bmass_i = bmass{i};
                else
                    bmass_i = bmass(:, i);
                end
                if iscell(psigrowth)
                    psigrowth_i = psigrowth{i};
                else
                    psigrowth_i = psigrowth(:, i);
                end

                % Normalize stoichiometric coefficients by H2 coefficient for this reactor
                % γ_c^H2 = (γ_c * m_c) / |γ_H2|
                gamma_row = gamma(i, :);
                gamma_norm = nbactMax(i) .* gamma_row .* mc ./ abs(gamma_row(idxH2));

                % Calculate base conversion rate
                % The source is based on microbial mass and the
                % reaction-specific yield scale.
                qbase = psigrowth_i.*bmass_i./Y_H2(i);

                % For SRB, only a pH/salinity-dependent fraction of the
                % total sulfide produced is volatile H2S; the rest stays
                % as the HS- aqueous tracer (see SRBTracerConvRate,
                % which accounts for the complementary (1-f_H2S) part).
                % Splitting here, at the source term, avoids overwriting
                % flash mole fractions directly (see the note in
                % SoreideWhitsonEos.getMixtureFugacityCoefficients).
                if isSRB && ~isempty(idxprod)
                    if isfield(state, 'phreeqcPH')
                        pH = state.phreeqcPH;
                    else
                        pH = [];
                    end

                    fH2S = rm.EOSModel.fractionH2SVolatile(state.T, pH);
                end

                % Apply normalized stoichiometric coefficients to each component
                for c = 1:ncomp
                    contrib = gamma_norm(c) .* qbase;
                    if isSRB && c == idxprod
                        contrib = contrib .* fH2S;
                    end
                    qbiot{c} = qbiot{c} + contrib;
                end
            end
        end
    end
end

function validateMetabolicReactions(bcrm, nreact)
% Validate reactor types
for i = 1:nreact
    rxn = bcrm.metabolicReaction{i};
    if ~ismember(rxn, {'MethanogenicArchae', 'AcetogenicBacteria', 'SulfateReducingBacteria'})
        error('BactConvertionRate:UnsupportedReaction', ...
            'Unsupported metabolic reaction: %s', rxn);
    end
end
end

function [idxH2, idxprod] = reactionComponentIndices(compNames, bcrm, i, isSRB)
idxH2   = find(strcmpi(compNames, bcrm.rH2{i}), 1);
idxsub  = find(strcmpi(compNames, bcrm.rsub{i}), 1);
idxprod = find(strcmpi(compNames, bcrm.p2{i}), 1);

% Sulfate is a tracer; SRB requires only its H2 EOS component here.
% Retain the optional product lookup used by the existing sulfide split.
if isempty(idxH2)
    error('BactConvertionRate:MissingH2', ...
        'Required component H2 (%s) not found for reactor %d', bcrm.rH2{i}, i);
end
if isempty(idxsub) && ~isSRB
    error('BactConvertionRate:MissingSubstrate', ...
        'Required component substrate (%s) not found for reactor %d', bcrm.rsub{i}, i);
end
end

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