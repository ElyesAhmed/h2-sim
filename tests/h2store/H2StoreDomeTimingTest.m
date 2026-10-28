classdef H2StoreDomeTimingTest < matlab.unittest.TestCase
    %H2STOREDOMETIMINGTEST Requested durations and complete timestep coverage.
    properties (TestParameter)
        duration = {0.01, 0.5, 1, 1.5, 2, 10, 10.35}
        target = {0.1, 1, 10}
        stage = {'cushion', 'charge', 'discharge'}
    end
    methods (Test)
        function exactInterval(test, duration, target)
            steps = rampupDomeTimesteps(duration, target);
            test.verifyEqual(sum(steps), duration, 'AbsTol', 1e-12);
            test.verifyGreaterThan(steps, 0);
            test.verifyLessThanOrEqual(steps, target);
        end
        function defaultSetupOptions(test)
            mrstModule add test-suite;
            [~, options] = modelForDome3DAquifer([], false);
            test.verifyEqual(options.dtCushion, 86400);
            W = struct('name','Prod','type','rate','val',1,'sign',1, ...
                'status',true,'compi',[0,1]);
            schedule = makeDomeAquiferSchedule(W, options);
            expected = options.timeCushion + options.timeShut + ...
                options.numCycles*(options.timeCharge + options.timeIdle + options.timeDischarge);
            test.verifyEqual(sum(schedule.step.val), expected, 'AbsTol', 1e-7);
        end
        function zeroInterval(test)
            test.verifyEmpty(rampupDomeTimesteps(0, 1));
        end
        function selectedStage(test, stage)
            [W, options] = inputs();
            options.([stage, 'Only']) = true;
            schedule = makeDomeAquiferSchedule(W, options);
            key = ['time', upper(stage(1)), stage(2:end)];
            test.verifyEqual(sum(schedule.step.val), options.(key), 'AbsTol', 1e-7);
            test.verifyGreaterThan(schedule.step.val, 0);
        end
        function fullCycleDurations(test)
            [W, options] = inputs();
            schedule = makeDomeAquiferSchedule(W, options);
            names = arrayfun(@(i) schedule.control(i).W.name, ...
                schedule.step.control(:), 'UniformOutput', false);
            totals = [sum(schedule.step.val(strcmp(names,'cushion'))), ...
                sum(schedule.step.val(strcmp(names,'charge'))), ...
                sum(schedule.step.val(strcmp(names,'shut'))), ...
                sum(schedule.step.val(strcmp(names,'discharge')))];
            n = options.numCycles;
            expected = [options.timeCushion, n*options.timeCharge, ...
                options.timeShut+n*options.timeIdle, n*options.timeDischarge];
            test.verifyEqual(totals, expected, 'AbsTol', 1e-7);
            test.verifyEqual(sum(schedule.step.val), sum(expected), 'AbsTol', 1e-7);
        end
        function shortInjection(test)
            [W, options] = inputs();
            options.timeCharge = 0.5;
            options.dtCharge = 10;
            options.chargeOnly = true;
            schedule = makeDomeAquiferSchedule(W, options);
            test.verifyEqual(sum(schedule.step.val), 0.5, 'AbsTol', 1e-14);
            test.verifyGreaterThan(schedule.step.val, 0);
        end
        function rateConventions(test)
            [W, options] = inputs();
            options.chargeOnly = true;
            schedule = makeDomeAquiferSchedule(W, options);
            for k = 1:numel(schedule.control)
                test.verifyEqual(schedule.control(k).W.val, options.rateCharge);
                test.verifyEqual(schedule.control(k).W.sign, 1);
                test.verifyEqual(schedule.control(k).W.T, options.tempCharge);
            end
        end
    end
end

function [W, options] = inputs()
    W = struct('name','Prod','type','rate','val',1,'sign',1, ...
        'status',true,'compi',[0,1]);
    options = struct('rateCushion',2e5/86400,'rateCharge',4e5/86400, ...
        'rateDischarge',4e5/86400,'rateIdle',0,'tempCushion',323.15, ...
        'tempCharge',323.15,'timeCushion',365*86400,'dtCushion',86400, ...
        'timeCharge',10*86400,'dtCharge',86400,'timeDischarge',10*86400, ...
        'dtDischarge',86400,'timeIdle',3*86400,'dtIdle',8.4*3600, ...
        'timeShut',90*86400,'dtShut',8.4*3600,'numCycles',4, ...
        'chargeOnly',false,'dischargeOnly',false,'cushionOnly',false, ...
        'use_cushion',true,'useGroupCtrl',false);
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
