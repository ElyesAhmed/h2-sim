function steps = benchmarkStorageTimesteps(duration, targetStep)
    % BENCHMARKSTORAGETIMESTEPS Exact-duration two-step ramps for storage stages.
    %   steps = benchmarkStorageTimesteps(duration, targetStep) uses the same time
    %   units for both inputs and returns positive column timesteps. Each ramp
    %   has two equal half-target steps. Short intervals scale both ramps to fit.
    %   The full positive remainder is retained; zero duration returns [].

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
        return
    end
    steps = rampupStorageTimesteps(duration, min(targetStep, duration / 2), 1, false);
end
