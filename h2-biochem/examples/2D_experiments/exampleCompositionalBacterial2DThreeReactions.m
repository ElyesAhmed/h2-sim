function results = exampleCompositionalBacterial2DThreeReactions(varargin)
%Compare microbial and abiotic hydrogen storage in a 2D structural trap
%
% SYNOPSIS:
%   results = exampleCompositionalBacterial2DThreeReactions();
%   results = exampleCompositionalBacterial2DThreeReactions( ...
%       'scenarios', {'bacterial', 'abiotic'}, ...
%       'molecularDiffusion', false, 'molecularDispersion', false);
%
% DESCRIPTION:
%   Simulate cyclic hydrogen storage with residual methane, methanogenesis,
%   acetogenesis and sulfate reduction. SO4 and HS are aqueous tracers; H2S
%   is an EOS component. Kinetics use the existing biochemical tables, with
%   no PHREEQC coupling. Initial biomass is [15, 15, 15] in model units;
%   temperature is 317.50 K, sulfate is 0.1 mol/kg water, and EOS pH is 7.2.
%   The EOS salinity parameter is zero. Flow controls and layered geometry
%   come from modelForSimple2DAquifer and the bundled illustrative deck.
%
% OPTIONAL PARAMETERS:
%   numCycles           - Number of storage cycles (default 5).
%   gridSpacing         - Two positive PEBI target spacings in m ([0.5, 0.5]).
%   scenarios           - Cell array selecting clogging, bacterial, abiotic
%                         (default all three, in that order).
%   molecularDiffusion  - Include molecular diffusion (default true).
%   molecularDispersion - Include mechanical dispersion (default true).
%   maximumFlowSteps    - Positive integer prefix limit, or Inf (default Inf).
%   plotResults         - Plot when all scenarios are complete (default true).
%   deckFile            - Input deck (default bundled Aquifer2D deck).
%   outputDirectory     - Compact results and figures (default
%                         build/compositional-2d-three-reactions).
%   simulationDirectory - Packed-output root (default empty: MRST default).
%
% RETURNS:
%   results - One struct per selected scenario with the model, initial state,
%             accepted states, well outputs, reports and packed setup. A
%             limited run writes a prefix of the full packed case and sets
%             complete=false, allowing a subsequent run to resume the setup.
%
% NOTE:
%   The website selects bacterial/abiotic cases and disables molecular
%   transport. A short prefix or coarser teaching grid does not reproduce
%   its full five-cycle results. Reported consumption is not a conservation
%   or convergence proof.
%
% SEE ALSO:
%   modelForSimple2DAquifer, plotCompositionalBacterial2DThreeReactions,
%   packH2simSimulationProblem

    %% Select cases and load the layered aquifer
    opt = struct('numCycles', 5, 'gridSpacing', [0.5, 0.5], ...
        'scenarios', {{'clogging', 'bacterial', 'abiotic'}}, ...
        'molecularDiffusion', true, 'molecularDispersion', true, ...
        'maximumFlowSteps', inf, 'plotResults', true, 'deckFile', '', ...
        'outputDirectory', fullfile(pwd, 'build', 'compositional-2d-three-reactions'), ...
        'simulationDirectory', '');
    opt = merge_options(opt, varargin{:});
    opt = validateOptions(opt);
    mrstModule add ad-core ad-blackoil ad-props deckformat upr test-suite spe10 compositional
    deck = readEclipseDeck(opt.deckFile);
    [description, setup, state0Bo, modelBo, schedule] = modelForSimple2DAquifer( ...
        deck, 'numCycles', opt.numCycles, 'gridSpacing', opt.gridSpacing);

    %% Define components, reactions and initial conditions
    compFluid = h2BiochemCompositionalMixture( ...
        {'Water', 'Hydrogen', 'CarbonDioxide', 'Methane', 'HydrogenSulfide', 'AceticAcid'}, ...
        {'H2O', 'H2', 'CO2', 'C1', 'H2S', 'CH3COOH'});
    biochemFluid = TableBioChemMixture( ...
        {'MethanogenicArchae', 'AcetogenicBacteria', 'SulfateReducingBacteria'}, ...
        {'bactM', 'bactA', 'bactS'});
    initial = struct('sulfateMolality', 0.1, 'temperature', 273.15 + 44.35, ...
        'biomass', [15, 15, 15], 'composition', [0.8480, 1e-5, 1e-5, 0.1530, 0, 0]);
    initial.composition = initial.composition/sum(initial.composition);
    schedule = configureSchedule(schedule, initial.temperature);

    %% Run or resume each selected scenario
    if ~isfolder(opt.outputDirectory)
        mkdir(opt.outputDirectory);
    end
    caseResults = cell(1, numel(opt.scenarios));
    for j = 1:numel(opt.scenarios)
        scenario = opt.scenarios{j};
        [model, state0] = setupScenario(modelBo, state0Bo, schedule, ...
            compFluid, biochemFluid, initial, scenario, opt);
        caseResults{j} = runScenario(model, state0, schedule, scenario, ...
            description, setup, opt);
    end
    results = [caseResults{:}];

    %% Inspect completed results
    if opt.plotResults && all([results.complete])
        plotCompositionalBacterial2DThreeReactions(results, ...
            'outputDirectory', opt.outputDirectory);
    end
