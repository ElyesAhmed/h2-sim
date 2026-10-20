classdef H2BiochemMixtureTest < matlab.unittest.TestCase
 methods (Test)
  function preservesTabulatedComponentsAndOrdering(test)
   names={'Water','AceticAcid','Hydrogen'}; symbols={'H2O','CH3COOH','H2'};
   mix=h2BiochemCompositionalMixture(names,symbols);
   base=TableCompositionalMixture(names([1,3]),symbols([1,3]));
   test.verifyEqual(mix.names,symbols);
   for name={'Tcrit','Pcrit','Vcrit','acentricFactors','molarMass'}
    test.verifyEqual(mix.(name{1})([1,3]),base.(name{1}));
   end
   test.verifyEqual(mix.molarMass(2),0.060050);
   test.verifyEqual(mix.Vcrit(2),0.060050/276);
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
