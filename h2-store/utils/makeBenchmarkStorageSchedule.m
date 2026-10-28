function schedule = makeBenchmarkStorageSchedule(initialW, options)
%MAKEBENCHMARKSTORAGESCHEDULE Assemble modified benchmark storage controls.
%   schedule = makeBenchmarkStorageSchedule(W, options) returns a schedule
%   without boundary conditions. Injection stages cover each timestep once,
%   using two opening controls, one middle control and two closing controls.
%   Charge rates are constant; cushion rate controls scale the final ramp.
%
% Default BHP buildup consists of six cushion/shut-in pairs at options.bhp,
% 94, 98, 102, 102 and 102 bar, followed by numCycles storage cycles. Cushion-only
% selects the first four pairs. numCyclesCushions is not applied. Later buildup
% values are assigned even if use_bhp=false, which interprets them as rates.
% BHP-controlled buildup is the tested benchmark mode. Idle has sign +1;
% discharge has sign -1, a 20 bar BHP limit and only its first completion open.

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}
    if options.use_cushion
        W = initialW;
        W(1).name = 'cushion';
        W(1).T = options.tempCushion;
        W(1).sign = 1;
        if options.use_bhp
            W(1).type = 'bhp';
            W(1).val = options.bhp;
        else
            W(1).type = 'rate';
            W(1).val = options.rateCushion;
        end
        cushion = injectionStages(W, options.timeCushion, options.dtCushion, ...
            ~options.use_bhp);
    end
    W = initialW;
    W(1).type = 'rate';
    W(1).name = 'charge';
    W(1).T = options.tempCharge;
    W(1).val = options.rateCharge;
    W(1).sign = 1;
    charge = injectionStages(W, options.timeCharge, options.dtCharge, false);
    W(1).name = 'shut';
    W(1).T = options.tempCushion;
    W(1).val = options.rateIdle;
    W(1).sign = 1;
    idle = simpleSchedule(benchmarkStorageTimesteps(options.timeIdle, options.dtIdle), 'W', W);
    if options.useGroupCtrl
        idle.groups = [];
    end
    shut = simpleSchedule(benchmarkStorageTimesteps(options.timeShut, options.dtShut), 'W', W);
    W(1).name = 'discharge';
    W(1).val = -options.rateDischarge;
    W(1).sign = -1;
    W(1).lims.bhp = 20*barsa;
    W(1).cstatus(2:end) = 0;
    discharge = simpleSchedule( ...
        benchmarkStorageTimesteps(options.timeDischarge, options.dtDischarge), 'W', W);
    if options.chargeOnly
        schedule = combineSchedules(charge{:}, 'makeConsistent', false);
    elseif options.dischargeOnly
        schedule = discharge;
    else
        cycle = combineSchedules(charge{:}, idle, discharge, 'makeConsistent', false);
        cycles = repmat({cycle}, 1, options.numCycles);
        if options.use_cushion
            buildup = cell(1, 4);
            levels = [options.bhp, 94*barsa, 98*barsa, 102*barsa];
            for k = 1:4
                if k > 1
                    for j = 1:numel(cushion)
                        cushion{j}.control.W.val = levels(k);
                    end
                end
                buildup{k} = combineSchedules(cushion{:}, shut, 'makeConsistent', false);
            end
            if options.cushionOnly
                schedule = combineSchedules(buildup{:}, 'makeConsistent', false);
            else
                schedule = combineSchedules(buildup{:}, buildup{4}, buildup{4}, ...
                    cycles{:}, 'makeConsistent', false);
            end
        else
            schedule = combineSchedules(cycles{:}, 'makeConsistent', false);
        end
    end
end

function stages = injectionStages(W, duration, targetStep, scaleClosingRate)
    validateattributes(duration, {'numeric'}, {'positive'});
    steps = benchmarkStorageTimesteps(duration, targetStep);
    groups = {1, 2, 3:numel(steps)-2, numel(steps)-1, numel(steps)};
    stages = cell(1, 5);
    rate = W(1).val;
    for k = 1:5
        indices = groups{k};
        if scaleClosingRate && k > 3
            W(1).val = rate.*steps(indices)./max(steps);
        end
        stages{k} = simpleSchedule(steps(indices), 'W', W);
    end
end
