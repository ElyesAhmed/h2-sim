classdef H2BiochemParallelTest < matlab.unittest.TestCase
 methods (Test)
  function serialDefaultDoesNotProbeToolbox(test)
   test.verifyFalse(resolveH2BiochemParallel(false,@() error('Unexpected license check')));
  end
  function unavailableToolboxFallsBack(test)
   test.verifyWarning(@() resolveH2BiochemParallel(true,@() false), ...
      'H2Biochem:ParallelUnavailable');
   saved=warning('off','H2Biochem:ParallelUnavailable');
   cleanup=onCleanup(@() warning(saved)); %#ok<NASGU>
   test.verifyFalse(resolveH2BiochemParallel(true,@() false));
  end
  function availableToolboxHonorsRequest(test)
   test.verifyTrue(resolveH2BiochemParallel(true,@() true));
  end
 end
end

%{
Copyright 2026 H2sim contributors.

This file is part of H2sim.

H2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

H2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with H2sim. If not, see <https://www.gnu.org/licenses/>.
%}
