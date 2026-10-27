classdef BiochemistryGenericFacilityModel < GenericFacilityModel
    % Microbial reaction and liquid well sources for compositional models.
    %
    % Bacterial sources are mass rates [kg/s]; non-volatile aqueous tracer
    % sources are molar rates [mol/s]. Positive values add material to a
    % reservoir cell. Well outflow carries the local liquid concentration;
    % injected liquid carries no bacteria or aqueous tracers here.
    %
    % getAqueousTracerSources gates SRB reactions with reactionsEnabled,
    % independently of well transport. The legacy getBacteriaSources and
    % getSRBTracerSources methods rely on the caller to gate reactions.
    %
    % SEE ALSO:
    %   BiochemistryModel, BiochemistryPhreeqcModel, CarbonLimitedGrowthRate

    properties
        bacterialFormulation = 'bacterialmodel';  % Formulation for bacterial transport
    end

    methods
        %-----------------------------------------------------------------%
        function model = setupStateFunctionGroupings(model, useDefaults)
            % Set up state function groupings using parent, and add
            % biochemistry-specific functions

            if nargin < 2
                useDefaults = isempty(model.FacilityFlowDiscretization);
            end

            % Base facility groupings
            model = setupStateFunctionGroupings@GenericFacilityModel(model, useDefaults);

            % Add biochemistry-specific state functions only when bacteriamodel is active
            rm = model.ReservoirModel;
            if ~isempty(rm) && isprop(rm, 'bacteriamodel') && rm.bacteriamodel
                ffd = model.FacilityFlowDiscretization;
                % Note: BacterialMass is already registered in ReservoirModel's PVTPropertyFunctions
                ffd = ffd.setStateFunction('PsiGrowthRate', GrowthBactRateSRC(model));
                ffd = ffd.setStateFunction('CarbonLimitedGrowthRate', ...
                    CarbonLimitedGrowthRate(model));
                ffd = ffd.setStateFunction('PsiDecayRate', DecayBactRateSRC(model));
                ffd = ffd.setStateFunction('BactConvRate', BactConvertionRate(model));
                if isprop(rm, 'sulfateReduction') && rm.sulfateReduction
                    ffd = ffd.setStateFunction('SRBTracerConvRate', SRBTracerConvRate(model));
                end
                model.FacilityFlowDiscretization = ffd;
            end
        end

        %-----------------------------------------------------------------%
        function state = initStateAD(model, state, vars, names, origin)
            % Initialize AD state from double state
            state = initStateAD@GenericFacilityModel(model, state, vars, names, origin);
        end

        %-----------------------------------------------------------------%
        function names = getBasicPrimaryVariableNames(model)
            % Get names of primary variables
            names = getBasicPrimaryVariableNames@GenericFacilityModel(model);

            % If bacterial variables are disabled, return immediately
            if strcmpi(model.bacterialFormulation, 'none') || ...
                    strcmpi(model.primaryVariableSet, 'none')
                return
            end
        end

        %-----------------------------------------------------------------%
        function [variables, names, map] = getBasicPrimaryVariables(model, wellSol)
            % Return facility primary variables
            [variables, names, map] = getBasicPrimaryVariables@GenericFacilityModel(model, wellSol);
        end

        %-----------------------------------------------------------------%
        function [fn, index] = getVariableField(model, name, varargin)
            % Get field name and index for a given variable
            [fn, index] = getVariableField@GenericFacilityModel(model, name, varargin{:});
        end

        %-----------------------------------------------------------------%
        function src = getBacteriaSources(model, fd, state, state0, dt)
            % Net growth/decay plus liquid well advection [kg/s].
            rm = model.ReservoirModel;
            bcrm = rm.biochemFluid;
            if isempty(rm) || ~isprop(rm, 'bacteriamodel') || ~rm.bacteriamodel
                src = 0;
                return;
            end

            nbioreact = bcrm.nbioreact;
            reaction = model.getBacterialReactionSources( ...
                fd, state, state0, dt, nbioreact);
            well = model.getBacterialWellSources(state, nbioreact);
            src = cell(1, nbioreact);
            for i = 1:nbioreact
                src{i} = reaction{i} + well{i};
            end
        end

        %-----------------------------------------------------------------%
        function src = getSRBTracerSources(model, fd, state, state0, dt)
            % Reaction + well-advection source for the SO4/HS aqueous
            % tracers. Mirrors getBacteriaSources, but for the two
            % non-volatile species that never enter the EOS/flash.
            rm = model.ReservoirModel;
            if isempty(rm) || ~isprop(rm, 'sulfateReduction') || ~rm.sulfateReduction
                src = {0, 0};
                return;
            end

            flowState = fd.buildFlowState(model, state, state0, dt);
            src_reaction = model.getProps(flowState, 'SRBTracerConvRate');

            src_well = model.getTracerWellSources(state, {'SO4', 'HS'});

            src = cell(1, 2);
            for i = 1:2
                src{i} = src_reaction{i} + src_well{i};
            end
        end

        %-----------------------------------------------------------------%
        function src = getAqueousTracerSources(model, fd, state, state0, dt)
            % Reaction and well sources for all mobile aqueous tracers.
            % Ca/Mg are analytical totals updated by the post-step
            % PHREEQC split, so their in-step reaction sources are zero.
            rm = model.ReservoirModel;
            if isempty(rm) || ~rm.hasMobileAqueousTracers()
                src = {};
                return;
            end

            tracerNames = rm.getAqueousTracerNames();
            ntracer = numel(tracerNames);
            src_reaction = cell(1, ntracer);
            [src_reaction{:}] = deal(0);
            % Disable biological sources independently of aqueous well fluxes.
            if rm.reactionsEnabled && rm.sulfateReduction && ...
                    ~(ismethod(rm, 'isSequentialCompositionalPhreeqcBackend') && ...
                    rm.isSequentialCompositionalPhreeqcBackend())
                flowState = fd.buildFlowState(model, state, state0, dt);
                srbSource = model.getProps(flowState, 'SRBTracerConvRate');
                src_reaction{strcmp(tracerNames, 'SO4')} = srbSource{1};
                src_reaction{strcmp(tracerNames, 'HS')} = srbSource{2};
            end

            src_well = model.getTracerWellSources(state, tracerNames);

            src = cell(1, ntracer);
            for i = 1:ntracer
                src{i} = src_reaction{i} + src_well{i};
            end
        end

        %-----------------------------------------------------------------%
        function [eqs, names, types, state] = getModelEquations(model, state0, state, dt, drivingForces)
            % Return facility equations including parent contributions
            [eqs, names, types, state] = ...
                getModelEquations@GenericFacilityModel(model, state0, state, dt, drivingForces);
        end

        %-----------------------------------------------------------------%
        function [values, tolerances, names, evaluated] = getFacilityConvergenceValues(model, problem, varargin)
            % Get convergence values for facility
            [values, tolerances, names, evaluated] = ...
                getFacilityConvergenceValues@GenericFacilityModel(model, problem, varargin{:});
        end
    end

    methods (Access = private)
        function src_growthdecay = getBacterialReactionSources( ...
                model, fd, state, state0, dt, nbioreact)
            % Specific rates [1/s] act on BacterialMass [kg]. Preserve the
            % regularization sink and active biomass-floor condition.
            rm = model.ReservoirModel;
            src_growthdecay = cell(1, nbioreact);
            [src_growthdecay{:}] = deal(0);
            if ~(ismethod(rm, 'isSequentialCompositionalPhreeqcBackend') && ...
                    rm.isSequentialCompositionalPhreeqcBackend())
                reg = 1.0e-10;
                flowState = fd.buildFlowState(model, state, state0, dt);
                psigrowth = model.getProps(flowState, 'CarbonLimitedGrowthRate');
                psidecay  = model.getProps(flowState, 'PsiDecayRate');   % [1/s]
                bmass     = rm.PVTPropertyFunctions.get(rm, state, 'BacterialMass');  % pv * S_l * rho_l * nbact [kg]
                nbact     = rm.getProp(state, 'nbact');
                for i = 1:nbioreact
                    src_growthdecay{i} = (psigrowth{i} - psidecay{i}).* bmass{i} - reg .* bmass{i};
                    if iscell(nbact)
                        nbact_i = nbact{i};
                    else
                        nbact_i = nbact(:, i);
                    end
                    % Treat the normalized biomass floor as an active
                    % bound. Without this complementarity condition,
                    % decay requests nbact < floor while updateState clips
                    % every Newton iterate back to the floor, leaving an
                    % irreducible residual and forcing timestep cuts.
                    activeFloor = value(nbact_i) <= ...
                        rm.bact_capProp.*(1 + sqrt(eps));
                    negativeSource = value(src_growthdecay{i}) < 0;
                    src_growthdecay{i}(activeFloor & negativeSource) = 0;
                end
            end
        end

        function src = getBacterialWellSources(model, state, nbioreact)
            % Liquid well flux [m^3/s] times density and bacterial fraction.
            rm = model.ReservoirModel;
            src = cell(1, nbioreact);
            [src{:}] = deal(0);
            map = model.getProp(state, 'FacilityWellMapping');
            if isempty(map.cells)
                return;
            end

            q_ph = model.getProp(state, 'PhaseFlux');
            rho = rm.PVTPropertyFunctions.get(rm, state, 'Density');
            nbact = rm.getProp(state, 'nbact');
            L_ix = rm.getLiquidIndex();
            q_l = q_ph{L_ix};
            rho_l = rho{L_ix};
            rho_perf = rho_l(map.cells);
            nc = rm.G.cells.num;
            nf = numel(map.cells);
            S = sparse(map.cells, (1:nf)', 1, nc, nf);
            for i = 1:nbioreact
                if iscell(nbact)
                    nbacti = nbact{i};
                else
                    nbacti = nbact(:, i);
                end
                q_bact = rho_perf .* q_l .* nbacti(map.cells);
                q_bact(q_l > 0) = 0;
                src{i} = S * q_bact;
            end
        end

        function src = getTracerWellSources(model, state, names)
            % Scatter perforation molar fluxes [mol/s] to reservoir cells.
            rm = model.ReservoirModel;
            src = cell(1, numel(names));
            [src{:}] = deal(0);
            map = model.getProp(state, 'FacilityWellMapping');
            if isempty(map.cells)
                return;
            end

            q_ph = model.getProp(state, 'PhaseFlux');
            q_l = q_ph{rm.getLiquidIndex()};
            nc = rm.G.cells.num;
            nf = numel(map.cells);
            S = sparse(map.cells, (1:nf)', 1, nc, nf);
            for i = 1:numel(names)
                concentration = rm.getProp(state, lower(names{i}));
                q_tracer = q_l .* concentration(map.cells);
                q_tracer(q_l > 0) = 0;
                src{i} = S * q_tracer;
            end
        end
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