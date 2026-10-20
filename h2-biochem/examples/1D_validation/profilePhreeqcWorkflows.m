function results = profilePhreeqcWorkflows(varargin)
%Measure PHREEQC batching and pressure-flash performance in paired runs
%
% SYNOPSIS:
%   results = profilePhreeqcWorkflows()
%   results = profilePhreeqcWorkflows('trials', 3, 'maximumFlowSteps', 2)
%
% DESCRIPTION:
%   Profile the multirate and compositional PHREEQC workflows, then compare
%   baseline and optimized timings in alternating run order. Multirate runs
%   compare pressure brackets; compositional runs compare per-cell and
%   batched chemistry calls. Each run uses the same grid, timesteps, and
%   tolerances. State comparisons check that the optimization preserves the
%   result within the specified absolute and relative tolerances.
%
% OPTIONAL PARAMETERS:
%   trials               - Number of timing pairs per backend (default 3).
%   maximumFlowSteps     - Number of flow steps per simulation (default 2).
%   backends             - Cell array containing 'multirate' and/or
%                          'compositional' (default both).
%   collectProfiles      - Collect MATLAB profiler output before the timing
%                          trials (default true). Timed pairs are unprofiled.
%   profileOnly          - Skip timing pairs (default false).
%   reuseCompletedTrials - Reuse pairs saved in outputDirectory
%                          (default false).
%   outputDirectory      - Checkpoint folder (default
%                          build/phreeqc-performance under pwd).
%
% RETURNS:
%   results - Profile data, paired timings, speedups, saved states, and
%             per-field state comparisons for each selected backend.
%
% SEE ALSO:
%   exampleSequentialBiochemistryPhreeqc1D,
%   benchmarkSequentialPhreeqcVolumeFlash

    %% Select workflows and timing options
    opt = struct('trials',                  3, ...
                 'maximumFlowSteps',        2, ...
                 'backends',                {{'multirate', 'compositional'}}, ...
                 'collectProfiles',         true, ...
                 'profileOnly',             false, ...
                 'reuseCompletedTrials',    false, ...
                 'outputDirectory',         ...
                     fullfile(pwd, 'build', 'phreeqc-performance'));
    opt = merge_options(opt, varargin{:});
    validateOptions(opt);
    cleanupProfile = onCleanup(@() profile('off'));

    %% Profile and time each workflow
    results = struct;
    for backend = opt.backends
        name = backend{1};
        if opt.collectProfiles
            profile clear
            profile on
            baseline = runCase(name, false, opt.maximumFlowSteps);
            profile off
            results.(name).profile = profile('info');
            results.(name).baseline = struct( ...
                'states', {baseline.states}, ...
                'elapsedSeconds', baseline.elapsedSeconds);
            saveCheckpoint(results, opt.outputDirectory, name);
            printProfile(results.(name).profile);
        else
            checkpoint = fullfile(opt.outputDirectory, [name, '_benchmark.mat']);
            if isfile(checkpoint)
                previous = load(checkpoint, 'results');
                results.(name) = previous.results.(name);
            end
        end
        if opt.profileOnly
            continue
        end

        seconds = zeros(opt.trials, 2);
        difference = zeros(opt.trials, 1);
        for trial = 1:opt.trials
            order = [false, true];
            if mod(trial, 2) == 0
                order = fliplr(order);
            end
            reuse = opt.reuseCompletedTrials && isfield(results, name) && ...
                isfield(results.(name), 'trials') && ...
                size(results.(name).trials, 1) >= trial && ...
                all(~cellfun(@isempty, results.(name).trials(trial, :)));
            if reuse
                paired = results.(name).trials(trial, :);
                validateSavedPair(paired, opt.maximumFlowSteps);
                fprintf('Reusing saved %s pair %d.\n', name, trial);
            else
                paired = cell(1, 2);
                for enabled = order
                    paired{1 + enabled} = runCase(name, enabled, opt.maximumFlowSteps);
                end
            end
            for enabled = order
                seconds(trial, 1 + enabled) = paired{1 + enabled}.elapsedSeconds;
            end
            for pairIndex = 1:2
                current = paired{pairIndex};
                results.(name).trials{trial, pairIndex} = struct( ...
                    'states', {current.states}, ...
                    'elapsedSeconds', current.elapsedSeconds);
            end
            saveCheckpoint(results, opt.outputDirectory, name);
            [difference(trial), comparison] = compareStates(paired{1}, paired{2}, name);
            results.(name).comparisons{trial} = comparison;
            fprintf('%s pair %d: %.6g -> %.6g s, relative difference %.4g\n', ...
                name, trial, seconds(trial, 1), seconds(trial, 2), difference(trial));
        end
        results.(name).seconds = seconds;
        results.(name).speedup = median(seconds(:, 1))/median(seconds(:, 2));
        results.(name).maximumRelativeDifference = max(difference);
        saveCheckpoint(results, opt.outputDirectory, name);
        fprintf('%s: median %.6g -> %.6g s, speedup %.4g, difference %.4g\n', ...
            name, median(seconds(:, 1)), median(seconds(:, 2)), ...
            results.(name).speedup, max(difference));
    end
