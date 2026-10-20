function scenarios = runThreeBackendComparison(varargin)
%Compare microbial hydrogen consumption with three chemistry models
%
% Aqueous H2 mole fraction and total dissolved inorganic carbon (C(4)
% molality, mol/kgw) profiles are shown at the end of injection, storage,
% and production. DIC is compared instead of the aqueous CO2 mole fraction
% because CO2(aq) depends on pH and alkalinity. Summing the carbonate
% species gives a common quantity for comparison across coupled backends. Additional figures compare H2 loss over
% time and its final spatial distribution. Results remain in memory and no
% simulation files are written; figures export to outputDirectory.
%
% All three models are included in H2sim. The bundled chemistry database
% is sufficient; no external reference checkout is required.
%
% The three compared backends are:
%   1. Original h2-biochem (BiochemistryModel, no PHREEQC).
%   2. Sequential compositional PHREEQC (BiochemistryPhreeqcModel,
%      phreeqcBackend='sequential-compositional-phreeqc'): PHREEQC owns
%      MET/ACE/SRB kinetics entirely, applied once per transport timestep.
%   3. Sequential (SequentialBiochemistryPhreeqcModel): MRST retains
%      microbial kinetics/biomass, split into one coarse global flow step
%      followed by local reaction substeps each closed by a PHREEQC
%      equilibrium update -- see convertToSequentialBiochemistryPhreeqcModel.
%
% SYNOPSIS:
%   % h2_biogeochemistry.dat is bundled at h2-biochem/database/ and is found
%   % automatically via which() once startupH2sim has run, so no path is
%   % required by default:
%   scenarios = runThreeBackendComparison();
%
%   % To use a different database, pass its absolute path explicitly:
%   db = '/absolute/path/to/h2_biogeochemistry.dat';
%   scenarios = runThreeBackendComparison('phreeqcDatabaseFile', db);

    mrstModule add ad-props compositional deckformat

    %% Set simulation options
    opt = struct( ...
        'phreeqcDatabaseFile', '', ...
        'flowTimestepMaxDt', 2*day, ...
        'reactionSubstepMaxDt', 0.4*day, ...
        'plotResults', true, ...
        'outputDirectory', fullfile(pwd, 'build', 'phreeqc-figures'));
    opt = merge_options(opt, varargin{:});
    validateOptions(opt);
    databaseFile = resolvePhreeqcDatabaseFile(opt.phreeqcDatabaseFile);

    %% Define the shared benchmark and chemistry models
    commonOptions = { ...
        'rate', 'highrate', ...
        'scheduleMode', 'complete', ...
        'injectionCO2', 0, ...
        'bacteriamodel', true, ...
        'bactDiffusion', false, ...
        'chemotaxisEffect', false, ...
        'molecularDiffusion', false, ...
        'molecularDispersion', false, ...
        'bioClogging', false, ...
        'carbonateBuffer', true, ...
        'carbonateBufferPH', 6.24, ...
        'initialHCO3', 1.370e-3, ...
        'initialOverallCO2', 0};

    cases = [ ...
        makeCase("MRST-h2biochem", { ...
            'equilibrateInitialCO2', false, ...
            'phreeqcTimestepCoupling', false}, 'plain'), ...
        makeCase("MRST-compositional PHREEQC", { ...
            'equilibrateInitialCO2', false, ...
            'phreeqcTimestepCoupling', true, ...
            'phreeqcBackend', 'sequential-compositional-phreeqc', ...
            'phreeqcDatabaseFile', databaseFile}, 'plain'), ...
        makeCase("MRST-h2biochem PHREEQC", { ...
            'equilibrateInitialCO2', false, ...
            'paperBiomassKinetics', true, ...
            'nbact0', 1, ...
            'phreeqcTimestepCoupling', true, ...
            'phreeqcBackend', 'sequential-h2biochem-phreeqc', ...
            'phreeqcDatabaseFile', databaseFile}, 'coarseSplit')];

    %% Simulate each chemistry model
    scenarios = initializeScenarios(numel(cases));
    for caseNo = 1:numel(cases)
        current = cases(caseNo);
        fprintf('\nBackend %d/%d: %s\n', ...
            caseNo, numel(cases), current.name);
        [~, model, schedule, state0] = ...
            setupH2StorageExampleWithSRB_benchmark( ...
            commonOptions{:}, current.options{:});

        if strcmp(current.driver, 'coarseSplit')
            validateSequentialSetup(model, state0);
            schedule = coarsenScheduleByControl(schedule, opt.flowTimestepMaxDt);
            model = convertToSequentialBiochemistryPhreeqcModel(model, ...
                'reactionSubstepMaxDt', opt.reactionSubstepMaxDt);
        end

        solver = NonLinearSolver();
        solver.maxTimestepCuts = 12;
        timer = tic();
        [ws, states, report] = simulateScheduleAD( ...
            state0, model, schedule, 'nonlinearSolver', solver);
        if isstruct(report) && isfield(report, 'Failure')
            assert(~report.Failure, ...
                'Simulation report indicates failure for "%s".', current.name);
        end

        metrics = collectMetrics(states, schedule, model);
        scenarios(caseNo).name = current.name;
        scenarios(caseNo).model = model;
        scenarios(caseNo).schedule = schedule;
        scenarios(caseNo).states = states;
        scenarios(caseNo).ws = ws;
        scenarios(caseNo).state0 = state0;
        scenarios(caseNo).timeDays = metrics.timeDays;
        scenarios(caseNo).snapshotIndices = metrics.snapshotIndices;
        scenarios(caseNo).snapshotLabels = metrics.snapshotLabels;
        scenarios(caseNo).aqueousH2 = metrics.aqueousH2;
        scenarios(caseNo).aqueousDIC = metrics.aqueousDIC;
        scenarios(caseNo).lossPercent = metrics.lossPercent;
        scenarios(caseNo).finalSpatialConsumptionMoles = ...
            metrics.finalSpatialConsumptionMoles;
        scenarios(caseNo).xDimensionless = metrics.xDimensionless;
        scenarios(caseNo).injectedH2Moles = metrics.injectedH2Moles;
        scenarios(caseNo).consumedH2Moles = metrics.consumedH2Moles;
        scenarios(caseNo).runtimeSeconds = toc(timer);
    end

    printSummary(scenarios);
    if opt.plotResults
        plotPhreeqcBackendComparison(scenarios, ...
            'outputDirectory', opt.outputDirectory);
    end
