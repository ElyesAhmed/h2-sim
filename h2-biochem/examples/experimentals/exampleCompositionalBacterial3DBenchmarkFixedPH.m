function setup=exampleCompositionalBacterial3DBenchmarkFixedPH(varargin)
% Prepare ONE three-population 3D h2-store benchmark case; do not simulate.
%
% Uses the existing modelForUHSModifiedBenchmark in this H2Sim checkout:
% full benchmark grid, rock, relative permeability/capillary curves,
% completion geometry, well controls and pressure boundaries are retained.
% This is the h2-store adaptation of Hogeweg, Strobel & Hagemann (2022),
% doi:10.1007/s10596-022-10163-5, with the black-oil setup described by
% Ahmed et al. (2024), doi:10.1016/j.advwatres.2024.104772.
%
% Three populations: methanogens, acetogens, sulfate reducers (MET/ACE/SRB).
% Soreide-Whitson EOS with fixed pH input; no external geochemical coupling.
% Molecular diffusion, dispersion, bacterial diffusion, chemotaxis and
% bio-clogging are disabled. No pH evolution or pH-dependent Monod factor
% is added; the fixed pH enters the EOS sulfide-partitioning closure.
%
% The supplied legacy eight-component initial mixture is retained and
% normalized. H2S and acetic acid are appended at zero initial abundance;
% sulfate and aqueous sulfide use the existing nonvolatile tracer model.
% This mixed initialization differs from the black-oil source's pure-brine
% initial state and is an adaptation, not an exact benchmark reproduction.
%
% Component order: H2O C1 N2 CO2 C2 C3 NC4 H2 H2S CH3COOH.
% Initial populations default to [55,55,55]; initial sulfate is 0.1 mol/kgw.
% Default kinetic parameters come from TableBioChemMixture.
%
% PREPARE ONLY (creates packed setup, no accepted flow states):
%   setup=exampleCompositionalBacterial3DBenchmarkFixedPH;
%   setup=exampleCompositionalBacterial3DBenchmarkFixedPH('numCycles',2);
%
% RUN LATER, explicitly and separately:
%   simulatePackedProblem(setup.problem,'continueOnError',false);
%   [wellSols,states,reports]=getPackedSimulatorOutput(setup.problem);
%
% Keep reaction consumption separate from well recovery and boundary
% exchange when post-processing hydrogen loss.

root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
opt=merge_options(struct('numCycles',4,'fixedPH',7.2,'salinity',0, ...
 'initialSO4',0.1,'waterDensity',1000,'initialPopulation',[55,55,55], ...
 'initialComposition',[.9023,.07015,.00405,.020210,.00272,.0004,.00015,.00005,0,0], ...
 'deckFile','','linearThreads',4, ...
 'outputDirectory',fullfile(root,'build','benchmark-3d-fixed-ph-three-reactions')),varargin{:});
