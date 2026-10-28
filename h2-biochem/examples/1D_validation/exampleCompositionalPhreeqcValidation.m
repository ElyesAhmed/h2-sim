function result = exampleCompositionalPhreeqcValidation(varargin)
    % Validate compositional PHREEQC storage with an optional external comparison
    %
    % SYNOPSIS:
    %   result = exampleCompositionalPhreeqcValidation()
    %   result = exampleCompositionalPhreeqcValidation('referenceRoot', referenceRoot)
    %   result = exampleCompositionalPhreeqcValidation( ...
    %       'referenceRoot', referenceRoot, 'totalDays', 2, 'plotResults', false)
    %
    % DESCRIPTION:
    %   Simulate hydrogen injection, storage, and production in a 50 m, 1D
    %   reservoir. The default comparison uses 20 cells, high-rate microbial
    %   kinetics, and a 250-day schedule with injection ending at day 50 and
    %   production starting at day 200. Diffusion and chemotaxis are disabled.
    %
    %   The standalone case uses the Soreide-Whitson equation of state
    %   with 2.865 mol/kg NaCl and one PHREEQC update per two-day flow step.
    %   No external checkout is needed. If referenceRoot is supplied, an optional
    %   comparison uses the same thermodynamic parameters and the reference
    %   model's five chemistry substeps, retaining its kinetic equations.
    %
    %   Reference sources are copied to a temporary folder and adapted there;
    %   the supplied checkout is unchanged. The optional reference driver uses
    %   IPhreeqcCOM and requires Windows MATLAB. This restriction applies to
    %   the external reference, rather than H2sim's native Linux integration.
    %
    % OPTIONAL PARAMETERS:
    %   referenceRoot   - Optional external reference checkout containing
    %                     examples/H2Storage1D.m (default empty: H2sim only).
    %   injectionDays   - Injection duration in days. Must be 50 for this case.
    %   totalDays       - Prefix of the storage cycle in days: a positive
    %                     multiple of two, up to 250 (default 250). Runs ending
    %                     at day 50 or earlier contain injection only.
    %   gridCells       - Number of grid cells (default 20).
    %   rate            - Microbial rate case: 'medrate' or 'highrate'
    %                     (default 'highrate').
    %   plotResults     - Plot chemistry and any reference data (default true).
    %   outputDirectory - Folder for validation_results.mat and figures
    %                     (default build/phreeqc-validation under pwd).
    %
    % RETURNS:
    %   result - Structure with h2sim (model, initial state, selected schedule,
    %            accepted states, well solutions, reports, packed problem and
    %            elapsedSeconds), referenceRoot, description, and diagnostics.
    %            Includes reference outputs only when referenceRoot is supplied.
    %
    % NOTES:
    %   The selected schedule is hashed with the model and initial state before
    %   packing. Repeating an identical setup can reuse accepted packed states;
    %   changing totalDays selects a different cache. outputDirectory controls
    %   the MAT file and figure exports, not the packed simulation cache.
    %   elapsedSeconds includes cache lookup and output loading.
    %
    %   Each call writes validation_results.mat, even when plotResults is false.
    %   Diagnostics include cumulative reaction consumption and loss relative to
    %   total prescribed H2 injection over the selected schedule. Short runs do
    %   not reproduce the complete storage and production phases.
    %
    % SEE ALSO:
    %   runPhreeqcValidation, plotCompositionalPhreeqcValidation,
    %   collectPhreeqcValidationDiagnostics

    %% Set comparison options
    opt = struct('referenceRoot',   '', ...
        'injectionDays',   50, ...
        'totalDays',       250, ...
        'gridCells',       20, ...
        'rate',            'highrate', ...
        'plotResults',     true, ...
        'outputDirectory', fullfile(pwd, 'build', 'phreeqc-validation'));
    opt = merge_options(opt, varargin{:});
    opt = validateOptions(opt);
    opt.outputDirectory = prepareOutputDirectory(opt.outputDirectory);

    %% Prepare an optional reference before starting simulations
    referenceRunRoot = '';
    referenceSetup = '';
    if ~isempty(opt.referenceRoot)
        referenceRunRoot = stageReferenceSources(opt.referenceRoot);
        referenceSetup = adaptReferenceSetup(opt);
    end

    %% Run the H2sim storage case
    h2sim = runH2simCase(opt);

    %% Optionally compare with an explicitly supplied reference
    result = struct('h2sim', h2sim, 'referenceRoot', opt.referenceRoot, ...
        'description', 'Compositional PHREEQC storage-cycle validation.');
    if ~isempty(opt.referenceRoot)
        savedPath = path;
        savedFolder = pwd;
        cleanup = onCleanup(@() restoreEnvironment(savedPath, savedFolder));
        result.referenceRunRoot = referenceRunRoot;
        result.reference = runReferenceCase(opt, referenceRunRoot, referenceSetup);
        result.referenceAdapter = ...
            'Shared SW flow/chemistry EOS and C1 methane alias; reference kinetics retained';
        result.description = ...
            'PHREEQC storage-cycle comparison with an optional external reference.';
    end

    %% Collect diagnostics and save the result
    result.diagnostics = collectPhreeqcValidationDiagnostics(result);

    saveValidationResult(result, opt.outputDirectory);
    if opt.plotResults
        plotCompositionalPhreeqcValidation(result, ...
            'outputDirectory', opt.outputDirectory);
    end
