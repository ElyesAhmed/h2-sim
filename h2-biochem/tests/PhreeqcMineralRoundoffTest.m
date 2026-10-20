classdef PhreeqcMineralRoundoffTest < matlab.unittest.TestCase
 methods (Test)
  function observedFieldResidual(test)
   r = test.reservoirs(); w = 7.897830326919321;
   r.anhydrite = -2.8732139351338704e-11;
   [s,c,m,n] = normalizePhreeqcMineralRoundoff(r,w,1e-7);
   test.verifyEqual(s.anhydrite,0);
   test.verifyEqual(c,[0,0,-r.anhydrite,-r.anhydrite,0,0],'AbsTol',1e-25);
   test.verifyEqual(m(strcmp(n,'anhydrite')),-r.anhydrite);
   test.verifyEqual(computePhreeqcElementInventory(s),zeros(1,6));
  end
  function rejectsMaterialNegative(test)
   r = test.reservoirs(); r.anhydrite = -1e-7;
   test.verifyError(@() normalizePhreeqcMineralRoundoff(r,8,1e-7), ...
       'H2Biochem:InvalidPhreeqcMineral');
  end
  function respectsStricterAudit(test)
   r = test.reservoirs(); r.anhydrite = -2.8732139351338704e-11;
   test.verifyError(@() normalizePhreeqcMineralRoundoff(r,8,1e-12), ...
       'H2Biochem:InvalidPhreeqcMineral');
  end
  function rejectsNonfiniteMineral(test)
   r = test.reservoirs(); r.calcite = NaN;
   test.verifyError(@() normalizePhreeqcMineralRoundoff(r,8,1e-7), ...
       'H2Biochem:InvalidPhreeqcMineral');
  end
  function hydratedPhaseCorrection(test)
   r = test.reservoirs(); r.gypsum = -1e-12;
   [s,c] = normalizePhreeqcMineralRoundoff(r,8,1e-7);
   test.verifyEqual(s.gypsum,0);
   test.verifyEqual(c,[4,0,1,1,0,0]*1e-12,'AbsTol',1e-25);
  end
  function boundsSummedElementCorrection(test)
   r = test.reservoirs(); r.calcite = -6e-11; r.dolomite = -6e-11;
   test.verifyError(@() normalizePhreeqcMineralRoundoff(r,1,1e-7), ...
       'H2Biochem:InvalidPhreeqcMineral');
  end
  function positiveInventoriesUnchanged(test)
   r = test.reservoirs(); r.calcite = 2; r.dolomite = 3;
   [s,c] = normalizePhreeqcMineralRoundoff(r,8,1e-7);
   test.verifyEqual(s,r); test.verifyEqual(c,zeros(1,6));
  end
 end
 methods (Static)
  function r = reservoirs()
   fields = {'hydrogen','c4','acetate','s6','s2','ca','mg','fe2','fe3', ...
       'gasH2','gasCO2','gasCH4','gasH2S','calcite','dolomite', ...
       'anhydrite','gypsum','goethite','pyrite','brucite','portlandite'};
   r = cell2struct(num2cell(zeros(numel(fields),1)),fields,1);
  end
 end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).

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
