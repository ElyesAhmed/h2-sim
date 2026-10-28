function schedule = makeAquifer2DSchedule(W, options)
%MAKEAQUIFER2DSCHEDULE Assemble cushion, charge, idle and discharge controls.
%
% SYNOPSIS:
%   schedule = makeAquifer2DSchedule(W, options)
%
% PARAMETERS:
%   W       - Initial well structure from the 2D aquifer setup. The first well
%             is controlled; other wells retain their supplied settings.
%   options - Options returned by modelForSimple2DAquifer. Stage durations and
%             target timesteps must support the two eight-exponent ramps.
%
% RETURNS:
%   schedule - MRST schedule, without boundary conditions. With use_cushion,
%              cushion injection and shut-in precede numCycles repetitions of
%              charge, idle and discharge. Otherwise only the cycles are used.
%              chargeOnly, dischargeOnly and cushionOnly select single stages
%              in that priority order. cushionOnly requires use_cushion.
%
% Injection uses the tenth timestep's rate for the first nine timesteps and
% middle interval, then scales each of the last nine rates by its timestep.
% Idle and shut-in disable the first well and name its control 'shut'. The
% discharge well uses tempCushion, inherited from the idle control; the
% tempDischarge option is not used by this schedule construction.
%
% SEE ALSO:
%   modelForSimple2DAquifer, rampupStorageTimesteps, combineSchedules

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify it under the terms of the GNU 
General Public License as published by the Free Software Foundation, either version 3 of 
the License, or (at your option) any later version.

MRST is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with MRST. If not, 
see <http://www.gnu.org/licenses/>.
%}
    if options.use_cushion
        cushion = injectionStage(W, 'cushion', options.rateCushion, ...
            options.tempCushion, options.timeCushion, options.dtCushion);
    end
    charge = injectionStage(W, 'charge', options.rateCharge, ...
        options.tempCharge, options.timeCharge, options.dtCharge);
    W = charge{end}.control.W;
    W(1).val = 0;
    W(1).name = 'shut';
    W(1).T = options.tempCushion;
    W(1).sign = 0;
    W(1).status = false;
    idle = simpleSchedule(stageSteps(options.timeIdle, options.dtIdle), 'W', W);
    shut = simpleSchedule(stageSteps(options.timeShut, options.dtShut), 'W', W);
    W(1).name = 'discharge';
    W(1).val = -options.rateDischarge;
    W(1).sign = -1;
    W(1).status = true;
    discharge = simpleSchedule( ...
        stageSteps(options.timeDischarge, options.dtDischarge), 'W', W);
    if options.chargeOnly
        schedule = combineSchedules(charge{:}, 'makeConsistent', false);
    elseif options.dischargeOnly
        schedule = discharge;
    elseif options.cushionOnly
        schedule = combineSchedules(cushion{:}, 'makeConsistent', false);
    else
        cycle = combineSchedules(charge{:}, idle, discharge, ...
            'makeConsistent', false);
        cycles = repmat({cycle}, 1, options.numCycles);
        if options.use_cushion
            schedule = combineSchedules(cushion{:}, shut, cycles{:}, ...
                'makeConsistent', false);
        else
            schedule = combineSchedules(cycles{:}, 'makeConsistent', false);
        end
    end
end

function stages = injectionStage(W, name, rate, temperature, duration, targetStep)
    W(1).type = 'rate';
    W(1).name = name;
    W(1).T = temperature;
    W(1).sign = 1;
    steps = stageSteps(duration, targetStep);
    rates = rate .* steps ./ max(steps);
    groups = [num2cell(1:9), {10:numel(steps)-9}, ...
              num2cell(numel(steps)-8:numel(steps))];
    stages = cell(1, 19);
    for k = 1:19
        indices = groups{k};
        if k <= 10
            W(1).val = rates(10);
        else
            W(1).val = rates(indices);
        end
        stages{k} = simpleSchedule(steps(indices), 'W', W);
    end
end

function steps = stageSteps(duration, targetStep)
    steps = rampupStorageTimesteps(duration, targetStep, 8, false);
end