end

function opt = validateOptions(opt)
    assert(ischar(opt.referenceRoot) || ...
        (isstring(opt.referenceRoot) && isscalar(opt.referenceRoot)), ...
        'referenceRoot must be a character vector or scalar string.');
    opt.referenceRoot = char(opt.referenceRoot);
    if ~isempty(opt.referenceRoot)
        validateReferenceFiles(opt.referenceRoot);
    end
    validateattributes(opt.injectionDays, {'numeric'}, ...
        {'scalar', 'positive', '<=', 50});
    validateattributes(opt.totalDays, {'numeric'}, ...
        {'scalar', 'positive', '<=', 250});
    assert(mod(opt.totalDays, 2) == 0, ...
        'totalDays must be an integer number of 2-day flow steps.');
    assert(opt.injectionDays == 50, ...
        'The complete cycle uses a 50-day injection phase.');
    validateattributes(opt.gridCells, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});
    opt.rate = validatestring(opt.rate, {'medrate', 'highrate'});
end

function validateReferenceFiles(referenceRoot)
    required = {fullfile('examples', 'H2Storage1D.m'), ...
        fullfile('Modified_Models', 'mass2Zi.m'), ...
        fullfile('Modified_Models', 'mass2Zi_Parpool.m'), ...
        fullfile('Modified_Models', 'updateStatesFromPhreeqc.m')};
    for k = 1:numel(required)
        file = fullfile(referenceRoot, required{k});
        assert(isfile(file), 'H2sim:ReferenceDriverNotFound', ...
            'Optional reference file was not found at %s.', file);
    end
    assert(isfolder(fullfile(referenceRoot, 'examples', 'database')), ...
        'H2sim:ReferenceDatabaseNotFound', ...
        'The optional reference checkout must contain examples/database.');
    source = fileread(fullfile(referenceRoot, 'examples', 'H2Storage1D.m'));
    assert(contains(source, '%% Running the simulation'), ...
        'H2sim:ReferenceSetupChanged', 'External reference setup marker was not found.');
    assert(ispc, 'H2sim:ReferencePlatform', ...
        'The optional external reference uses Windows COM. H2sim runs without it.');
end

function directory = prepareOutputDirectory(directory)
    if ~isfolder(directory)
        mkdir(directory);
    end
    [ok, info] = fileattrib(directory);
    assert(ok, 'Unable to resolve output directory: %s', directory);
    % Resolve before the reference driver changes the working folder.
    directory = info.Name;
end

function summary = runH2simCase(opt)
    [model, schedule, state0] = setupH2simCase(opt);
    schedule = selectSchedule(schedule, opt.totalDays);

    solver = NonLinearSolver();
    solver.maxTimestepCuts = 12;
    problem = packH2simSimulationProblem(state0, model, schedule, ...
        'H2_COMPOSITIONAL_PHREEQC_VALIDATION_SW', 'NonLinearSolver', solver);
    timer = tic();
    ok = simulatePackedProblem(problem, 'continueOnError', false);
    assert(ok, 'H2sim validation case did not complete.');
    [ws, states, reports] = getPackedSimulatorOutput(problem);
    summary = struct('model',          model, ...
        'state0',         state0, ...
        'schedule',       schedule, ...
        'states',         {states}, ...
        'wellSols',       {ws}, ...
        'reports',        {reports}, ...
        'packedProblem',  problem, ...
        'elapsedSeconds', toc(timer));
end

