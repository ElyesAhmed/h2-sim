function diagnostics = reportMultirateDiagnostics(summary, varargin)
%Report consumption, biomass and reaction limiting from a saved multirate run
%
% SYNOPSIS:
%   diagnostics = reportMultirateDiagnostics(summary);
%   diagnostics = reportMultirateDiagnostics(summary, 'verbose', false);
%
% PARAMETERS:
%   summary - Result from exampleSequentialBiochemistryPhreeqc1D, containing
%             model, schedule and accepted states. Solver reports are optional.
%
% OPTIONAL PARAMETERS:
%   verbose - Print the collected diagnostics (default true).
%
% RETURNS:
%   diagnostics - Reaction names, final consumed H2 in mol, maximum final
%                 population ratio N/N0, maximum bicarbonate concentration
%                 in mol/m^3 liquid, and one limiter minimum per control step.
%                 limiterStatus is available, partial or unavailable. Missing
%                 limiter values are NaN, not evidence of unrestricted kinetics.
%
% DESCRIPTION:
%   Both packed-example and simulateScheduleAD report layouts are accepted.
%   Limiter minima cover recorded converged nonlinear reports in accepted
%   ministeps. Rejected attempts are excluded. Partial coverage is marked
%   explicitly; malformed report data raises an error. Consumption uses the
%   existing computeH2Consumption accounting, without changing simulations.
%
% SEE ALSO:
%   exampleSequentialBiochemistryPhreeqc1D, computeH2Consumption, printSeqDiag

    opt = merge_options(struct('verbose', true), varargin{:});
    validateattributes(opt.verbose, {'logical'}, {'scalar'}, mfilename, 'verbose');
    assert(isstruct(summary) && isscalar(summary) && ...
        all(isfield(summary, {'model', 'states', 'schedule'})), ...
        'H2sim:MultirateSummary', 'Expected a saved multirate summary.');
    nSteps = numel(summary.schedule.step.val);
    assert(iscell(summary.states) && nSteps > 0 && ...
        numel(summary.states) == nSteps, 'H2sim:MultirateStateCount', ...
        'Accepted states must match the nonempty schedule.');

    fluid = summary.model.biochemFluid;
    nReactions = fluid.nbioreact;
    consumed = zeros(1, nReactions);
    for k = 1:nReactions
        [~, cumulative] = computeH2Consumption( ...
            summary.states, summary.schedule, summary.model, k);
        consumed(k) = sum(cumulative(:, end));
    end
    population = value(summary.states{end}.nbact);
    assert(size(population, 2) == nReactions, 'H2sim:MultiratePopulation', ...
        'Final biomass must have one column per reaction.');
    bicarbonate = cellfun(@(state) max(value(state.tracerHCO3)), summary.states);
    [minimumScale, status] = collectLimiter(summary, nSteps);
    diagnostics = struct('reactionNames', {fluid.metabolicReaction}, ...
        'consumedH2Moles', consumed, ...
        'maximumPopulationRatio', max(population, [], 1), ...
        'maximumBicarbonateConcentration', bicarbonate(:), ...
        'minimumExtentScale', minimumScale, 'limiterStatus', {status});
    if opt.verbose
        printDiagnostics(diagnostics);
    end
end

function [minimumScale, status] = collectLimiter(summary, nSteps)
    minimumScale = nan(nSteps, 1);
    status = repmat({'unavailable'}, nSteps, 1);
    if ~isfield(summary, 'report') || isempty(summary.report)
        return
    end
    validateReport(summary.report);
    if isfield(summary.report, 'ControlstepReports')
        reports = summary.report.ControlstepReports;
    elseif isfield(summary.report, 'StepReports')
        % exampleSequentialBiochemistryPhreeqc1D wraps packed control reports.
        reports = summary.report.StepReports;
    else
        return
    end
    assert(iscell(reports) && numel(reports) == nSteps, ...
        'H2sim:MultirateReport', 'Control-step reports must match the schedule.');
    for k = 1:nSteps
        if isempty(reports{k})
            continue
        end
        validateReport(reports{k});
        if ~isfield(reports{k}, 'StepReports')
            continue
        end
        steps = reports{k}.StepReports;
        assert(iscell(steps), 'H2sim:MultirateReport', ...
            'StepReports must be a cell array.');
        expected = 0;
        available = 0;
        for j = 1:numel(steps)
            validateReport(steps{j});
            assert(isfield(steps{j}, 'Converged') && ...
                (islogical(steps{j}.Converged) || isnumeric(steps{j}.Converged)) && ...
                isreal(steps{j}.Converged) && isscalar(steps{j}.Converged) && ...
                any(steps{j}.Converged == [false, true]), ...
                'H2sim:MultirateReport', 'Ministeps need a scalar convergence flag.');
            if ~steps{j}.Converged
                continue
            end
            expected = expected + 1;
            scale = readLimiter(steps{j});
            if ~isnan(scale)
                available = available + 1;
                if isnan(minimumScale(k))
                    minimumScale(k) = scale;
                else
                    minimumScale(k) = min(minimumScale(k), scale);
                end
            end
        end
        if available > 0
            if available == expected
                status{k} = 'available';
            else
                status{k} = 'partial';
            end
        end
    end
