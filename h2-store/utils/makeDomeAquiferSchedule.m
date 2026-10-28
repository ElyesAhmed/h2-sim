function schedule = makeDomeAquiferSchedule(initialW, options)
%MAKEDOMEAQUIFERSCHEDULE Build cyclic controls with exact stage durations.
%   schedule = makeDomeAquiferSchedule(W, options) uses dome setup options.
%   Boundary conditions are attached separately by modelForDome3DAquifer.
%   Cushion and charge durations must be positive; idle and shut-in may be zero.
%   Each positive stage retains its full final remainder. Charge rates stay
%   constant through the final ramp; cushion rates scale with its timesteps.
%   Idle controls retain rateIdle and sign -1, and discharge uses tempCushion.

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
    %% Initialize wells based on grid, rock, fluid, and options
    W = initialW;
    
    %% Cushioning phase configuration
    if options.use_cushion
        W(1).type     = 'rate';
        W(1).name     = 'cushion';
        W(1).val      = options.rateCushion;
        W(1).T        = options.tempCushion;
        W(1).sign     = 1;

        %% Generate timesteps for the cushioning phase
        dtCushions = rampupDomeTimesteps(options.timeCushion, ...
            options.dtCushion);
        rateCushion = options.rateCushion .* dtCushions ./ max(dtCushions);
        
        %% Create schedules for the initial cushioning phases
        scheduleCushions = cell(1, 19);
        for i = 1:9    
            dtCushion = dtCushions(i);
            W(1).val  = rateCushion(10);
            scheduleCushions{i} = simpleSchedule(dtCushion, 'W', W);
        end

        %% Handle remaining cushioning phases
        dtCushion = dtCushions(10:end-9);
        W(1).val  = rateCushion(10);
        scheduleCushions{10} = simpleSchedule(dtCushion, 'W', W);
        
        %% Continue with final cushioning phases
        for i = 1:9    
            dtCushion = dtCushions(end-9+i);
            W(1).val  = rateCushion(end-9+i);
            scheduleCushions{i+10} = simpleSchedule(dtCushion, 'W', W);
        end
    end

    %% Set up wells again for the charging phase
    W = initialW;
    W(1).type     = 'rate';
    W(1).name     = 'charge';    
    W(1).val      = options.rateCharge;
    W(1).T        = options.tempCharge;
    W(1).sign     = 1;
    
    %% Generate timesteps for the charging phase
    dtCharges = rampupDomeTimesteps(options.timeCharge, ...
        options.dtCharge);
    rateCharge = options.rateCharge .* dtCharges ./ max(dtCharges);
    
    %% Create schedules for the initial charging phases
    scheduleCharges = cell(1, 19);
    for i = 1:9    
        dtCharge = dtCharges(i);
        W(1).val  = rateCharge(10);
        scheduleCharges{i} = simpleSchedule(dtCharge, 'W', W);
    end

    %% Handle remaining charging phases
    dtCharge = dtCharges(10:end-9);
    W(1).val  = rateCharge(10);
    scheduleCharges{10} = simpleSchedule(dtCharge, 'W', W);

    %% Continue with final charging phases
    for i = 1:9    
        dtCharge = dtCharges(end-9+i);
        W(1).val  = rateCharge(10);
        scheduleCharges{i+10} = simpleSchedule(dtCharge, 'W', W);
    end
    

    %% Idle phase configuration
    W(1).type     = 'rate';
    W(1).val      = options.rateIdle;
    W(1).name     = 'shut';        
    W(1).T        = options.tempCushion;
    W(1).sign     = -1;
    
    %% Generate schedule for the idle phase
    dtIdle = rampupDomeTimesteps(options.timeIdle, ...
        options.dtIdle);
    scheduleIdle = simpleSchedule(dtIdle, 'W', W);
    if options.useGroupCtrl
        groups = [];
        scheduleIdle.groups = groups;
    end

    %% Shut-in phase configuration
    dtShut = rampupDomeTimesteps(options.timeShut, ...
        options.dtShut);
    scheduleShut = simpleSchedule(dtShut, 'W', W);

    %% Discharge phase configuration
    W(1).type     = 'rate';
    W(1).name     = 'discharge';    
    W(1).val      = -options.rateDischarge;
    W(1).sign     = -1;
    
    %% Generate schedule for the discharge phase
    dtDischarge = rampupDomeTimesteps(options.timeDischarge, ...
        options.dtDischarge);
    scheduleDischarge = simpleSchedule(dtDischarge, 'W', W);

    
    %% Combine schedules based on the specified options
    if options.chargeOnly
        schedule = combineSchedules(scheduleCharges{:}, 'makeConsistent', false);
    elseif options.dischargeOnly
        schedule = scheduleDischarge;
    elseif options.cushionOnly
        schedule = combineSchedules(scheduleCushions{:}, 'makeConsistent', false);
    else 
        %% Combine all schedules for normal operation
        if options.use_cushion
            schedule = combineSchedules(scheduleCharges{:}, scheduleIdle, scheduleDischarge, 'makeConsistent', false);
            schedule = repmat({schedule}, 1, options.numCycles);
            schedule = combineSchedules(scheduleCushions{:}, scheduleShut, schedule{:}, 'makeConsistent', false);
        else
            schedule = combineSchedules(scheduleCharges{:}, scheduleIdle, scheduleDischarge, 'makeConsistent', false);
            schedule = repmat({schedule}, 1, options.numCycles);
            schedule = combineSchedules(schedule{:}, 'makeConsistent', false);  
        end
    end

end