function [model, schedule, state0] = setupH2simCase(opt)
    [~, model, schedule, state0] = setupH2StorageExampleWithSRB_benchmark( ...
        'gridCells',               opt.gridCells, ...
        'domainLength',            50, ...
        'rate',                    opt.rate, ...
        'scheduleMode',            'complete', ...
        'paperBiomassKinetics',    true, ...
        'nbact0',                  100, ...
        'injectionCO2',            0, ...
        'bacteriamodel',           true, ...
        'bactDiffusion',           false, ...
        'chemotaxisEffect',        false, ...
        'molecularDiffusion',      false, ...
        'molecularDispersion',     false, ...
        'bioClogging',             false, ...
        'carbonateBuffer',         true, ...
        'carbonateBufferPH',       6.24, ...
        'initialHCO3',             1.370e-3, ...
        'initialOverallCO2',       0, ...
        'equilibrateInitialCO2',   false, ...
        'phreeqcTimestepCoupling', true, ...
        'phreeqcBackend',          'sequential-compositional-phreeqc', ...
        'phreeqcDatabaseFile',     which('h2_biogeochemistry.dat'));
end

function schedule = selectSchedule(schedule, totalDays)
    % Keep the original controls and take complete two-day flow steps.
    nSteps = totalDays / 2;
    schedule.step.val = schedule.step.val(1:nSteps);
    schedule.step.control = schedule.step.control(1:nSteps);
end

function saveValidationResult(result, outputDirectory)
    % Write locally before copying to support output folders on WSL shares.
    localFile = [tempname, '.mat'];
    cleanup = onCleanup(@() delete(localFile));
    save(localFile, 'result', '-v7');
    copyfile(localFile, fullfile(outputDirectory, 'validation_results.mat'), 'f');
end

function referenceRoot = stageReferenceSources(sourceRoot)
    % Stage sources and database together to retain relative database paths.
    referenceRoot = tempname;
    mkdir(referenceRoot);
    modelDirectory = fullfile(referenceRoot, 'Modified_Models');
    exampleDirectory = fullfile(referenceRoot, 'examples');
    copyfile(fullfile(sourceRoot, 'Modified_Models'), modelDirectory);
    mkdir(exampleDirectory);
    copyfile(fullfile(sourceRoot, 'examples', 'database'), ...
        fullfile(exampleDirectory, 'database'));

    originalEOS = ['eos = EquationOfStateModel([], ', ...
        'model.EOSModel.CompositionalMixture, ''Peng-Robinson'');'];
    adapterNames = {'mass2Zi.m', 'mass2Zi_Parpool.m'};
    for k = 1:numel(adapterNames)
        adapterFile = fullfile(modelDirectory, adapterNames{k});
        source = fileread(adapterFile);
        assert(contains(source, originalEOS), ...
            'Reference chemistry reflash changed.');
        source = strrep(source, originalEOS, 'eos = model.EOSModel;');
        writeReferenceSource(adapterFile, source);
    end
    addTotalDICDiagnostic(modelDirectory);
end

function addTotalDICDiagnostic(modelDirectory)
    file = fullfile(modelDirectory, 'updateStatesFromPhreeqc.m');
    source = fileread(file);
    if contains(source, 'Solution.TotalDIC')
        return
    end
    % Record total DIC without changing the reference reaction equations.
    source = regexprep(source, '(C4\s*=\s*phaseData.C4;)', ...
        '$1 totalDIC = C4 + states{t,1}.x(:,3)./max(states{t,1}.x(:,1),eps)/MW_H2O;');
    source = regexprep(source, '(C4\(i\)\s*=\s*[^;]+;)', ...
        '$1 totalDIC(i) = output{end,6};');
    source = strrep(source, 'states{t,1}.Solution.C4        = C4;', ...
        ['states{t,1}.Solution.C4        = C4;', newline, ...
        'states{t,1}.Solution.TotalDIC = totalDIC;']);
    writeReferenceSource(file, source);
end

