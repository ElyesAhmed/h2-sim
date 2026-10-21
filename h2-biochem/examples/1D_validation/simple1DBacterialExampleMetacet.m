%% Closed-system microbial reactions in a 1D compositional model
% Initialize this checkout with startupH2sim, then run this script. Compare
% methanogenesis and acetogenesis with dynamic rock properties, with fixed
% rock properties, and without microbial reactions. PHREEQC is not used.
%
% The initial pressure is 82 bar, temperature is 313.15 K, and the component
% order is H2O, H2, CH4, CO2, acetate. Both wells are closed. The 400-step
% schedule is inherited from MRST's simplecomp dataset and shortened by a
% factor of three. This example requires that dataset and mrst-gui for the
% final interactive viewer; the other comparison figures are static plots.
%
% This is a script: model, state0, schedule, prob1/prob2/prob3, ws1/ws2/ws3
% and st1/st2/st3 remain in the caller workspace for inspection. The linked
% notebook is generated from this source without executing the simulation.
% Related model publication:
% https://www.sciencedirect.com/science/article/pii/S0360319925039473

mrstModule add ad-core ad-props deckformat mrst-gui
mrstModule add compositional
mrstVerbose off;

%% Prepare the grid, fluid and schedule
% Increase boundary-cell porosity to mimic well-adjacent storage. Retain
% the original gas/liquid reference densities in kg/m^3.
[~, model, schedule, ~] = setupSimpleCompositionalExample(false);
model.rock.poro([1, end]) = 0.90;
model.fluid.rhoGS = 0.08988;
model.fluid.rhoOS = 999.0140;
schedule.step.val = schedule.step.val/3;
schedule.step.val = schedule.step.val(1:400);
schedule.step.control = schedule.step.control(1:400);

%% Set residual saturations and relative permeability
swc = 0.20;
sor = 0.20;
sgr = 0.10;
swmax = 0.90;
sgmax = 0.80;
model.fluid = modifyRelPermForResidualSaturations( ...
    model.fluid, swc, swmax, sgr, sor, sgmax);

%% Define the initial mixture and microbial populations
% The composition follows H2O, H2, CH4, CO2, acetate and sums to one.
initComp = [0.90, 0.045, 0.005, 0.05, 0.0];
initTemp = 273.15 + 40;
initPress = 82*barsa;
biochemFluid = TableBioChemMixture( ...
    {'MethanogenicArchae', 'AcetogenicBacteria'}, {'nbactM', 'nbactA'});
nbioreact = biochemFluid.nbioreact;
initBact = ones(1, nbioreact)*9;
nc = ones(1, nbioreact)*180;
cp = zeros(1, nbioreact);

%% Configure the inherited bio-clogging formulation
% Keep the original coefficients. In setupBioCloggingModel2bacts, cp=0
% leaves scale=1 and does not disable porosity/permeability changes. The
% fixed-rock comparison below explicitly restores poro0 and perm0.
if nbioreact == 1
    [model, poro0, perm0] = setupBioCloggingModel( ...
        model, initBact(1), nc(1), cp(1));
else
    [model, poro0, perm0] = setupBioCloggingModel2bacts(model, initBact, nc, cp);
end

%% Construct the biochemical compositional model
% BiochemistryModel constructs its own Soreide-Whitson EOS. Its default
% msalt=0 is the effective setting retained from the original simulation;
% assigning a different EOS to the precursor model would be overwritten.
compFluid = h2BiochemCompositionalMixture( ...
    {'Water', 'Hydrogen', 'Methane', 'CarbonDioxide', 'AceticAcid'}, ...
    {'H2O', 'H2', 'C1', 'CO2', 'CH3COOH'});
backend = DiagonalAutoDiffBackend('modifyOperators', true);
model = BiochemistryModel(model.G, model.rock, model.fluid, compFluid, ...
    biochemFluid, true, backend, 'water', false, 'oil', true, 'gas', true, ...
    'bacteriamodel', true, 'moleculardiffusion', true, ...
    'liquidPhase', 'O', 'vaporPhase', 'G');

