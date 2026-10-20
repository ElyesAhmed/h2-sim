function results=exampleCompositionalBacterial2DThreeReactions(varargin)
%% 2D Compositional Hydrogen Storage with Three Reactions (MET, ACE, SRB)
% =========================================================================
% This example simulates hydrogen storage in a 2D structural trap with residual methane.
% It includes three microbial reactions:
%   - Methanogenesis (MET):  4 H2 + CO2  -> CH4 + 2 H2O
%   - Acetogenesis (ACE):    4 H2 + 2 CO2 -> CH3COOH + 2 H2O
%   - Sulfate Reduction (SRB): 4 H2 + SO4^2- + 2 H+ -> H2S + 4 H2O
%
% All kinetic parameters are taken from the default database
% (bioChemFluidsStructs.m) – no overrides.
%
% Sulfate (SO4) and bisulfide (HS) are treated as aqueous tracers.
% H2S is a volatile EOS component.
%
% Scenarios:
%   1) With bacteria and bio-clogging
%   2) With bacteria but without clogging
%   3) Abiotic (no bacteria)
%
% References:
%   - Original 2D case: Ahmed et al., 2024
%   - Three‑reaction model: Shojaee et al., 2025 (compositional PHREEQC)
% =========================================================================


% Run this existing case with five cycles, preserving the original 0.5 m grid.
% Defaults retain the three original scenarios and optional transport terms.
% Select scenarios={'bacterial','abiotic'} and disable molecular transport for
% the website comparison. All setups and accepted outputs are packed on disk.
opt=merge_options(struct('numCycles',5,'gridSpacing',[0.5,0.5], ...
 'scenarios',{{'clogging','bacterial','abiotic'}}, ...
 'molecularDiffusion',true,'molecularDispersion',true, ...
 'maximumFlowSteps',inf,'plotResults',true,'deckFile','', ...
 'outputDirectory',fullfile(pwd,'build','compositional-2d-three-reactions')),varargin{:});
validateattributes(opt.numCycles,{'numeric'},{'scalar','integer','positive'});
validateattributes(opt.maximumFlowSteps,{'numeric'},{'scalar','positive'});
mrstModule add ad-core ad-blackoil ad-props deckformat upr test-suite spe10 compositional
if isempty(opt.deckFile)
 root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
 opt.deckFile=fullfile(root,'h2-store','examples','data','Aquifer2D','H2STORAGE_RS.DATA');
end
deck=readEclipseDeck(opt.deckFile);
[description,setup,state0Bo,modelBo,schedule]=modelForSimple2DAquifer(deck, ...
 'numCycles',opt.numCycles,'gridSpacing',opt.gridSpacing);
compFluid=h2BiochemCompositionalMixture( ...
 {'Water','Hydrogen','CarbonDioxide','Methane','HydrogenSulfide','AceticAcid'}, ...
 {'H2O','H2','CO2','C1','H2S','CH3COOH'});
biochemFluid=TableBioChemMixture( ...
 {'MethanogenicArchae','AcetogenicBacteria','SulfateReducingBacteria'}, ...
 {'bactM','bactA','bactS'});
initialSO4=0.1;T0=273.15+44.35;nbact0=[15,15,15];
comp0=[0.8480,1e-5,1e-5,0.1530,0,0];comp0=comp0/sum(comp0);
for k=1:numel(schedule.control)
 W=schedule.control(k).W;
 W.stage=W.name;W.name='Storage';W.compi=[0,1];
 if strcmp(W.stage,'cushion') && k<11
  W.components=[0,.1,.9,0,0,0];
 else
  W.components=[0,.95,.05,0,0,0];
 end
 W.T=T0;
 if strcmp(W.stage,'discharge'),W.lims.bhp=35*barsa;end
 schedule.control(k).W=W;schedule.control(k).bc=[];
