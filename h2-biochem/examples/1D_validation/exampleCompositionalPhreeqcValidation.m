function result = exampleCompositionalPhreeqcValidation(varargin)
%Compare compositional PHREEQC coupling with the UGFACT storage-cycle model
%
% SYNOPSIS:
%   result = exampleCompositionalPhreeqcValidation('ugfactRoot', referenceRoot)
%   result = exampleCompositionalPhreeqcValidation( ...
%       'ugfactRoot', referenceRoot, 'totalDays', 2, 'plotResults', false)
%
% DESCRIPTION:
%   Simulate hydrogen injection, storage, and production in a 50 m, 1D
%   reservoir. The default comparison uses 20 cells, high-rate microbial
%   kinetics, and a 250-day schedule with injection ending at day 50 and
%   production starting at day 200. Diffusion and chemotaxis are disabled.
%
%   H2sim and the UGFACT reference use the Soreide-Whitson equation of state
%   with 2.865 mol/kg NaCl. Their chemistry splitting differs: H2sim applies
%   one PHREEQC update per two-day flow step, whereas UGFACT uses five
%   chemistry substeps. The comparison retains the reference kinetics.
%
%   Reference sources are copied to a temporary folder and adapted there;
%   the supplied UGFACT checkout is unchanged. The reference driver uses
%   IPhreeqcCOM and requires Windows MATLAB. This restriction applies to
%   the external reference, rather than H2sim's native Linux integration.
%
% OPTIONAL PARAMETERS:
%   ugfactRoot      - Path to a separate UGFACT checkout containing
%                     examples/H2Storage1D.m. Required.
%   injectionDays   - Injection duration in days. Must be 50 for this case.
%   totalDays       - Simulated duration in days: a positive multiple of
%                     two, up to 250 (default 250).
%   gridCells       - Number of grid cells (default 20).
%   rate            - Microbial rate case: 'medrate' or 'highrate'
%                     (default 'highrate').
%   plotResults     - Plot the comparison (default true).
%   outputDirectory - Folder for validation_results.mat and figures
%                     (default build/phreeqc-validation under pwd).
%
% RETURNS:
%   result - H2sim and UGFACT setups, simulation outputs, elapsed times,
%            comparison diagnostics, and reference-adapter metadata.
%
% SEE ALSO:
%   runPhreeqcValidation, plotCompositionalPhreeqcValidation,
%   collectPhreeqcValidationDiagnostics

    %% Set comparison options
    opt = struct('ugfactRoot',      '', ...
                 'injectionDays',   50, ...
                 'totalDays',       250, ...
                 'gridCells',       20, ...
                 'rate',            'highrate', ...
                 'plotResults',     true, ...
                 'outputDirectory', fullfile(pwd, 'build', 'phreeqc-validation'));
    opt = merge_options(opt, varargin{:});
    opt = validateOptions(opt);
    opt.outputDirectory = prepareOutputDirectory(opt.outputDirectory);

    %% Run the H2sim storage case
    h2sim = runH2simCase(opt);

    %% Run the reference with matching thermodynamic parameters
    % Restore the MATLAB path and working folder even if the reference fails.
    savedPath = path;
    savedFolder = pwd;
    cleanup = onCleanup(@() restoreEnvironment(savedPath, savedFolder));
    referenceRunRoot = stageReferenceSources(opt.ugfactRoot);
    ugfact = runReferenceCase(opt, referenceRunRoot);

    %% Collect diagnostics and save the comparison
    result = struct( ...
        'h2sim',           h2sim, ...
        'ugfact',          ugfact, ...
        'ugfactRoot',      opt.ugfactRoot, ...
        'referenceRunRoot', referenceRunRoot, ...
        'referenceAdapter', ...
            'Shared SW flow/chemistry EOS and C1 methane alias; upstream kinetics retained', ...
        'description', ...
            'Complete PHREEQC storage-cycle comparison; common SW parameters; distinct chemistry splitting.');
    result.diagnostics = collectPhreeqcValidationDiagnostics(result);

    % Write locally before copying to support output folders on WSL shares.
    localFile = [tempname, '.mat'];
    fileCleanup = onCleanup(@() delete(localFile));
    save(localFile, 'result', '-v7');
    copyfile(localFile, fullfile(opt.outputDirectory, 'validation_results.mat'), 'f');
    if opt.plotResults
        plotCompositionalPhreeqcValidation(result, ...
            'outputDirectory', opt.outputDirectory);
    end
end

function opt = validateOptions(opt)
    referenceFile = fullfile(opt.ugfactRoot, 'examples', 'H2Storage1D.m');
    assert(isfile(referenceFile), ...
        'Set ugfactRoot to a separate UGFACT checkout.');
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

    nSteps = opt.totalDays/2;
    schedule.step.val = schedule.step.val(1:nSteps);
    schedule.step.control = schedule.step.control(1:nSteps);

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

function referenceRoot = stageReferenceSources(ugfactRoot)
    % Stage sources and database together to retain relative database paths.
    referenceRoot = tempname;
    mkdir(referenceRoot);
    modelDirectory = fullfile(referenceRoot, 'Modified_Models');
    exampleDirectory = fullfile(referenceRoot, 'examples');
    copyfile(fullfile(ugfactRoot, 'Modified_Models'), modelDirectory);
    mkdir(exampleDirectory);
    copyfile(fullfile(ugfactRoot, 'examples', 'database'), ...
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
    source = fileread(fullfile(opt.ugfactRoot, 'examples', 'H2Storage1D.m'));
    source = strrep(source, 'clear;clc;close all', '');
    source = strrep(source, '''CH4''', '''C1'''); % SW methane alias.
    source = regexprep(source, 'mrstModule add UGFACT2[^\n]*', '');
    marker = strfind(source, '%% Running the simulation');
    assert(~isempty(marker), 'Upstream setup marker changed.');
    source = source(1:marker(1)-1);
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

function summary = runReferenceCase(opt, referenceRunRoot)
    addpath(fullfile(referenceRunRoot, 'Modified_Models'));
    source = adaptReferenceSetup(opt);
    cd(fullfile(referenceRunRoot, 'examples'));
    % The upstream script defines model, state0, and schedule in this scope.
    [model, state0, schedule] = evaluateReferenceSetup(source);
    validateReferenceSetup(model, opt);

    model.parpool = false;
    nSteps = opt.totalDays/2;
    schedule.step.val = repmat(2*day, nSteps, 1);
    schedule.step.control = ones(nSteps, 1);
    schedule.step.control(cumsum(schedule.step.val) > 50*day) = 2;
    schedule.step.control(cumsum(schedule.step.val) > 200*day) = 3;
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
    assert(~report.Failure, 'UGFACT reference did not converge.');
    finiteState = @(state) all(isfinite(state.pressure)) && ...
                           all(isfinite(state.x(:)));
    assert(all(cellfun(finiteState, states)), ...
        'UGFACT reference returned non-finite pressure or composition.');
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
