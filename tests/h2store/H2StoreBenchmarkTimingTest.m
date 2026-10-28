classdef H2StoreBenchmarkTimingTest < matlab.unittest.TestCase
    %H2STOREBENCHMARKTIMINGTEST Benchmark stage coverage and BHP controls.
    properties (TestParameter)
        duration = {0.1, 1, 2, 10.25}
        target = {1, 10}
        stage = {'charge', 'discharge', 'cushion'}
    end
    methods (Test)
        function exactInterval(test, duration, target)
            steps = benchmarkStorageTimesteps(duration, target);
            test.verifyEqual(sum(steps), duration, 'AbsTol', 1e-12);
            test.verifyGreaterThan(steps, 0);
            test.verifyLessThanOrEqual(steps, target);
        end
        function selectedStage(test, stage)
            [W, options] = inputs();
            options.([stage,'Only']) = true;
            schedule = makeBenchmarkStorageSchedule(W, options);
            if strcmp(stage,'cushion')
                expected = 4*(options.timeCushion+options.timeShut);
            else
                field = ['time',upper(stage(1)),stage(2:end)];
                expected = options.(field);
            end
            test.verifyEqual(sum(schedule.step.val), expected, 'AbsTol', 1e-7);
        end
        function defaultStageTotals(test)
            [W, options] = inputs();
            schedule = makeBenchmarkStorageSchedule(W, options);
            names = arrayfun(@(k) schedule.control(k).W.name, ...
                schedule.step.control(:),'UniformOutput',false);
            totals = [sum(schedule.step.val(strcmp(names,'cushion'))), ...
                sum(schedule.step.val(strcmp(names,'charge'))), ...
                sum(schedule.step.val(strcmp(names,'shut'))), ...
                sum(schedule.step.val(strcmp(names,'discharge')))];
            expected = [6*options.timeCushion, options.numCycles*options.timeCharge, ...
                6*options.timeShut+options.numCycles*options.timeIdle, ...
                options.numCycles*options.timeDischarge];
            test.verifyEqual(totals, expected, 'AbsTol',1e-7);
            test.verifyEqual(sum(schedule.step.val)/86400, 1200, 'AbsTol',1e-10);
        end
        function buildupPressures(test)
            [W, options] = inputs();
            schedule = makeBenchmarkStorageSchedule(W, options);
            names = arrayfun(@(k) schedule.control(k).W.name, ...
                schedule.step.control(:),'UniformOutput',false);
            cushion = strcmp(names,'cushion');
            starts = find(cushion & [true; ~cushion(1:end-1)]);
            levels = zeros(1,numel(starts));
            for k = 1:numel(starts)
                well = schedule.control(schedule.step.control(starts(k))).W;
                test.verifyEqual(well.type,'bhp');
                levels(k) = well.val/barsa;
            end
            test.verifyEqual(levels,[90,94,98,102,102,102]);
        end
        function noCushionAndDischarge(test)
            [W, options] = inputs();
            options.use_cushion = false;
            schedule = makeBenchmarkStorageSchedule(W, options);
            expected = options.numCycles*(options.timeCharge+options.timeIdle+options.timeDischarge);
            test.verifyEqual(sum(schedule.step.val),expected,'AbsTol',1e-7);
            for k = 1:numel(schedule.control)
                well = schedule.control(k).W;
                if strcmp(well.name,'discharge')
                    test.verifyEqual(well.val,-options.rateDischarge);
                    test.verifyEqual(well.sign,-1);
                    test.verifyEqual(well.lims.bhp,20*barsa);
                    test.verifyEqual(well.cstatus,[true;false]);
                end
            end
        end
        function shortCharge(test)
            [W, options] = inputs();
            options.chargeOnly = true;
            options.timeCharge = 0.5;
            options.dtCharge = 10;
            schedule = makeBenchmarkStorageSchedule(W, options);
            test.verifyEqual(sum(schedule.step.val),0.5,'AbsTol',1e-14);
        end
    end
end

function [W, options] = inputs()
    mrstModule add test-suite;
    [~,options] = modelForUHSModifiedBenchmark([],false);
    W = struct('name','Prod','type','rate','val',options.rateCharge, ...
        'sign',1,'status',true,'compi',[0,1],'cstatus',[true;true]);
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