end

function scale = readLimiter(step)
    scale = NaN;
    if ~isfield(step, 'NonlinearReport')
        return
    end
    assert(iscell(step.NonlinearReport), 'H2sim:MultirateReport', ...
        'NonlinearReport must be a cell array.');
    for j = 1:numel(step.NonlinearReport)
        current = step.NonlinearReport{j};
        validateReport(current);
        if ~isfield(current, 'SequentialBiochemistryPhreeqcStages')
            continue
        end
        assert(isfield(current, 'Converged') && ...
            (islogical(current.Converged) || isnumeric(current.Converged)) && ...
            isreal(current.Converged) && isscalar(current.Converged) && ...
            any(current.Converged == [false, true]), ...
            'H2sim:MultirateReport', 'Reaction-stage reports need a convergence flag.');
        if ~current.Converged
            continue
        end
        stage = current.SequentialBiochemistryPhreeqcStages;
        validateReport(stage);
        if ~isfield(stage, 'ReactionSubstepReports') || isempty(stage.ReactionSubstepReports)
            continue
        end
        substeps = stage.ReactionSubstepReports;
        assert(iscell(substeps), 'H2sim:MultirateReport', ...
            'ReactionSubstepReports must be a cell array.');
        values = zeros(numel(substeps), 1);
        for k = 1:numel(substeps)
            validateReport(substeps{k});
            assert(isfield(substeps{k}, 'ExtentScaleMinimum'), ...
                'H2sim:MultirateReport', 'Reaction reports need ExtentScaleMinimum.');
            value = substeps{k}.ExtentScaleMinimum;
            assert(isnumeric(value) && isreal(value) && isscalar(value) && ...
                isfinite(value) && value >= 0 && value <= 1, ...
                'H2sim:MultirateReport', 'ExtentScaleMinimum must be finite in [0, 1].');
            values(k) = value;
        end
        if isnan(scale)
            scale = min(values);
        else
            scale = min(scale, min(values));
        end
    end
end

function validateReport(report)
    assert(isstruct(report) && isscalar(report), 'H2sim:MultirateReport', ...
        'Expected a scalar solver-report struct.');
end

function printDiagnostics(diagnostics)
    fprintf('\nFinal reaction-specific H2 consumption and biomass:\n');
    for k = 1:numel(diagnostics.reactionNames)
        fprintf('  %-25s %10.4g mol H2 | max N/N0 %.4g\n', ...
            diagnostics.reactionNames{k}, diagnostics.consumedH2Moles(k), ...
            diagnostics.maximumPopulationRatio(k));
    end
    complete = strcmp(diagnostics.limiterStatus, 'available');
    partial = strcmp(diagnostics.limiterStatus, 'partial');
    fprintf('\nLimiter coverage: %d complete, %d partial, %d unavailable steps.\n', ...
        nnz(complete), nnz(partial), nnz(~complete & ~partial));
    observed = diagnostics.minimumExtentScale(~isnan(diagnostics.minimumExtentScale));
    if ~isempty(observed)
        fprintf('Recorded limiter minima: min %.3g | median %.3g | below 0.5: %d.\n', ...
            min(observed), median(observed), nnz(observed < 0.5));
    end
    bicarbonate = diagnostics.maximumBicarbonateConcentration;
    fprintf('\nMaximum bicarbonate [mol/m^3 liquid]: start %.3g | min %.3g | end %.3g.\n', ...
        bicarbonate(1), min(bicarbonate), bicarbonate(end));
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