end

function opt = validateOptions(opt)
    validateattributes(opt.numCycles, {'numeric'}, ...
        {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'numCycles');
    validateattributes(opt.gridSpacing, {'numeric'}, ...
        {'vector', 'numel', 2, 'positive', 'finite', 'real'}, mfilename, 'gridSpacing');
    validateattributes(opt.maximumFlowSteps, {'numeric'}, ...
        {'scalar', 'positive', 'real'}, mfilename, 'maximumFlowSteps');
    assert(isinf(opt.maximumFlowSteps) || ...
        opt.maximumFlowSteps == floor(opt.maximumFlowSteps), ...
        'H2sim:StorageStepLimit', 'maximumFlowSteps must be a positive integer or Inf.');
    validateattributes(opt.scenarios, {'cell'}, {'vector', 'nonempty'}, ...
        mfilename, 'scenarios');
    for k = 1:numel(opt.scenarios)
        opt.scenarios{k} = validatestring(opt.scenarios{k}, ...
            {'clogging', 'bacterial', 'abiotic'}, mfilename, 'scenarios');
    end
    if isempty(opt.deckFile)
        opt.deckFile = fullfile(h2simRoot(), 'h2-store', 'examples', 'data', ...
            'Aquifer2D', 'H2STORAGE_RS.DATA');
    end
end

function schedule = configureSchedule(schedule, temperature)
    for k = 1:numel(schedule.control)
        W = schedule.control(k).W;
        W.stage = W.name;
        W.name = 'Storage';
        W.compi = [0, 1];
        if strcmp(W.stage, 'cushion') && k < 11
            W.components = [0, .1, .9, 0, 0, 0];
        else
            W.components = [0, .95, .05, 0, 0, 0];
        end
        W.T = temperature;
        if strcmp(W.stage, 'discharge')
            W.lims.bhp = 35*barsa;
        end
        schedule.control(k).W = W;
        schedule.control(k).bc = [];
    end
end

function [model, state0] = setupScenario(modelBo, state0Bo, schedule, ...
        compFluid, biochemFluid, initial, scenario, opt)
    backend = DiagonalAutoDiffBackend('modifyOperators', true);
    model = BiochemistryModel(modelBo.G, modelBo.rock, modelBo.fluid, compFluid, ...
        biochemFluid, false, backend, 'oil', true, 'gas', true, ...
        'bacteriamodel', ~strcmp(scenario, 'abiotic'), 'bactDiffusion', false, ...
        'chemotaxisEffect', false, 'molecularDiffusion', opt.molecularDiffusion, ...
        'molecularDispersion', opt.molecularDispersion, ...
        'liquidPhase', 'O', 'vaporPhase', 'G');
    model.EOSModel = SoreideWhitsonEos(model.G, compFluid, 'msalt', 0, 'pH', 7.2, ...
        'initial_NaCl', 0, 'initial_SO4', initial.sulfateMolality, 'rho_water', 1000);
    model.gravity = modelBo.gravity;
    model.outputFluxes = false;
    model = setupBioCloggingModel(model, initial.biomass, ...
        [120, 120, 120], [1, 1, 1], strcmp(scenario, 'clogging'));
    model.OutputStateFunctions{end + 1} = 'ComponentPhaseDensity';
    if model.bacteriamodel
        state0 = initCompositionalStateBacteria(model, state0Bo.pressure, ...
            initial.temperature, state0Bo.s, initial.composition, ...
            initial.biomass, model.EOSModel);
    else
        state0 = initCompositionalState(model, state0Bo.pressure, ...
            initial.temperature, state0Bo.s, initial.composition, model.EOSModel);
    end
    state0.tracerSO4 = repmat(initial.sulfateMolality*1000, model.G.cells.num, 1);
    state0.tracerHS = zeros(model.G.cells.num, 1);
    state0.h2sDissolvedLag = zeros(model.G.cells.num, 1);
    state0.wellSol = initWellSolAD(schedule.control(1).W, model, state0);
    state0.wellSol.bhp = max(state0.pressure(schedule.control(1).W.cells)) + 5*barsa;
end

function result = runScenario(model, state0, schedule, scenario, description, setup, opt)
    [solver, ~] = setupOptimizedLinearSolver(model, 'complexityLevel', 'low', ...
        'solverTolerance', 1e-4, 'maxNonlinIter', 20);
    solver.maxTimestepCuts = 12;
    packingOptions = {'NonLinearSolver', solver};
    if ~isempty(opt.simulationDirectory)
        packingOptions = [packingOptions, {'Directory', opt.simulationDirectory}];
    end
    problem = packH2simSimulationProblem(state0, model, schedule, ...
        ['H2_COMPOSITIONAL_2D_THREE_REACTIONS_', upper(scenario)], packingOptions{:});
    resultFile = fullfile(opt.outputDirectory, [scenario, '_results.mat']);
    if isfile(resultFile) && isinf(opt.maximumFlowSteps)
        saved = loadH2simResults(resultFile, 'result');
        if saved.result.complete && strcmp(saved.result.packedProblem.Name, problem.Name) && ...
                problem.OutputHandlers.reports.numelData() == numel(schedule.step.val)
            result = saved.result;
            validateResult(result, numel(schedule.step.val));
            fprintf('REUSED %s: %d saved physical states.\n', scenario, numel(result.states));
            return
        end
        % Release a mismatched saved history before allocating new states.
        clear saved
    end

    % A limited run writes a prefix while retaining the full setup/cache identity.
    runProblem = problem;
    limit = min(numel(schedule.step.val), opt.maximumFlowSteps);
    if limit < numel(schedule.step.val)
        runProblem.SimulatorSetup.schedule.step.val = schedule.step.val(1:limit);
        runProblem.SimulatorSetup.schedule.step.control = schedule.step.control(1:limit);
    end
    timer = tic;
    ok = simulatePackedProblem(runProblem, 'continueOnError', false);
    assert(ok, 'Case failed: %s', scenario);
    [ws, states, reports] = getH2simPackedPhysicalOutput(runProblem);
    result = struct('name', scenario, 'description', description, 'setup', setup, ...
        'model', model, 'state0', state0, 'schedule', runProblem.SimulatorSetup.schedule, ...
        'states', {states}, 'wellSols', {ws}, 'reports', {reports}, ...
        'packedProblem', problem, 'elapsedSeconds', toc(timer), ...
        'complete', limit == numel(schedule.step.val));
    validateResult(result, limit);
    saveResult(resultFile, result);
    fprintf('SAVED %s: %d cells, %d steps, %.1f seconds.\n', ...
        scenario, model.G.cells.num, numel(states), result.elapsedSeconds);
end

function validateResult(result, expectedSteps)
    assert(numel(result.states) == expectedSteps && ...
        numel(result.wellSols) == expectedSteps && numel(result.reports) == expectedSteps && ...
        all(~cellfun(@isempty, result.states)), ...
        'H2sim:StorageOutputCount', 'Packed states, wells and reports must match the requested steps.');
end

function saveResult(filename, result)
    file = [tempname, '.mat'];
    cleanup = onCleanup(@() delete(file));
    save(file, 'result', '-v7.3');
    copyfile(file, filename, 'f');
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
