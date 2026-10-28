function steps = rampupStorageTimesteps(duration, targetStep, rampCount, capFinalStep)
%RAMPUPSTORAGETIMESTEPS Build timesteps with geometric ramps at both ends.
%
% SYNOPSIS:
%   steps = rampupStorageTimesteps(duration, targetStep, rampCount)
%   steps = rampupStorageTimesteps(duration, targetStep, rampCount, true)
%
% PARAMETERS:
%   duration     - Requested interval length, in the same units as targetStep.
%   targetStep   - Timestep between the two ramps.
%   rampCount    - Ramp exponent. The initial ramp has rampCount + 1 steps,
%                  starting with two steps of targetStep/2^rampCount.
%   capFinalStep - Limit the final remainder to the first ramp step. Default
%                  false. The dome and benchmark setups enable this option;
%                  it can make the total shorter than duration.
%
% RETURNS:
%   steps - Column vector: increasing ramp, target steps, decreasing ramp,
%           then a positive remainder, if present. A zero duration returns [].
%
% The interval must accommodate both ramps.

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
    if nargin < 4
        capFinalStep = false;
    end
    if duration == 0
        steps = [];
        return;
    end
    initial = (targetStep./2.^[rampCount, rampCount:-1:1])';
    elapsed = cumsum(initial);
    if any(elapsed > duration)
        initial = initial(elapsed < duration);
    end
    remaining = duration - sum(2.*initial);
    middle = repmat(targetStep, floor(remaining/targetStep), 1);
    final = duration - sum(2.*initial) - sum(middle);
    if final <= 0
        final = [];
    end
    if capFinalStep
        if final >= initial(1)
            final = initial(1);
        end
    end
    steps = [initial; middle; sort(initial, 'descend'); final];
end