end

function item = makeCase(name, options, driver)
    % driver: 'plain' (simulateScheduleAD) or 'coarseSplit' (coarse-flow/
    % local-reaction split via convertToSequentialBiochemistryPhreeqcModel).
    item = struct('name', name, 'options', {options}, 'driver', driver);
end

function scenarios = initializeScenarios(nCases)
    template = struct( ...
        'name', "", 'model', [], 'schedule', [], 'states', [], ...
        'ws', [], 'state0', [], ...
        'timeDays', [], 'snapshotIndices', [], 'snapshotLabels', [], ...
        'aqueousH2', [], 'aqueousDIC', [], 'lossPercent', [], ...
        'finalSpatialConsumptionMoles', [], 'xDimensionless', [], ...
        'injectedH2Moles', nan, 'consumedH2Moles', nan, ...
        'runtimeSeconds', nan);
    scenarios = repmat(template, nCases, 1);
end

function metrics = collectMetrics(states, schedule, model)
    assert(numel(states) == numel(schedule.step.val), ...
        'Saved states and schedule must contain the same number of steps.');
    componentNames = model.EOSModel.getComponentNames();
    idxH2 = findComponentIndex(componentNames, {'H2', 'Hydrogen'});
    idxCO2 = findComponentIndex(componentNames, {'CO2', 'CarbonDioxide'});

    controls = schedule.step.control(:);
    assert(all(ismember([1, 2, 3], controls)), ...
        'The comparison requires injection, storage, and production periods.');
    snapshotIndices = [find(controls == 1, 1, 'last'), ...
        find(controls == 2, 1, 'last'), numel(states)];
    assert(all(snapshotIndices > 0), ...
        'The comparison requires injection, storage, and production periods.');
    snapshotLabels = ["End injection", "End storage", "End simulation"];

    aqueousH2 = zeros(model.G.cells.num, numel(snapshotIndices));
    aqueousDIC = zeros(model.G.cells.num, numel(snapshotIndices));
    for i = 1:numel(snapshotIndices)
        state = states{snapshotIndices(i)};
        aqueousH2(:, i) = componentColumn(state.x, idxH2);
        aqueousDIC(:, i) = aqueousDICColumn(state, model, componentNames, idxCO2);
    end

    nReactions = model.biochemFluid.nbioreact;
    cumulative = zeros(numel(states), nReactions);
    finalSpatial = zeros(model.G.cells.num, nReactions);
    for reaction = 1:nReactions
        [~, reactionCumulative] = computeH2Consumption( ...
            states, schedule, model, reaction);
        cumulative(:, reaction) = sum(reactionCumulative, 1).';
        finalSpatial(:, reaction) = reactionCumulative(:, end);
    end
    totalConsumed = sum(cumulative, 2);
    injected = prescribedInjectedH2(schedule, model);
    x = dimensionlessCellDistance(model.G);

    metrics = struct( ...
        'timeDays', cumsum(schedule.step.val(:))./day, ...
        'snapshotIndices', snapshotIndices, ...
        'snapshotLabels', snapshotLabels, ...
        'aqueousH2', aqueousH2, ...
        'aqueousDIC', aqueousDIC, ...
        'lossPercent', 100.*totalConsumed./injected, ...
        'finalSpatialConsumptionMoles', sum(finalSpatial, 2), ...
        'xDimensionless', x, ...
        'injectedH2Moles', injected, ...
        'consumedH2Moles', totalConsumed(end));
end

