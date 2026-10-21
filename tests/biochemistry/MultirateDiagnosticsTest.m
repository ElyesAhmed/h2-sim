classdef MultirateDiagnosticsTest < matlab.unittest.TestCase
    % Saved-result diagnostics must preserve accounting and report coverage.
    methods (Test)
        function collectsPhysicalQuantitiesWithoutSolverReports(test)
            summary = fixture();
            original = summary;
            diagnostics = reportMultirateDiagnostics(summary, 'verbose', false);
            test.verifyEqual(diagnostics.consumedH2Moles, [7, 10]);
            test.verifyEqual(diagnostics.maximumPopulationRatio, [3, 5]);
            test.verifyEqual(diagnostics.maximumBicarbonateConcentration, [2; 4]);
            test.verifyTrue(all(isnan(diagnostics.minimumExtentScale)));
            test.verifyEqual(diagnostics.limiterStatus, {'unavailable'; 'unavailable'});
            test.verifyEqual(summary, original);
        end

        function combinesAcceptedMinistepsAndExcludesRejectedAttempts(test)
            summary = fixture();
            rejected = stepReport(0.01);
            rejected.Converged = false;
            summary.report.ControlstepReports = { ...
                struct('StepReports', {{rejected, stepReport(0.8), stepReport(0.2)}}); ...
                struct('StepReports', {{stepReport([0.9, 0.7])}})};
            diagnostics = reportMultirateDiagnostics(summary, 'verbose', false);
            test.verifyEqual(diagnostics.minimumExtentScale, [0.2; 0.7]);
            test.verifyEqual(diagnostics.limiterStatus, {'available'; 'available'});
        end

        function supportsPackedExampleReportLayout(test)
            summary = fixture();
            reports = {struct('StepReports', {{stepReport(0.3)}}); ...
                       struct('StepReports', {{stepReport(0.4)}})};
            summary.report = struct('Failure', false, 'StepReports', {reports});
            diagnostics = reportMultirateDiagnostics(summary, 'verbose', false);
            test.verifyEqual(diagnostics.minimumExtentScale, [0.3; 0.4]);
            test.verifyEqual(diagnostics.limiterStatus, {'available'; 'available'});
        end

        function excludesUnconvergedNonlinearReports(test)
            summary = fixture();
            step = stepReport(0.01);
            step.NonlinearReport{1}.Converged = false;
            accepted = stepReport(0.6);
            step.NonlinearReport{2} = accepted.NonlinearReport{1};
            summary.report.ControlstepReports = { ...
                struct('StepReports', {{step}}); []};
            diagnostics = reportMultirateDiagnostics(summary, 'verbose', false);
            test.verifyEqual(diagnostics.minimumExtentScale(1), 0.6);
        end

        function marksPartialAndUnavailableCoverage(test)
            summary = fixture();
            missing = struct('Converged', true);
            summary.report.ControlstepReports = { ...
                struct('StepReports', {{stepReport(0.8), missing}}); ...
                struct('StepReports', {{missing}})};
            diagnostics = reportMultirateDiagnostics(summary, 'verbose', false);
            test.verifyEqual(diagnostics.limiterStatus, {'partial'; 'unavailable'});
            test.verifyEqual(diagnostics.minimumExtentScale(1), 0.8);
            test.verifyTrue(isnan(diagnostics.minimumExtentScale(2)));
        end

        function rejectsMalformedReports(test)
            summary = fixture();
            summary.report.ControlstepReports = { ...
                struct('StepReports', {{stepReport(Inf)}}); []};
            test.verifyError(@() reportMultirateDiagnostics(summary), ...
                'H2sim:MultirateReport');
            summary.report.ControlstepReports = {struct('StepReports', 'invalid'); []};
            test.verifyError(@() reportMultirateDiagnostics(summary), ...
                'H2sim:MultirateReport');
            summary.report.ControlstepReports = {[]};
            test.verifyError(@() reportMultirateDiagnostics(summary), ...
                'H2sim:MultirateReport');
        end

        function rejectsMismatchedStates(test)
            summary = fixture();
            summary.states = summary.states(1);
            test.verifyError(@() reportMultirateDiagnostics(summary), ...
                'H2sim:MultirateStateCount');
        end

        function legacyScriptPreservesSummaryAndCallerVariables(test)
            summary = fixture();
            original = summary;
            bf = 'caller-owned';
            r = 123;
            text = evalc('printSeqDiag');
            test.verifyEqual(summary, original);
            test.verifyEqual(bf, 'caller-owned');
            test.verifyEqual(r, 123);
            test.verifySubstring(text, '2 unavailable steps');
            test.verifySubstring(text, 'mol H2');
        end
    end
end

function summary = fixture()
    fluid = struct('nbioreact', 2, 'metabolicReaction', {{'MET', 'ACE'}});
    model = struct('biochemFluid', fluid, 'G', struct('cells', struct('num', 2)));
    first = struct('cumulativeH2ConsumptionMoles', [1, 2; 3, 4], ...
        'nbact', ones(2), 'tracerHCO3', [1; 2]);
    last = struct('cumulativeH2ConsumptionMoles', [2, 3; 5, 7], ...
        'nbact', [2, 5; 3, 4], 'tracerHCO3', [3; 4]);
    summary = struct('model', model, 'schedule', struct('step', ...
        struct('val', [2; 3])), 'states', {{first; last}});
end

function step = stepReport(values)
    substeps = arrayfun(@(x) struct('ExtentScaleMinimum', x), ...
        values, 'UniformOutput', false);
    stage = struct('ReactionSubstepReports', {substeps});
    nonlinear = struct('Converged', true, 'SequentialBiochemistryPhreeqcStages', stage);
    step = struct('Converged', true, 'NonlinearReport', {{nonlinear}});
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
