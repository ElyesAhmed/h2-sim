classdef H2StoreTimestepTest < matlab.unittest.TestCase
    %H2STORETIMESTEPTEST Ramp ordering and aquifer remainder conventions.
    properties (TestParameter)
        cap = {false, true}
        rampCount = {1, 2}
    end
    methods (Test)
        function rampAndRemainder(test, cap, rampCount)
            actual = rampupStorageTimesteps(49, 10, rampCount, cap);
            if rampCount == 1
                ramp = [5; 5];
            else
                ramp = [2.5; 2.5; 5];
            end
            final = 9;
            if cap
                final = ramp(1);
            end
            expected = [ramp; 10; 10; flipud(ramp); final];
            test.verifyEqual(actual, expected);
            test.verifyGreaterThan(actual, 0);
            test.verifyLessThanOrEqual(actual, 10);
            test.verifyEqual(sum(actual), 40 + final);
        end
        function exactInterval(test, cap)
            steps = rampupStorageTimesteps(40, 10, 2, cap);
            test.verifyEqual(steps, [2.5; 2.5; 5; 10; 10; 5; 2.5; 2.5]);
            test.verifyEqual(sum(steps), 40);
        end
        function zeroInterval(test)
            test.verifyEmpty(rampupStorageTimesteps(0, 10, 8));
        end
        function defaultRemainder(test)
            test.verifyEqual(rampupStorageTimesteps(49, 10, 2), ...
                rampupStorageTimesteps(49, 10, 2, false));
        end
    end
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