%% Close both wells and initialize the state
% Retain valid placeholder well compositions even though rates are zero
% and status is false. This is not an injection/production comparison.
schedule.control.W(1).components = [0.001, 0.948, 0.001, 0.05, 0.0];
schedule.control.W(2).components = [0.001, 0.948, 0.001, 0.05, 0.0];
schedule.control.W(1).type = 'rate';
schedule.control.W(1).val = 0;
schedule.control.W(2).type = 'rate';
schedule.control.W(2).val = 0;
[schedule.control.W.status] = deal(false);
state0 = initCompositionalStateBacteria(model, initPress, initTemp, [0, 1], ...
    initComp, initBact, model.EOSModel);
% Keep the original strict well-composition check alongside shared validation.
assert(all(arrayfun(@(w) abs(sum(w.components) - 1) < 1e-12, schedule.control.W)));
validateH2simSimulationInputs(state0, model, schedule);

%% Run the dynamic-rock microbial case
prob1 = packSimulationProblem(state0, model, schedule, 'bio_cloggingMA');
prob1.SimulatorSetup.model.OutputStateFunctions{end} = 'ComponentPhaseMass';
simulatePackedProblem(prob1);
[ws1, st1] = getPackedSimulatorOutput(prob1);

%% Run the fixed-rock microbial case
model2 = model;
model2.rock.perm = perm0;
model2.rock.poro = poro0;
model2.fluid.pvMultR = @(p, varargin) ones(size(p));
prob2 = packSimulationProblem(state0, model2, schedule, 'bio_no_clogMA');
prob2.SimulatorSetup.model.OutputStateFunctions{end} = 'ComponentPhaseMass';
simulatePackedProblem(prob2);
[ws2, st2] = getPackedSimulatorOutput(prob2);

%% Run the abiotic case with the same initial state
model3 = model2;
model3.bacteriamodel = false;
state3 = state0;
prob3 = packSimulationProblem(state3, model3, schedule, 'no_bacteriaMA');
prob3.SimulatorSetup.model.OutputStateFunctions{end} = 'ComponentPhaseMass';
simulatePackedProblem(prob3);
[ws3, st3] = getPackedSimulatorOutput(prob3);

%% Prepare the scenario comparison
compNames = model.EOSModel.getComponentNames();
idxH2 = find(strcmp(compNames, 'H2'));
idxCO2 = find(strcmp(compNames, 'CO2'));
idxCH4 = find(strcmp(compNames, 'C1'));
timeDays = cumsum(schedule.step.val)/day;
timeYrs = timeDays/365;
scenarios = {
    struct('name', 'Bio-Clog', 'model', model, 'states', {st1}, ...
           'color', [0, 0.5, 0], 'line', '-'), ...
    struct('name', 'Bio-NoClog', 'model', model2, 'states', {st2}, ...
           'color', [0, 0.7, 0.7], 'line', '--'), ...
    struct('name', 'Abiotic', 'model', model3, 'states', {st3}, ...
           'color', [0.7, 0, 0], 'line', ':')};

%% Plot the physical results
plotComponentProfiles(scenarios, compNames, timeYrs);
plotBacterialEffects(scenarios, timeYrs, poro0, perm0);
plotPressureAndSaturation(scenarios, timeYrs);
plotComponentComparison(scenarios, timeYrs, idxH2, idxCO2, idxCH4);

%% Open the interactive pressure viewer
% This final viewer is intended for a MATLAB desktop session.
plotToolbar(model.G, st1, 'plot1d', true, 'field', 'pressure');
title('Bio-Clogging Scenario - Pressure');

%% Copyright notice

% <html>
% <p><font size="-1">
% Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.
% </font></p>
% <p><font size="-1">
% This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).
% </font></p>
% <p><font size="-1">
% MRST is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% </font></p>
% <p><font size="-1">
% MRST is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% </font></p>
% <p><font size="-1">
% You should have received a copy of the GNU General Public License
% along with MRST.  If not, see
% <a href="http://www.gnu.org/licenses/">http://www.gnu.org/licenses</a>.
% </font></p>
% </html>

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