function source = adaptReferenceSetup(opt)
    source = fileread(fullfile(opt.referenceRoot, 'examples', 'H2Storage1D.m'));
    source = strrep(source, 'clear;clc;close all', '');
    source = strrep(source, '''CH4''', '''C1'''); % SW methane alias.
    source = regexprep(source, 'mrstModule add [^\n]*', '');
    marker = strfind(source, '%% Running the simulation');
    assert(~isempty(marker), 'Upstream setup marker changed.');
    source = source(1:marker(1) - 1);
    source = strrep(source, '[NX,NY,NZ]=deal(50,1,1);', ...
        sprintf('[NX,NY,NZ]=deal(%d,1,1);', opt.gridCells));

    if strcmp(opt.rate, 'highrate')
        source = regexprep(source, 'model.Kinetic.mu_MET\s*=\s*1.109', ...
            'model.Kinetic.mu_MET = 4.1');
        source = regexprep(source, 'model.Kinetic.mu_ACE\s*=\s*0.872', ...
            'model.Kinetic.mu_ACE = 1.9');
        source = regexprep(source, 'model.Kinetic.mu_SRB\s*=\s*1.048', ...
            'model.Kinetic.mu_SRB = 5.5');
        source = regexprep(source, 'model.Kinetic.K_Dmet\s*=\s*10e-6', ...
            'model.Kinetic.K_Dmet = 9e-6');
    end

    source = strrep(source, ...
        'model = GenericOverallCompositionModel_Modified(arg{:});', ...
        ['model = GenericOverallCompositionModel_Modified(arg{:});', newline, ...
        'model.EOSModel = SoreideWhitsonEos(G, mixture, ', ...
        '''msalt'', 2.865, ''pH'', 6.24, ''initial_NaCl'', 2.865, ', ...
        '''initial_SO4'', 4.664e-3, ''rho_water'', 1000);']);
    source = strrep(source, ...
        'eos = EquationOfStateModel([], mixture, ''Peng-Robinson'');', ...
        ['eos = SoreideWhitsonEos([], mixture, ''msalt'', 2.865, ', ...
        '''pH'', 6.24, ''initial_NaCl'', 2.865, ', ...
        '''initial_SO4'', 4.664e-3, ''rho_water'', 1000);']);
end

function summary = runReferenceCase(opt, referenceRunRoot, source)
    addpath(fullfile(referenceRunRoot, 'Modified_Models'));
    cd(fullfile(referenceRunRoot, 'examples'));
    % The upstream script defines model, state0, and schedule in this scope.
    [model, state0, schedule] = evaluateReferenceSetup(source);
    validateReferenceSetup(model, opt);

    model.parpool = false;
    nSteps = opt.totalDays / 2;
    schedule.step.val = repmat(2 * day, nSteps, 1);
    schedule.step.control = ones(nSteps, 1);
    schedule.step.control(cumsum(schedule.step.val) > 50 * day) = 2;
    schedule.step.control(cumsum(schedule.step.val) > 200 * day) = 3;
    problem = packH2simSimulationProblem(state0, model, schedule, ...
        'PHREEQC_REFERENCE_CYCLE_SETUP');

    timer = tic();
    [wellSol, states, report] = simulateScheduleAD_Modified(state0, model, schedule);
    validateReferenceOutput(states, report);
    % Persist reference outputs through MRST ResultHandlers as well as MAT.
    for k = 1:numel(states)
        problem.OutputHandlers.states{k} = states{k};
        problem.OutputHandlers.wellSols{k} = wellSol{k};
        problem.OutputHandlers.reports{k} = report.ControlstepReports{k};
    end
    summary = struct('model',          model, ...
        'state0',         state0, ...
        'schedule',       schedule, ...
        'states',         {states}, ...
        'wellSols',       {wellSol}, ...
        'report',         report, ...
        'packedProblem',  problem, ...
        'elapsedSeconds', toc(timer));
end

function [model, state0, schedule] = evaluateReferenceSetup(source)
    % Declare the outputs that the external setup script fills through eval.
    model = [];
    state0 = [];
    schedule = [];
    eval(source);
end

function validateReferenceSetup(model, opt)
    assert(model.G.cells.num == opt.gridCells, ...
        'Reference grid adapter did not match the requested grid.');
    actual = [model.Kinetic.mu_MET, model.Kinetic.mu_ACE, model.Kinetic.mu_SRB];
    if strcmp(opt.rate, 'highrate')
        expected = [4.1, 1.9, 5.5];
        assert(model.Kinetic.K_Dmet == 9e-6, ...
            'Reference high-rate MET half-saturation must match H2sim.');
    else
        expected = [1.109, 0.872, 1.048];
    end
    assert(all(actual == expected), ...
        'Reference microbial growth rates do not match the requested rate case.');
end

function validateReferenceOutput(states, report)
    assert(~report.Failure, 'External reference did not converge.');
    finiteState = @(state) all(isfinite(state.pressure)) && ...
        all(isfinite(state.x(:)));
    assert(all(cellfun(finiteState, states)), ...
        'External reference returned non-finite pressure or composition.');
end

function writeReferenceSource(file, source)
    fid = fopen(file, 'w');
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, source, 'char');
end

function restoreEnvironment(savedPath, savedFolder)
    path(savedPath);
    cd(savedFolder);
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