function dic = aqueousDICColumn(state, model, componentNames, idxCO2)
    % Total dissolved inorganic carbon (C(4)) molality, mol/kgw, so the
    % PHREEQC-coupled backends are compared on the
    % same quantity instead of the pH-slaved aqueous CO2 mole fraction.
    if isfield(state, 'phreeqcTotalCarbon') && ~isempty(state.phreeqcTotalCarbon)
        dic = reshape(value(state.phreeqcTotalCarbon), [], 1);
        return;
    end
    if isfield(state, 'Solution') && isfield(state.Solution, 'C4')
        dic = reshape(value(state.Solution.C4), [], 1);
        return;
    end
    % Backends without an aqueous carbon model (original h2-biochem): sum the
    % transported carbonate tracer and the EOS-dissolved CO2.
    idxH2O = findComponentIndex(componentNames, {'H2O', 'Water'});
    xCO2 = componentColumn(state.x, idxCO2);
    xH2O = max(componentColumn(state.x, idxH2O), eps);
    co2Molality = xCO2 ./ xH2O .* 55.508;
    if isfield(state, 'tracerHCO3') && ~isempty(state.tracerHCO3)
        hco3Molality = reshape(value(state.tracerHCO3), [], 1) ./ 1000;
    else
        hco3Molality = zeros(model.G.cells.num, 1);
    end
    dic = hco3Molality + co2Molality;
end

function column = componentColumn(composition, componentIndex)
    if iscell(composition)
        column = value(composition{componentIndex});
    else
        column = value(composition(:, componentIndex));
    end
    column = column(:);
end

function injected = prescribedInjectedH2(schedule, model)
    names = model.EOSModel.CompositionalMixture.names;
    idxH2 = findComponentIndex(names, {'H2', 'Hydrogen'});
    gasIndex = model.getVaporIndex();
    injected = 0;
    for step = 1:numel(schedule.step.val)
        wells = schedule.control(schedule.step.control(step)).W;
        for w = 1:numel(wells)
            if wells(w).sign <= 0 || ...
                    (isfield(wells, 'status') && ~wells(w).status)
                continue;
            end

            if strcmpi(wells(w).type, 'grat')
                gasRate = wells(w).val;
            elseif strcmpi(wells(w).type, 'rate')
                gasRate = wells(w).val*wells(w).compi(gasIndex);
            else
                continue;
            end
            molarRate = gasRate*model.FacilityModel.pressure/ ...
                (8.314462618*model.FacilityModel.T);
            injected = injected + molarRate*wells(w).components(idxH2)* ...
                schedule.step.val(step);
        end
    end
    assert(injected > 0, 'No prescribed H2 injection was found.');
end

function index = findComponentIndex(names, aliases)
    for i = 1:numel(aliases)
        candidate = find(strcmpi(names, aliases{i}), 1);
        if ~isempty(candidate)
            index = candidate;
            return;
        end
    end
    error('Component "%s" was not found.', strjoin(aliases, '" or "'));
end

function printSummary(scenarios)
    names = [scenarios.name].';
    injected = [scenarios.injectedH2Moles].';
    consumed = [scenarios.consumedH2Moles].';
    loss = 100.*consumed./injected;
    runtime = [scenarios.runtimeSeconds].';
    summary = table(names, injected, consumed, loss, runtime, ...
        'VariableNames', {'Backend', 'InjectedH2_mol', 'ConsumedH2_mol', ...
        'FinalH2Loss_percent', 'Runtime_seconds'});
    disp(summary);
end

function databaseFile = resolvePhreeqcDatabaseFile(databaseFile)
    assert(ischar(databaseFile) || ...
        (isstring(databaseFile) && isscalar(databaseFile)), ...
        'phreeqcDatabaseFile must be a character vector or scalar string.');
    databaseFile = char(databaseFile);
    if isempty(strtrim(databaseFile))
        databaseFile = getenv('PHREEQC_DATABASE_FILE');
    end
    if isempty(strtrim(databaseFile))
        databaseFile = which('h2_biogeochemistry.dat');
    end
    if isempty(strtrim(databaseFile)) || ~isfile(databaseFile)
        error('runThreeBackendComparison:MissingPhreeqcDatabase', ...
            ['h2_biogeochemistry.dat was not found. Pass its absolute path ', ...
            'using ''phreeqcDatabaseFile'', databaseFile.']);
    end
    [~, name, extension] = fileparts(databaseFile);
    assert(strcmpi([name, extension], 'h2_biogeochemistry.dat'), ...
        'The database must be h2_biogeochemistry.dat.');
end

function validateOptions(opt)
    validateattributes(opt.flowTimestepMaxDt, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, ...
        'runThreeBackendComparison', 'flowTimestepMaxDt');
    validateattributes(opt.reactionSubstepMaxDt, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, ...
        'runThreeBackendComparison', 'reactionSubstepMaxDt');
    validateattributes(opt.plotResults, {'logical'}, {'scalar'});
end

function validateSequentialSetup(model, state0)
    assert(model.bacterialDecayOrder == 1, ...
       'The matched sequential case requires first-order biomass decay.');
    assert(max(abs(value(state0.nbact) - 1), [], 'all') < 1e-12, ...
       'The matched sequential case requires initial N/N0 = 1.');
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).

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
