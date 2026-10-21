classdef ReactionDisabledCarbonDiagnosticTest < matlab.unittest.TestCase
% Carbon-budget diagnostics must not run in reaction-disabled stages.
    methods (Test)
        function disabledStageRetainsOtherDiagnostics(test)
            [model, schedule, state0] = fixture(false);
            requested = model.OutputStateFunctions;
            model.reactionsEnabled = false;
            [~, states, report] = simulateScheduleAD(state0, model, schedule);
            test.verifyFalse(report.Failure);
            container = model.FlowPropertyFunctions.getStateFunctionContainerName();
            test.verifyNotEmpty(states{1}.(container).PsiGrowthRate);
            test.verifyEmpty(states{1}.(container).CarbonLimitedGrowthRate);
            test.verifyEqual(model.OutputStateFunctions, requested);
            test.verifyFalse(isfield(states{1}, 'carbonSubstrateDt'));
            test.verifyFalse(isfield(states{1}, 'carbonSubstrateMoles'));
        end

        function reenabledStageStillProducesCarbonDiagnostic(test)
            [model, schedule, state0] = fixture(false);
            model.reactionsEnabled = false;
            [~, flowStates] = simulateScheduleAD(state0, model, schedule);
            model.reactionsEnabled = true;
            [~, states, report] = simulateScheduleAD(flowStates{1}, model, schedule);
            test.verifyFalse(report.Failure);
            container = model.FlowPropertyFunctions.getStateFunctionContainerName();
            test.verifyNotEmpty(states{1}.(container).CarbonLimitedGrowthRate);
            test.verifyGreaterThan(states{1}.carbonSubstrateDt, 0);
            test.verifySize(states{1}.carbonSubstrateMoles, [model.G.cells.num, 1]);
        end

        function disabledHybridReachesDriverGuard(test)
            [model, schedule, state0] = fixture(true);
            model.reactionsEnabled = false;
            test.verifyError(@() simulateScheduleAD(state0, model, schedule), ...
                'BiochemistryPhreeqcModel:SequentialH2BiochemPhreeqcRequiresPicardDriver');
        end
    end
end

function [model, schedule, state0] = fixture(coupled)
    [~, model, schedule, state0] = setupH2StorageExampleWithSRB_benchmark( ...
        'gridCells', 4, 'carbonateBuffer', true, ...
        'initialHCO3', 1.370e-3, 'initialOverallCO2', 0, ...
        'paperBiomassKinetics', true, 'nbact0', 1, ...
        'phreeqcTimestepCoupling', coupled, ...
        'phreeqcBackend', 'sequential-h2biochem-phreeqc', ...
        'phreeqcDatabaseFile', which('h2_biogeochemistry.dat'));
    schedule.step.val = 0.1*day;
    schedule.step.control = 1;
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
