function lastSteps = getCyclesLastSteps(schedule)
    % GETCYCLESLASTSTEPS Last schedule step of each storage stage.
    %
    % SYNOPSIS:
    %   lastSteps = getCyclesLastSteps(schedule)
    %
    % RETURNS:
    %   lastSteps - Struct of step indices, grouped by the stage assigned to
    %               the first well in each control. Adjacent equal stage names
    %               form one stage, even when the control index changes.
    %               Well names are used when the stage field is absent.
    %               The standard stage fields are present for empty schedules.

    lastSteps = struct('charge', [], 'discharge', [], 'shut', [], 'cushion', []);
    n = numel(schedule.step.control);
    for i = 1:n
        current = stageName(schedule.control(schedule.step.control(i)));
        if i < n
            next = stageName(schedule.control(schedule.step.control(i + 1)));
        else
            next = '';
        end
        if i == n || ~strcmp(current, next)
            if ~isfield(lastSteps, current)
                lastSteps.(current) = [];
            end
            lastSteps.(current)(end + 1) = i;
        end
    end
end

function name = stageName(control)
    if isfield(control.W, 'stage')
        name = control.W(1).stage;
    else
        name = control.W(1).name;
    end
end

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
