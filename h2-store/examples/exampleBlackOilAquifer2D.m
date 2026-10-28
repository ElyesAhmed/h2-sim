function result = exampleBlackOilAquifer2D(varargin)
    % EXAMPLEBLACKOILAQUIFER2D Simulate structural trapping and cyclic hydrogen storage.
    %
    % SYNOPSIS:
    %   result = exampleBlackOilAquifer2D()
    %   result = exampleBlackOilAquifer2D('name', value, ...)
    %
    % OPTIONAL PARAMETERS:
    %   gridSpacing          - Target grid spacing [m], default [2, 2].
    %   numCycles            - Positive integer storage-cycle count, default 5.
    %   plotResults          - Plot simulation results and fluid tables, default true.
    %   minimumProductionBhp - Withdrawal pressure limit [Pa], default 35 bar.
    %   deckFile             - ECLIPSE deck path. Empty selects the bundled
    %                          Aquifer2D/H2STORAGE_RS.DATA deck.
    %   outputDirectory      - Folder for aquifer_results.mat and generated plots,
    %                          default build/aquifer-2d under the current folder.
    %
    % RETURNS:
    %   result - Structure containing the model, initial state, schedule, states,
    %            well solutions, reports, packed problem, resolved setup and paths.
    %            elapsedSeconds measures the packed simulation call.
    %
    % The case uses gravity, layered rock, capillarity and dissolved hydrogen.
    % Brine occupies the black-oil model's oil phase. A single well retains its
    % physical name through all controls; its stage field records each operation.
    % The initial well BHP is 5 bar above the maximum completion pressure.
    % Packed outputs persist through packH2simSimulationProblem, and the result
    % structure is also saved in outputDirectory. No PHREEQC engine is required.
    %
    % SEE ALSO:
    %   modelForSimple2DAquifer, packH2simSimulationProblem,
    %   plotBlackOilAquifer2D, plotAquiferFluidTables

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

    options = struct( ...
        'gridSpacing',          [2, 2], ...
        'numCycles',            5, ...
        'plotResults',          true, ...
        'minimumProductionBhp', 35 * barsa, ...
        'deckFile',             '', ...
        'outputDirectory',      fullfile(pwd, 'build', 'aquifer-2d'));
    options = merge_options(options, varargin{:});
    validateattributes(options.numCycles, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});
    mrstModule add ad-core ad-props ad-blackoil deckformat upr test-suite spe10;

    %% Read the deck and construct the aquifer model
    deckFile = options.deckFile;
    if isempty(deckFile)
        deckFile = fullfile(fileparts(mfilename('fullpath')), ...
            'data', 'Aquifer2D', 'H2STORAGE_RS.DATA');
    end
    assert(isfile(deckFile), 'Aquifer Eclipse deck not found: %s', deckFile);
    deck = readEclipseDeck(deckFile);
    [description, setup, state0, model, schedule] = modelForSimple2DAquifer(deck, ...
        'gridSpacing', options.gridSpacing, 'numCycles', options.numCycles);

    %% Use one physical well throughout the storage stages
    for k = 1:numel(schedule.control)
        schedule.control(k).W(1).stage = schedule.control(k).W(1).name;
        schedule.control(k).W(1).name = 'Storage';
        if strcmp(schedule.control(k).W(1).stage, 'discharge')
            schedule.control(k).W(1).lims.bhp = options.minimumProductionBhp;
        end
    end
    state0.wellSol(1).name = 'Storage';
    state0.wellSol(1).bhp = ...
        max(state0.pressure(schedule.control(1).W.cells)) + 5 * barsa;

    %% Configure the solvers and run the packed problem
    solver = NonLinearSolver();
    solver.maxTimestepCuts = 12;
    solver.LinearSolver = selectLinearSolverAD(model);
    problem = packH2simSimulationProblem(state0, model, schedule, ...
        'H2_BLACKOIL_AQUIFER_2D', 'NonLinearSolver', solver);
    timer = tic;
    completed = simulatePackedProblem(problem, 'continueOnError', false);
    elapsed = toc(timer);
    assert(completed, 'Aquifer simulation did not complete.');
    [wellSols, states, reports] = getPackedSimulatorOutput(problem);

    %% Save the result and optionally generate plots
    result = struct('description', description, 'setup', setup, 'model', model, ...
        'schedule', schedule, 'state0', state0, 'states', {states}, ...
        'wellSols', {wellSols}, 'reports', {reports}, 'packedProblem', problem, ...
        'elapsedSeconds', elapsed, 'deckFile', deckFile, ...
        'outputDirectory', options.outputDirectory);
    writeAquiferResults(result, options.outputDirectory);
    if options.plotResults
        plotBlackOilAquifer2D(result, 'outputDirectory', options.outputDirectory);
        plotAquiferFluidTables(result, 'outputDirectory', options.outputDirectory);
    end
end

function writeAquiferResults(result, outputDirectory)
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end
    file = [tempname, '.mat'];
    cleanup = onCleanup(@() delete(file));
    save(file, 'result', '-v7');
    copyfile(file, fullfile(outputDirectory, 'aquifer_results.mat'), 'f');
end
