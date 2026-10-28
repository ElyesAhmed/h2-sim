function [cases, restartChecks] = runStorageCycleCases()
    % RUNSTORAGECYCLECASES Run small complete cycles and MAT-file restarts.
    %
    % Requires initialized MRST, h2-store and h2-biochem paths and a working
    % PHREEQC engine. Each six-step cycle injects, shuts in and produces.
    % The checkpoint follows step three, within the shut-in period. A fresh
    % model and nonlinear solver resume the serialized state at step four.
    % No golden outputs are written by this function.
    factories = {@setupBlackOilCycle, @setupPhreeqcCycle};
    names = {'blackOil', 'phreeqc'};
    cases = struct();
    restartChecks = struct();
    for k = 1:numel(names)
        rng(42);
        gravity reset on;
        clear runSequentialH2BiochemPhreeqcEquilibrium;
        factory = factories{k};
        [model, state0, schedule, cleanup] = factory();
        [wells, states] = solve(state0, model, schedule, 1);
        complete = capture(state0, states, wells, schedule, model);
        checkCycle(complete);
        clear cleanup model;

        clear runSequentialH2BiochemPhreeqcEquilibrium;
        [model, state0, schedule, cleanup] = factory();
        prefix = schedule;
        prefix.step.val = prefix.step.val(1:3);
        prefix.step.control = prefix.step.control(1:3);
        [prefixWells, prefixStates] = solve(state0, model, prefix, 1);
        checkpoint = prefixStates{end};
        checkpointFile = [tempname, '.mat'];
        removeCheckpoint = onCleanup(@() delete(checkpointFile));
        save(checkpointFile, 'checkpoint');
        clear checkpoint cleanup model;
        clear runSequentialH2BiochemPhreeqcEquilibrium;
        [model, ~, schedule, cleanup] = factory();
        loaded = load(checkpointFile, 'checkpoint');
        [tailWells, tailStates] = solve(loaded.checkpoint, model, schedule, 4);
        restarted = capture(state0, [prefixStates; tailStates], ...
            [prefixWells; tailWells], schedule, model);
        checkCycle(restarted);
        restartCheck = struct('passed', true, 'identifier', '', 'message', '', ...
            'reactionConsumption', []);
        try
            compareRestart(complete, restarted, names{k});
        catch exception
            restartCheck.passed = false;
            restartCheck.identifier = exception.identifier;
            restartCheck.message = exception.message;
            fprintf('CYCLE_RESTART_FAIL model=%s message=%s\n', names{k}, exception.message);
        end
        if strcmp(names{k}, 'phreeqc')
            field = 'sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles';
            consumed = cellfun(@(state) sum(state.(field), 'all'), complete.states(2:end));
            restartCheck.reactionConsumption = consumed;
            fprintf('CYCLE_REACTION cumulativeMoles=%s\n', mat2str(consumed', 17));
            if ~(consumed(end) > 0 && all(diff(consumed) >= -1e-12))
                restartCheck.passed = false;
                restartCheck.message = [restartCheck.message, ...
                    ' Reactive cycle must retain positive cumulative consumption.'];
            end
        end
        restartChecks.(names{k}) = restartCheck;
        cases.(names{k}) = complete;
        fprintf('CYCLE_COMPLETE model=%s steps=6 restartStep=4 restartPassed=%d\n', ...
            names{k}, restartCheck.passed);
        clear cleanup removeCheckpoint;
    end
    if nargout < 2
        assert(all(structfun(@(x) x.passed, restartChecks)), ...
            'h2sim:cycles:Restart', 'A serialized restart differed; request restartChecks for details.');
    end
end

function compareRestart(complete, restarted, name)
    % PHREEQC engine history is not serialized. The documented PE diagnostic
    % can change on restart; retain it in golden outputs and report its drift.
    maximumPEDifference = 0;
    maximumHSDifference = 0;
    for k = 1:numel(complete.states)
        if isfield(complete.states{k}, 'tracerHS')
            maximumHSDifference = max(maximumHSDifference, ...
                max(abs(complete.states{k}.tracerHS - restarted.states{k}.tracerHS)));
        end
        if isfield(complete.states{k}, 'phreeqcPE')
            a = complete.states{k}.phreeqcPE;
            b = restarted.states{k}.phreeqcPE;
            assert(isequal(size(a), size(b)) && all(isfinite(a)) && all(isfinite(b)));
            maximumPEDifference = max(maximumPEDifference, max(abs(a - b)));
            complete.states{k} = rmfield(complete.states{k}, 'phreeqcPE');
            restarted.states{k} = rmfield(restarted.states{k}, 'phreeqcPE');
        end
    end
    fprintf('CYCLE_RESTART model=%s maximumPEDiagnosticDifference=%.17g maximumHSTracerDifference=%.17g\n', ...
        name, maximumPEDifference, maximumHSDifference);
    compareStorageCycleValues(complete, restarted, [name, '.restart']);
end

function [wells, states] = solve(state, model, schedule, restartStep)
    solver = NonLinearSolver('maxIterations', 25, 'maxTimestepCuts', 12);
    [wells, states, report] = simulateScheduleAD(state, model, schedule, ...
        'NonLinearSolver', solver, 'restartStep', restartStep);
    assert(~report.Failure && numel(states) == numel(schedule.step.val) - restartStep + 1, ...
        'h2sim:cycles:Convergence', 'A cycle did not complete every requested step.');
end

function data = capture(state0, states, wells, schedule, model)
    fields = {'pressure', 's', 'components', 'rs', 'rv', 'nbact', ...
        'phreeqcPH', 'phreeqcPE', 'phreeqcTotalCarbon', ...
        'tracerSO4', 'tracerHS', 'tracerHCO3', 'h2ConsumptionRate', ...
        'sequentialLocalReactionTargetComponentMoles', ...
        'sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles', ...
        'sequentialH2BiochemPhreeqcBiomassMET', ...
        'sequentialH2BiochemPhreeqcBiomassACE', ...
        'sequentialH2BiochemPhreeqcBiomassSRB'};
    allStates = [{state0}; states];
    snapshots = cell(size(allStates));
    for k = 1:numel(allStates)
        item = struct();
        for j = 1:numel(fields)
            field = fields{j};
            if isfield(allStates{k}, field)
                item.(field) = value(allStates{k}.(field));
            end
        end
        snapshots{k} = item;
    end
    % Inactive MRST well solutions may retain the previous rate. Record raw
    % outputs, but use schedule status when accounting for physical exchange.
    wellValues = cell(size(wells));
    for k = 1:numel(wells)
        item = struct();
        for field = {'bhp', 'qGs', 'qOs', 'qWs'}
            if isfield(wells{k}, field{1})
                item.(field{1}) = value(wells{k}.(field{1}));
            end
        end
        item.active = double(schedule.control(schedule.step.control(k)).W.status);
        wellValues{k} = item;
    end
    if isa(model, 'GenericBlackOilModel')
        [hydrogen, ~] = computeGasVolumes(model, allStates, 1:numel(allStates));
        inventory = cellfun(@sum, hydrogen);
        flux = cellfun(@(w) w.active * w.qGs, wellValues) .* schedule.step.val;
        residual = inventory(2:end) - inventory(1) - cumsum(flux);
        fprintf('CYCLE_BALANCE maximumRelativeHydrogenResidual=%.17g\n', ...
            max(abs(residual)) / inventory(1));
        assert(max(abs(residual)) / inventory(1) < 1e-5, ...
            'h2sim:cycles:Conservation', 'Hydrogen storage does not balance well exchange.');
    end
    data = struct('stepSeconds', schedule.step.val, ...
        'controls', schedule.step.control, 'states', {snapshots}, ...
        'wells', {wellValues});
    if isa(model, 'GenericBlackOilModel')
        data.hydrogenSurfaceVolume = inventory;
        data.hydrogenWellExchange = flux;
    end
end

function checkCycle(data)
    for k = 1:numel(data.states)
        state = data.states{k};
        assert(all(isfinite(state.pressure)) && all(state.pressure > 0));
        assert(all(isfinite(state.s), 'all') && all(state.s >= -1e-8, 'all') && ...
            all(state.s <= 1 + 1e-8, 'all') && all(abs(sum(state.s, 2) - 1) < 1e-8));
        if isfield(state, 'components')
            z = state.components;
            assert(all(isfinite(z), 'all') && all(z >= -1e-8, 'all') && ...
                all(z <= 1 + 1e-8, 'all') && all(abs(sum(z, 2) - 1) < 1e-8));
        end
    end
    rates = cellfun(@(w) w.active * (w.qGs + w.qOs), data.wells);
    fprintf('CYCLE_ACTIVE_TOTAL_SURFACE_RATES values=%s\n', mat2str(rates', 12));
    assert(all(rates(1:2) > 0) && all(abs(rates(3:4)) < 1e-12) && ...
        all(rates(5:6) < 0), 'h2sim:cycles:WellControls', ...
        'The cycle must actually inject, shut in and produce fluids.');
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
