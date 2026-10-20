function setup = exampleCompositionalBacterial3DBenchmarkFixedPH(varargin)
% Prepare the h2-store 3D UHS benchmark with MET, ACE and SRB; no simulation.
%
% Uses modelForUHSModifiedBenchmark for grid, rock, wells, boundary pressures
% and the default operating schedule. Reference: Hogeweg et al. (2022),
% doi:10.1007/s10596-022-10163-5; h2-store adaptation: Ahmed et al. (2024),
% doi:10.1016/j.advwatres.2024.104772.
%
% Ten EOS components: the legacy eight plus H2S and acetic acid. Sulfate
% and aqueous sulfide are tracers. The legacy mixed initial composition
% differs from the black-oil source's pure-brine initialization.
% Fixed-pH Soreide-Whitson EOS, without PHREEQC or additional transport terms.
% Default microbial kinetics; AMGCL CPR with the benchmark solver settings.
%
%   setup = exampleCompositionalBacterial3DBenchmarkFixedPH;
%   simulatePackedProblem(setup.problem);
%   [wellSols, states, reports] = getPackedSimulatorOutput(setup.problem);

opt = merge_options(struct('fixedPH', 7.2, 'salinity', 0, ...
    'initialSO4', 0.1, 'deckFile', ''), varargin{:});
mrstModule add ad-core ad-blackoil ad-props deckformat compositional test-suite
gravity reset on
if isempty(opt.deckFile)
    opt.deckFile = fullfile(getDatasetPath('uhs_benchmark', ...
        'askBeforeDownload', false), 'UHS_BENCHMARK_RS.DATA');
end
deck = readEclipseDeck(opt.deckFile);
[description, sourceOptions, stateBo, modelBo, schedule] = ...
    modelForUHSModifiedBenchmark(deck);
base = convertBlackOilModelToCompositionalModel(modelBo);

%% Compositional flow and three microbial populations
fluid = h2BiochemCompositionalMixture( ...
    {'Water', 'Methane', 'Nitrogen', 'CarbonDioxide', 'Ethane', ...
     'Propane', 'n-Butane', 'Hydrogen', 'HydrogenSulfide', 'AceticAcid'}, ...
    {'H2O', 'C1', 'N2', 'CO2', 'C2', 'C3', 'NC4', 'H2', 'H2S', 'CH3COOH'});
biology = TableBioChemMixture( ...
    {'MethanogenicArchae', 'AcetogenicBacteria', 'SulfateReducingBacteria'}, ...
    {'bactM', 'bactA', 'bactS'});
model = BiochemistryModel(modelBo.G, modelBo.rock, base.fluid, ...
    fluid, biology, false, DiagonalAutoDiffBackend('modifyOperators', true), ...
    'oil', true, 'gas', true, 'liquidPhase', 'O', 'vaporPhase', 'G', ...
    'bacteriamodel', true, 'molecularDiffusion', false, ...
    'molecularDispersion', false, 'bactDiffusion', false, 'chemotaxisEffect', false);
model.EOSModel = SoreideWhitsonEos(model.G, fluid, ...
    'msalt', opt.salinity, 'pH', opt.fixedPH, 'initial_NaCl', opt.salinity, ...
    'initial_SO4', opt.initialSO4, 'rho_water', 1000);
model.gravity = modelBo.gravity;
model.outputFluxes = false;
model.OutputStateFunctions{end+1} = 'ComponentPhaseDensity';
% The default dzMaxAbs=0.1 lets a near-wellbore cell's composition jump
% far enough per Newton step to cross the EOS pure-liquid/pure-vapor
% stability boundary (a hard L==0/1 threshold with no hysteresis) and
% back again every iteration, producing a persistent two-cycle in that
% cell's phase flag that drags coupled bacterial equations with it.
% Tightening the per-step composition cap keeps it from overshooting.
model.dzMaxAbs = 0.02;

%% Keep source well geometry and controls; supply compositional inflow data
water = [1, zeros(1, 9)];
hydrogen = zeros(1, 10); hydrogen(8) = 1;
for c = 1:numel(schedule.control)
    well = schedule.control(c).W;
    well.stage = well.name;
    well.name = 'Storage';
    well.compi = [0, 1];
    well.components = hydrogen;
    if ~isfield(well, 'T'), well.T = sourceOptions.initTemp; end
    if strcmpi(well.type, 'rate') && well.val == 0
        well.status = false;
    end
    schedule.control(c).W = well;
    if isfield(schedule.control(c), 'bc') && ~isempty(schedule.control(c).bc)
        bc = schedule.control(c).bc;
        bc.components = repmat(water, numel(bc.face), 1);
        bc.nbact = zeros(numel(bc.face), 3);
        schedule.control(c).bc = bc;
    end
end

%% Initial state and packed setup
composition = [.9023, .07015, .00405, .020210, .00272, .0004, .00015, .00005, 0, 0];
composition = composition/sum(composition);
state0 = initCompositionalStateBacteria(model, stateBo.pressure, ...
    sourceOptions.initTemp, stateBo.s, composition, [55, 55, 55], model.EOSModel);
state0.tracerSO4 = repmat(opt.initialSO4*1000, model.G.cells.num, 1);
state0.tracerHS = zeros(model.G.cells.num, 1);
state0.h2sDissolvedLag = zeros(model.G.cells.num, 1);
model = model.validateModel(schedule.control(schedule.step.control(1)));
state0 = model.validateState(state0);
[solver, linear] = setupOptimizedLinearSolver(model, 'maxNonlinIter', 40);
solver.maxTimestepCuts = 12;
solver.timeStepSelector.maxTimestep = 2*day;
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
directory = fullfile(root, 'build', 'benchmark-3d-fixed-ph-three-reactions');
% Use a name keyed on the run options instead of packH2simSimulationProblem's
% default content hash: the EOS flash during state0/model construction runs
% through OpenMP-accelerated MEX code (useOMP is on by default), whose
% reduction order is not guaranteed bit-reproducible run to run, so the
% hash of the serialized model can differ between two otherwise-identical
% runs and silently restart the simulation from step 1 each time.
runName = sprintf('pH%g_sal%g_so4%g', opt.fixedPH, opt.salinity, opt.initialSO4);
problem = packH2simSimulationProblem(state0, model, schedule, ...
    'H2_3D_BENCHMARK_FIXED_PH_THREE_REACTIONS', ...
    'Directory', directory, 'NonLinearSolver', solver, 'Name', runName);
setup = struct('description', description, 'options', opt, ...
    'sourceOptions', sourceOptions, 'model', model, 'state0', state0, ...
    'schedule', schedule, 'problem', problem, 'solverClass', class(linear));
fprintf('Prepared %d cells and %d schedule steps with %s. No simulation started.\n', ...
    model.G.cells.num, numel(schedule.step.val), class(linear));
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