end

function validateOptions(opt)
    validateattributes(opt.trials, {'numeric'}, {'scalar', 'integer', 'positive'});
    validateattributes(opt.maximumFlowSteps, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});
    assert(iscell(opt.backends) && all(ismember(opt.backends, ...
        {'multirate', 'compositional'})), 'Unknown benchmark backend.');
    validateattributes(opt.collectProfiles, {'logical'}, {'scalar'});
    validateattributes(opt.profileOnly, {'logical'}, {'scalar'});
    validateattributes(opt.reuseCompletedTrials, {'logical'}, {'scalar'});
end

function validateSavedPair(paired, steps)
    assert(all(cellfun(@(entry) numel(entry.states) == steps, paired)), ...
        'Saved trials use a different number of flow steps.');
end

function printProfile(info)
    functions = info.FunctionTable;
    [~, indices] = sort([functions.TotalTime], 'descend');
    for index = indices(1:min(20, numel(indices)))
        fprintf('%10.3f %8d %s\n', functions(index).TotalTime, ...
            functions(index).NumCalls, functions(index).FunctionName);
    end
end

function summary = runCase(backend, enabled, steps)
    if strcmp(backend, 'multirate')
        % Use fresh outputs so timings exclude cached-result retrieval.
        summary = exampleSequentialBiochemistryPhreeqc1D( ...
            'maximumFlowSteps', steps, ...
            'phreeqcReflashLocalBracket', enabled, ...
            'simulationDirectory', tempname);
        validateReflashInventory(summary.states);
        return
    end

    [~, model, schedule, state0] = setupH2StorageExampleWithSRB_benchmark( ...
        'rate',                                    'highrate', ...
        'scheduleMode',                            'complete', ...
        'injectionCO2',                            0, ...
        'bacteriamodel',                           true, ...
        'bactDiffusion',                           false, ...
        'chemotaxisEffect',                        false, ...
        'molecularDiffusion',                      false, ...
        'molecularDispersion',                     false, ...
        'bioClogging',                             false, ...
        'carbonateBuffer',                         true, ...
        'carbonateBufferPH',                       6.24, ...
        'initialHCO3',                             1.370e-3, ...
        'initialOverallCO2',                       0, ...
        'equilibrateInitialCO2',                   false, ...
        'phreeqcTimestepCoupling',                 true, ...
        'phreeqcBackend',                          'sequential-compositional-phreeqc', ...
        'phreeqcDatabaseFile',                     which('h2_biogeochemistry.dat'), ...
        'sequentialCompositionalPhreeqcBatchSize', 1);
    if enabled
        model.phreeqcCouplingOptions.sequentialCompositionalPhreeqcBatchSize = ...
            model.G.cells.num;
    end
    assert(steps <= numel(schedule.step.val), ...
        'Requested more steps than the schedule contains.');
    schedule.step.val = schedule.step.val(1:steps);
    schedule.step.control = schedule.step.control(1:steps);

    solver = NonLinearSolver();
    solver.maxTimestepCuts = 12;
    timer = tic();
    [~, states, report] = simulateScheduleAD(state0, model, schedule, ...
        'nonlinearSolver', solver);
    seconds = toc(timer);
    assert(~report.Failure, 'Simulation failed.');

    % Retain warning-based element audits for both baseline and batched runs.
    auditFailures = zeros(numel(states), 1);
    for k = 1:numel(states)
        auditFailures(k) = nnz(~states{k}.phreeqcElementBalancePass);
    end
    summary = struct('states', {states}, 'elapsedSeconds', seconds, ...
        'elementAuditFailures', auditFailures);
    fprintf('Element audit warning entries by step: %s\n', mat2str(auditFailures.'));
end

function validateReflashInventory(states)
    for k = 1:numel(states)
        assert(all(states{k}.sequentialH2BiochemPhreeqcReflashPass(:)), ...
            'Post-flash inventory audit failed.');
    end
end

function [difference, comparison] = compareStates(a, b, backend)
    assert(numel(a.states) == numel(b.states));
    fields = {'pressure', 'components', 's', 'nbact', 'phreeqcPH', ...
        'tracerHCO3', 'tracerSO4', 'tracerHS', 'tracerCa', 'tracerMg', ...
        'phreeqcMineralCalcite', 'phreeqcMineralDolomite', ...
        'phreeqcMineralAnhydrite', 'phreeqcMineralQuartz', ...
        'phreeqcMineralGoethite', 'phreeqcMineralBrucite', ...
        'phreeqcMineralPortlandite', 'phreeqcMineralPyrite', 'phreeqcMineralGypsum'};
    if strcmp(backend, 'multirate')
        fields = [fields, {'sequentialH2BiochemPhreeqcReflashActualMoles', ...
            'h2ConsumptionRate', 'sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles'}];
    else
        fields = [fields, {'sequentialCompositionalPhreeqcReactionRates', ...
            'sequentialCompositionalPhreeqcBiomassMET', ...
            'sequentialCompositionalPhreeqcBiomassACE', ...
            'sequentialCompositionalPhreeqcBiomassSRB'}];
    end

    difference = 0;
    comparison = struct;
    for k = 1:numel(a.states)
        for field = fields
            x = value(a.states{k}.(field{1}));
            y = value(b.states{k}.(field{1}));
            assert(all(isfinite(x(:))) && all(isfinite(y(:))));
            maximumConcentrationDifference = [];
            if startsWith(field{1}, 'tracer')
                % Convert mol/m^3 to moles using the chemistry handoff volume.
                if strcmp(backend, 'multirate')
                    waterField = 'sequentialH2BiochemPhreeqcInputWaterMass';
                else
                    waterField = 'sequentialCompositionalPhreeqcInputWaterMass';
                end
                maximumConcentrationDifference = max(abs(x(:) - y(:)));
                x = x(:).*a.states{k}.(waterField)/1000;
                y = y(:).*b.states{k}.(waterField)/1000;
            end
            absoluteTolerance = comparisonTolerance(field{1});
            scale = max(abs(x(:)), abs(y(:)));
            residual = abs(x(:) - y(:));
            limit = absoluteTolerance + 1e-6*scale;
            normalized = max(residual./limit);
            d = max(residual./max(scale, absoluteTolerance));
            fprintf('  %s step %d: absolute %.4g, tolerance fraction %.4g\n', ...
                field{1}, k, max(residual), normalized);
            comparison(k).(field{1}) = struct( ...
                'maximumAbsoluteDifference', max(residual), ...
                'maximumRelativeDifference', d, ...
                'maximumToleranceFraction', normalized, ...
                'maximumConcentrationDifference', maximumConcentrationDifference);
            assert(normalized <= 1, ...
                'Optimization changed %s beyond its tolerance (%.6g).', ...
                field{1}, normalized);
            difference = max(difference, d);
        end
    end
end

function tolerance = comparisonTolerance(field)
    tolerance = 1e-10;
    if strcmp(field, 'pressure')
        tolerance = 1;
    end
    if strcmp(field, 'nbact') || strcmp(field, 'phreeqcPH')
        tolerance = 1e-8;
    end
    if startsWith(field, 'tracer') || startsWith(field, 'phreeqcMineral') || ...
            endsWith(field, 'ActualMoles') || endsWith(field, 'ConsumptionMoles')
        tolerance = 1e-7;
    end
end

function saveCheckpoint(results, directory, backend)
    % MATLAB HDF5 writes can fail on WSL UNC paths; write locally, then copy.
    if isempty(directory)
        return
    end
    if ~isfolder(directory)
        mkdir(directory);
    end
    localFile = [tempname, '.mat'];
    cleanup = onCleanup(@() delete(localFile));
    save(localFile, 'results', '-v7');
    copyfile(localFile, fullfile(directory, [backend, '_benchmark.mat']), 'f');
end

%{
Copyright 2026 H2sim contributors.

This file is part of H2sim.

H2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

H2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with H2sim. If not, see <https://www.gnu.org/licenses/>.
%}
