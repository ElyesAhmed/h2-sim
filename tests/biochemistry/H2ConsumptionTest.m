classdef H2ConsumptionTest < matlab.unittest.TestCase
    methods (Test)

        function integratesSavedRates(test)
            [model, schedule] = fixture();
            states = {struct('h2ConsumptionRate', [1, 3; 2, 4]), ...
                struct('h2ConsumptionRate', [5, 7; 6, 8])};
            [rate, cumulative] = computeH2Consumption(states, schedule, model, 2);
            test.verifyEqual(rate, [3, 7; 4, 8]);
            test.verifyEqual(cumulative, [6, 27; 8, 32]);
        end

        function cumulativeValuesOverrideRatesWithoutClipping(test)
            [model, schedule] = fixture();
            states = {struct('cumulativeH2ConsumptionMoles', [2, 6; 4, 8], ...
                'h2ConsumptionRate', 100 * ones(2)), ...
                struct('cumulativeH2ConsumptionMoles', [1, 3; 10, 14], ...
                'h2ConsumptionRate', 100 * ones(2))};
            [rate, cumulative] = computeH2Consumption(states, schedule, model, 2);
            test.verifyEqual(cumulative, [6, 3; 8, 14]);
            test.verifyEqual(rate, [3, -1; 4, 2]);
        end

        function rejectsInconsistentCumulativeHistory(test)
            [model, schedule] = fixture();
            states = {struct('h2ConsumptionRate', ones(2)), ...
                struct('cumulativeH2ConsumptionMoles', ones(2))};
            verifyFailure(test, @() computeH2Consumption(states, schedule, model, 1), ...
                'Saved states contain an inconsistent cumulative H2 consumption history.');
        end

        function rejectsMissingSourceAndMismatchedSteps(test)
            [model, schedule] = fixture();
            verifyFailure(test, @() computeH2Consumption({struct(), struct()}, ...
                schedule, model, 1), ...
                ['Saved states do not contain the converged H2 source rate. ', ...
                'Rerun the simulation before post-processing H2 consumption.']);
            verifyFailure(test, @() computeH2Consumption({struct()}, ...
                schedule, model, 1), ...
                'states and schedule must contain the same number of timesteps.');
        end

        function acceptsEmptyHistoryAndRejectsInvalidReaction(test)
            [model, schedule] = fixture();
            schedule.step.val = [];
            [rate, cumulative] = computeH2Consumption({}, schedule, model, 1);
            test.verifySize(rate, [2, 0]);
            test.verifySize(cumulative, [2, 0]);
            verifyFailure(test, @() computeH2Consumption({}, schedule, model, 3), ...
                'idxReaction must identify an existing biochemical reaction.');
        end

    end
end

function verifyFailure(test, call, message)
    failure = [];
    try
        call();
    catch exception
        failure = exception;
    end
    test.assertNotEmpty(failure);
    test.verifyEqual(failure.identifier, '');
    test.verifyEqual(failure.message, message);
end

function [model, schedule] = fixture()
    model = struct('G', struct('cells', struct('num', 2)), ...
        'biochemFluid', struct('nbioreact', 2));
    schedule = struct('step', struct('val', [2; 3]));
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
