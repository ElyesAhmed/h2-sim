classdef H2simPackedSimulationTest < matlab.unittest.TestCase
 methods (Test)
  function savedSetupDistinguishesChangedInputs(test)
   mrstModule add ad-core ad-props ad-blackoil
   G=computeGeometry(cartGrid([2,1,1],[2,1,1]));
   rock=makeRock(G,100*milli*darcy,0.2);
   fluid=initSimpleADIFluid('phases','OG','rho',[1000,1]);
   model=GenericBlackOilModel(G,rock,fluid,'water',false,'disgas',false,'vapoil',false);
   state=initResSol(G,1e7,[1,0]);schedule=simpleSchedule(day);
   folder=tempname;mkdir(folder);cleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
   first=packH2simSimulationProblem(state,model,schedule,'CACHE_TEST','Directory',folder);
   again=packH2simSimulationProblem(state,model,schedule,'CACHE_TEST','Directory',folder);
   test.verifyEqual(first.Name,again.Name);
   changed=state;changed.pressure(2)=changed.pressure(2)+1;
   second=packH2simSimulationProblem(changed,model,schedule,'CACHE_TEST','Directory',folder);
   test.verifyNotEqual(first.Name,second.Name);
   loaded=load(fullfile(first.OutputHandlers.states.getDataPath(),'packed_setup.mat'),'problem');
   test.verifyEqual(loaded.problem.SimulatorSetup.state0.pressure,state.pressure);
   test.verifyEqual(loaded.problem.SimulatorSetup.schedule.step.val,schedule.step.val);
   loaded=load(fullfile(second.OutputHandlers.states.getDataPath(),'packed_setup.mat'),'problem');
   test.verifyEqual(loaded.problem.SimulatorSetup.state0.pressure,changed.pressure);
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