validateattributes(opt.numCycles,{'numeric'},{'scalar','integer','positive'});
validateattributes(opt.fixedPH,{'numeric'},{'scalar','real','finite','>=',0,'<=',14});
validateattributes(opt.salinity,{'numeric'},{'scalar','real','finite','nonnegative'});
validateattributes(opt.initialSO4,{'numeric'},{'scalar','real','finite','nonnegative'});
validateattributes(opt.waterDensity,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(opt.linearThreads,{'numeric'},{'scalar','integer','positive'});
validateattributes(opt.initialPopulation,{'numeric'},{'row','numel',3,'real','finite','positive'});
validateattributes(opt.initialComposition,{'numeric'},{'row','real','finite','nonnegative'});
if numel(opt.initialComposition)==8,opt.initialComposition=[opt.initialComposition,0,0];end
assert(numel(opt.initialComposition)==10 && sum(opt.initialComposition)>0);
z0=opt.initialComposition/sum(opt.initialComposition);
mrstModule add ad-core ad-blackoil ad-props deckformat compositional test-suite
if isempty(opt.deckFile)
 opt.deckFile=fullfile(getDatasetPath('uhs_benchmark','askBeforeDownload',false),'UHS_BENCHMARK_RS.DATA');
end
assert(isfile(opt.deckFile),'h2sim:MissingBenchmarkDeck', ...
 'UHS benchmark deck not found: %s. Set deckFile to the local h2-store dataset.',opt.deckFile);
sourceFunction=which('modelForUHSModifiedBenchmark');
expected=fullfile(root,'h2-store','utils','modelForUHSModifiedBenchmark.m');
assert(strcmpi(strrep(sourceFunction,'\','/'),strrep(expected,'\','/')), ...
 'Use modelForUHSModifiedBenchmark from this H2Sim checkout.');
gravity reset on
deck=readEclipseDeck(opt.deckFile);
[description,sourceOptions,stateBo,modelBo,sourceSchedule]= ...
 modelForUHSModifiedBenchmark(deck,'numCycles',opt.numCycles);
assert(modelBo.G.griddim==3,'Keep the existing 3D benchmark grid.');
base=convertBlackOilModelToCompositionalModel(modelBo);
fluid=h2BiochemCompositionalMixture( ...
 {'Water','Methane','Nitrogen','CarbonDioxide','Ethane','Propane','n-Butane','Hydrogen','HydrogenSulfide','AceticAcid'}, ...
 {'H2O','C1','N2','CO2','C2','C3','NC4','H2','H2S','CH3COOH'});
biology=TableBioChemMixture( ...
 {'MethanogenicArchae','AcetogenicBacteria','SulfateReducingBacteria'}, ...
 {'bactM','bactA','bactS'});
model=BiochemistryModel(modelBo.G,modelBo.rock,base.fluid,fluid,biology,false, ...
 DiagonalAutoDiffBackend('modifyOperators',true),'oil',true,'gas',true, ...
 'liquidPhase','O','vaporPhase','G','bacteriamodel',true, ...
 'molecularDiffusion',false,'molecularDispersion',false, ...
 'bactDiffusion',false,'chemotaxisEffect',false);
model.EOSModel=SoreideWhitsonEos(model.G,fluid,'msalt',opt.salinity, ...
 'pH',opt.fixedPH,'initial_NaCl',opt.salinity, ...
 'initial_SO4',opt.initialSO4,'rho_water',opt.waterDensity);
model.gravity=modelBo.gravity;model.outputFluxes=false;
model.OutputStateFunctions{end+1}='ComponentPhaseDensity';

%% Adapt compositions and audit every inherited well control.
waterComposition=[1,zeros(1,9)];injectionComposition=zeros(1,10);injectionComposition(8)=1;
schedule=sourceSchedule;wellAudit=struct([]);
for c=1:numel(schedule.control)
 wells=schedule.control(c).W;
 assert(numel(wells)==1,'This benchmark expects one physical storage well.');
 original=wells;
 wells.stage=wells.name;wells.name='Storage'; % Same well across all stages.
 wells.compi=[0,1];wells.components=injectionComposition;
 % Explicit gas-mixture temperature; hydraulic targets remain unchanged.
 if ~isfield(wells,'T'),wells.T=sourceOptions.initTemp;end
 if strcmpi(wells.type,'rate') && wells.val==0
  wells.status=false;wells.sign=0;
 end
 assert(isequal(wells.cells,original.cells) && isequal(wells.WI,original.WI));
 assert(isequal(wells.r,original.r) && isequal(wells.cstatus,original.cstatus));
 assert(strcmp(wells.type,original.type) && wells.val==original.val);
 if isfield(original,'lims'),assert(isequaln(wells.lims,original.lims));end
 cells=wells.cells(:);
 assert(all(cells>=1 & cells<=model.G.cells.num) && numel(unique(cells))==numel(cells));
 assert(all(isfinite(wells.r) & wells.r>0) && all(isfinite(wells.WI) & wells.WI>0));
 assert(numel(wells.cstatus)==numel(cells) && any(wells.cstatus));
 assert(all(isfinite(wells.components)) && all(wells.components>=0) && abs(sum(wells.components)-1)<1e-12);
 assert(isequal(wells.compi,[0,1]) && isfinite(wells.T) && wells.T>0);
 if wells.status
  if strcmpi(wells.type,'rate'),assert(sign(wells.val)==wells.sign);end
  if strcmpi(wells.type,'bhp'),assert(wells.val>0 && ismember(wells.sign,[-1,1]));end
 end
 % In particular, retain h2-store's production cstatus mask and BHP limit;
 % do not silently reopen source-disabled completion intervals.
 schedule.control(c).W=wells;
 if isfield(schedule.control(c),'bc') && ~isempty(schedule.control(c).bc)
  bc=schedule.control(c).bc;
  bc.components=repmat(waterComposition,numel(bc.face),1);
  bc.nbact=zeros(numel(bc.face),3);
  schedule.control(c).bc=bc;
 end
 wellAudit(c)=struct('stage',wells.stage,'type',wells.type,'targetSI',wells.val, ...
  'sign',wells.sign,'active',logical(wells.status),'completionCells',cells, ...
  'activeCompletionCount',nnz(wells.cstatus),'geometryAndLimitsPreserved',true); %#ok<AGROW>
end
assert(isequal(schedule.step,sourceSchedule.step),'Do not change the inherited operating schedule.');

%% Initial flash and three-population state; still no flow timesteps.
state0=initCompositionalStateBacteria(model,stateBo.pressure,sourceOptions.initTemp, ...
 stateBo.s,z0,opt.initialPopulation,model.EOSModel);
state0.tracerSO4=repmat(opt.initialSO4*opt.waterDensity,model.G.cells.num,1);
state0.tracerHS=zeros(model.G.cells.num,1);state0.h2sDissolvedLag=zeros(model.G.cells.num,1);
model=model.validateModel();state0=model.validateState(state0);
state0.wellSol=initWellSolAD(schedule.control(schedule.step.control(1)).W,model,state0);
[solver,linear]=setupOptimizedLinearSolver(model,'complexityLevel','medium', ...
 'solverTolerance',1e-4,'maxNonlinIter',12,'linearThreads',opt.linearThreads);
solver.maxTimestepCuts=12;solver.timeStepSelector.maxTimestep=5*day;
assert(~isa(model,'BiochemistryPhreeqcModel') && model.EOSModel.pH==opt.fixedPH);
assert(model.sulfateReduction && model.biochemFluid.nbioreact==3);
assert(~model.molecularDiffusion && ~model.molecularDispersion && ~model.bactDiffusion && ~model.chemotaxisEffect);
assert(all(isfinite(state0.pressure)) && all(state0.pressure>0));
assert(all(isfinite(state0.s),'all') && min(state0.s,[],'all')>=-1e-8);
assert(max(abs(sum(state0.components,2)-1))<1e-12 && max(abs(sum(state0.s,2)-1))<1e-8);
assert(isequal(size(state0.nbact),[model.G.cells.num,3]));
if ~isfolder(opt.outputDirectory),mkdir(opt.outputDirectory);end
problem=packH2simSimulationProblem(state0,model,schedule, ...
 'H2_3D_BENCHMARK_FIXED_PH_THREE_REACTIONS','Directory',opt.outputDirectory,'NonLinearSolver',solver);
setup=struct('description',description,'options',opt,'sourceOptions',sourceOptions, ...
 'sourceSetupFunction',sourceFunction,'componentNames',{fluid.names}, ...
 'initialComposition',z0,'model',model,'state0',state0,'schedule',schedule, ...
 'problem',problem,'wellAudit',wellAudit,'solverClass',class(linear), ...
 'packedSetupFile',fullfile(problem.OutputHandlers.states.getDataPath(),'packed_setup.mat'), ...
 'simulationStarted',false);
file=fullfile(opt.outputDirectory,'benchmark_setup.mat');tmp=[tempname,'.mat'];
cleanup=onCleanup(@() delete(tmp));save(tmp,'setup','-v7.3');copyfile(tmp,file,'f');
fprintf('PREPARED: %d cells, %d steps, %.3f days; MET/ACE/SRB; fixed pH %.2f; %s.\n', ...
 model.G.cells.num,numel(schedule.step.val),sum(schedule.step.val)/day,opt.fixedPH,class(linear));
fprintf('Well geometry, radii, indices, signs, compositions and production limits checked.\n');
fprintf('Setup saved: %s\nNo reservoir simulation started.\n',file);
end
