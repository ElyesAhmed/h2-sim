function steps = rampupDomeTimesteps(duration, targetStep)
%RAMPUPDOMETIMESTEPS Two geometric ramps with the requested total duration.
%   steps = rampupDomeTimesteps(duration, targetStep) returns positive column
%   timesteps bounded by targetStep. Both arguments use the same time units.
%   Zero duration returns []. The eight-exponent ramps are scaled down when
%   the interval is shorter than two target steps. Any positive remainder
%   follows the decreasing ramp and is retained in full.

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
    validateattributes(duration, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'});
    validateattributes(targetStep, {'numeric'}, {'scalar', 'real', 'finite', 'positive'});
    if duration == 0
        steps = [];
        return;
    end
    rampStep = min(targetStep, duration/2);
    initial = (rampStep./2.^[8, 8:-1:1])';
    remaining = max(duration - sum(2.*initial), 0);
    middle = repmat(targetStep, floor(remaining/targetStep), 1);
    final = duration - sum(2.*initial) - sum(middle);
    if final <= 0
        final = [];
    end
    steps = [initial; middle; sort(initial, 'descend'); final];
end
