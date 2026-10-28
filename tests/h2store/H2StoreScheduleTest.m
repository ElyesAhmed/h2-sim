classdef H2StoreScheduleTest < matlab.unittest.TestCase
    %H2STORESCHEDULETEST Stage ordering, controls, rates and temperature.
    properties (TestParameter)
        stage = {'charge', 'discharge', 'cushion'}
        useCushion = {false, true}
    end
    methods (Test)
        function singleStage(test, stage)
            [W, options] = inputs();
            options.([stage, 'Only']) = true;
            schedule = makeAquifer2DSchedule(W, options);
            field = ['time', upper(stage(1)), stage(2:end)];
            test.verifyEqual(sum(schedule.step.val), options.(field), 'AbsTol', 1e-12);
            for k = 1:numel(schedule.control)
                test.verifyEqual(schedule.control(k).W.name, stage);
            end
        end
        function cycleOrder(test, useCushion)
            [W, options] = inputs();
            options.use_cushion = useCushion;
            schedule = makeAquifer2DSchedule(W, options);
            names = arrayfun(@(k) schedule.control(k).W.name, ...
                schedule.step.control(:), 'UniformOutput', false);
            transitions = [true; ~strcmp(names(2:end), names(1:end-1))];
            expected = {'charge'; 'shut'; 'discharge'; 'charge'; 'shut'; 'discharge'};
            duration = 2*(100 + 30 + 80);
            if useCushion
                expected = [{'cushion'; 'shut'}; expected];
                duration = duration + 120 + 40;
            end
            test.verifyEqual(names(transitions), expected);
            test.verifyEqual(sum(schedule.step.val), duration, 'AbsTol', 1e-12);
            test.verifyGreaterThan(schedule.step.val, 0);
            test.verifyGreaterThanOrEqual(schedule.step.control, 1);
            test.verifyLessThanOrEqual(schedule.step.control, numel(schedule.control));
        end
        function injectionRates(test)
            [W, options] = inputs();
            options.chargeOnly = true;
            schedule = makeAquifer2DSchedule(W, options);
            rates = arrayfun(@(control) control.W.val, schedule.control);
            test.verifyNumElements(rates, 19);
            test.verifyEqual(rates(1:10), repmat(options.rateCharge, 10, 1));
            tail = [5, 2.5, 1.25, 0.625, 0.3125, 0.15625, ...
                    0.078125, 0.0390625, 0.0390625];
            test.verifyEqual(rates(11:19), options.rateCharge*tail(:)/10);
        end
        function idleAndDischargeControls(test)
            [W, options] = inputs();
            schedule = makeAquifer2DSchedule(W, options);
            for k = 1:numel(schedule.control)
                well = schedule.control(k).W;
                if strcmp(well.name, 'shut')
                    test.verifyFalse(well.status);
                    test.verifyEqual(well.val, 0);
                    test.verifyEqual(well.sign, 0);
                elseif strcmp(well.name, 'discharge')
                    test.verifyTrue(well.status);
                    test.verifyEqual(well.val, -options.rateDischarge);
                    test.verifyEqual(well.sign, -1);
                    test.verifyEqual(well.T, options.tempCushion);
                else
                    test.verifyEqual(well.sign, 1);
                end
                test.verifyEqual(well.compi, [0, 1]);
            end
        end
        function suppliedWellIsUnchanged(test)
            [W, options] = inputs();
            before = W;
            makeAquifer2DSchedule(W, options);
            test.verifyEqual(W, before);
        end
        function singleStagePriority(test)
            [W, options] = inputs();
            options.chargeOnly = true;
            options.dischargeOnly = true;
            options.cushionOnly = true;
            schedule = makeAquifer2DSchedule(W, options);
            test.verifyEqual(schedule.control(1).W.name, 'charge');
        end
    end
end

function [W, options] = inputs()
    W = struct('name', 'Prod', 'type', 'rate', 'val', 18, ...
        'compi', [0, 1], 'sign', 1, 'status', true);
    options = struct('use_cushion', true, 'numCycles', 2, ...
        'chargeOnly', false, 'dischargeOnly', false, 'cushionOnly', false, ...
        'rateCharge', 18, 'rateCushion', 12, 'rateDischarge', 8, ...
        'tempCharge', 313, 'tempCushion', 303, 'tempDischarge', 333, ...
        'timeCharge', 100, 'timeCushion', 120, 'timeIdle', 30, ...
        'timeShut', 40, 'timeDischarge', 80, ...
        'dtCharge', 10, 'dtCushion', 10, 'dtIdle', 10, ...
        'dtShut', 10, 'dtDischarge', 10);
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