end
if ~isfolder(opt.outputDirectory),mkdir(opt.outputDirectory);end
caseResults=cell(1,numel(opt.scenarios));
for j=1:numel(opt.scenarios)
 scenario=validatestring(opt.scenarios{j},{'clogging','bacterial','abiotic'});
 backend=DiagonalAutoDiffBackend('modifyOperators',true);
 model=BiochemistryModel(modelBo.G,modelBo.rock,modelBo.fluid,compFluid, ...
  biochemFluid,false,backend,'oil',true,'gas',true, ...
  'bacteriamodel',~strcmp(scenario,'abiotic'),'bactDiffusion',false, ...
  'chemotaxisEffect',false,'molecularDiffusion',opt.molecularDiffusion, ...
  'molecularDispersion',opt.molecularDispersion,'liquidPhase','O','vaporPhase','G');
 model.EOSModel=SoreideWhitsonEos(model.G,compFluid,'msalt',0,'pH',7.2, ...
  'initial_NaCl',0,'initial_SO4',initialSO4,'rho_water',1000);
 model.gravity=modelBo.gravity;model.outputFluxes=false;
 model=setupBioCloggingModel(model,nbact0,[120,120,120],[1,1,1],strcmp(scenario,'clogging'));
 model.OutputStateFunctions{end+1}='ComponentPhaseDensity';
 if model.bacteriamodel
  state0=initCompositionalStateBacteria(model,state0Bo.pressure,T0,state0Bo.s,comp0,nbact0,model.EOSModel);
 else
  state0=initCompositionalState(model,state0Bo.pressure,T0,state0Bo.s,comp0,model.EOSModel);
 end
 state0.tracerSO4=repmat(initialSO4*1000,model.G.cells.num,1);
 state0.tracerHS=zeros(model.G.cells.num,1);state0.h2sDissolvedLag=zeros(model.G.cells.num,1);
 state0.wellSol=initWellSolAD(schedule.control(1).W,model,state0);
 state0.wellSol.bhp=max(state0.pressure(schedule.control(1).W.cells))+5*barsa;
 [solver,~]=setupOptimizedLinearSolver(model,'complexityLevel','low', ...
  'solverTolerance',1e-4,'maxNonlinIter',20);
 solver.maxTimestepCuts=12;
 problem=packH2simSimulationProblem(state0,model,schedule, ...
  ['H2_COMPOSITIONAL_2D_THREE_REACTIONS_',upper(scenario)],'NonLinearSolver',solver);
 % A setup check writes a valid prefix into the full packed case, allowing
 % the full run to resume without changing its setup or cache identity.
 resultFile=fullfile(opt.outputDirectory,[scenario,'_results.mat']);
 if isfile(resultFile) && isinf(opt.maximumFlowSteps)
  saved=loadH2simResults(resultFile,'result');
  if saved.result.complete && strcmp(saved.result.packedProblem.Name,problem.Name) ...
    && problem.OutputHandlers.reports.numelData()==numel(schedule.step.val)
   caseResults{j}=saved.result;
   fprintf('REUSED %s: %d saved physical states.\n',scenario,numel(saved.result.states));
   continue
  end
  clear saved
 end
 runProblem=problem;limit=min(numel(schedule.step.val),opt.maximumFlowSteps);
 if limit<numel(schedule.step.val)
  runProblem.SimulatorSetup.schedule.step.val=schedule.step.val(1:limit);
  runProblem.SimulatorSetup.schedule.step.control=schedule.step.control(1:limit);
 end
 timer=tic;ok=simulatePackedProblem(runProblem,'continueOnError',false);assert(ok,'Case failed: %s',scenario);
 [ws,states,reports]=getH2simPackedPhysicalOutput(runProblem);
 result=struct('name',scenario,'description',description,'setup',setup, ...
  'model',model,'state0',state0,'schedule',runProblem.SimulatorSetup.schedule, ...
  'states',{states},'wellSols',{ws},'reports',{reports}, ...
  'packedProblem',problem,'elapsedSeconds',toc(timer),'complete',limit==numel(schedule.step.val));
 caseResults{j}=result;
 file=[tempname,'.mat'];save(file,'result','-v7.3');
 copyfile(file,fullfile(opt.outputDirectory,[scenario,'_results.mat']),'f');delete(file);
 fprintf('SAVED %s: %d cells, %d steps, %.1f seconds.\n',scenario,model.G.cells.num,numel(states),result.elapsedSeconds);
end
results=[caseResults{:}];
if opt.plotResults && all([results.complete])
 plotCompositionalBacterial2DThreeReactions(results,'outputDirectory',opt.outputDirectory);
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
