%% Cyclic hydrogen storage in a layered 2D aquifer
% Read the h2storage dataset and run the black-oil setup described in Ahmed
% et al. (2024), Advances in Water Resources, 191, 104772. Brine occupies the
% oil phase and hydrogen the gas phase. The default setup includes a cushion
% stage followed by storage cycles. Operating controls, layered rock and
% prescribed lateral pressures are defined by modelForSimple2DAquifer.
%
% The selected external input is H2STORAGE_RS.DATA. The initial reservoir
% pressure and phase fractions are uniform; the boundary-pressure prescription
% is configured separately by the setup helper. A full run may take time.
%
% Plots show surface hydrogen inventory and the dissolved fraction of currently
% stored hydrogen. Cycle-endpoint frames use the corresponding saved states
% and elapsed times. This script expects the default cushion stage for its
% buildup maps. Change case options at the setup call below.
%
% SEE ALSO:
%   modelForSimple2DAquifer, summarizeH2StorageStates, getH2CycleEndpointData

clearvars;
mrstModule add ad-core ad-blackoil ad-props deckformat mrst-gui upr test-suite spe10;

%% Define the case name and read the Eclipse deck file
name = 'H2_STORAGE_RS';

%% Use H2STORAGE_RS_SALT.DATA for brine
dataPath = getDatasetPath('h2storage');
dataFile = fullfile(dataPath, 'H2STORAGE_RS.DATA');
deck = readEclipseDeck(dataFile);

%% Notice on Computational Cost
warning('ComputationalCost:High', ...
    'This example runs a full storage schedule and may take substantial time.');

%% Set up the simulation parameters and model components
[~, ~, state0, model, schedule, ~] = modelForSimple2DAquifer(deck);

%% Plot Grid with Wells, Permeability, and Porosity
figure;
subplot(1, 2, 1);
plotCellData(model.G, model.rock.poro);
hold on;
plotGrid(model.G, schedule.control(1).W.cells, 'LineStyle', 'none', 'FaceColor', 'red');
title('Porosity');
axis off tight;
subplot(1, 2, 2);
plotCellData(model.G, log10(model.rock.perm(:, 1)));
hold on;
plotGrid(model.G, schedule.control(1).W.cells, 'LineStyle', 'none', 'FaceColor', 'red');
title('Permeability (log10)');
axis off tight;
sgtitle('2D Dome-Shaped Aquifer');

%% Add output functions to the model for various properties
model.OutputStateFunctions{end + 1} = 'CapillaryPressure';
model.OutputStateFunctions{end + 1} = 'SurfaceDensity';
model.OutputStateFunctions{end + 1} = 'ShrinkageFactors';
model.outputFluxes = false;

%% Initialize the nonlinear solver and select the linear solver
nls = NonLinearSolver();
lsolve = selectLinearSolverAD(model);
nls.LinearSolver = lsolve;

%% Pack the simulation problem with the defined components
problem = packSimulationProblem(state0, model, schedule, name, ...
    'NonLinearSolver', nls);

%% Execute the simulation of the packed problem
simulatePackedProblem(problem, 'restartStep', 1);

%% Get packed reservoir and well states
[ws, states] = getPackedSimulatorOutput(problem);
%% Plot states
figure;
plotToolbar(model.G, states);

%% Plot well output
figure;
plotWellSols(ws);

%% Get last steps of each injection, production, and idle period
LastSteps = getCyclesLastSteps(schedule);

%% Compute gas volumes for different phases
[totGV_cush, vH2InW_cush, vH2InG_cush] = computeGasVolumes(model, states, LastSteps.cushion);

%% Add plots for H2 volume in Water, Gas, and Total Gas Volumes
figure;
subplot(2, 2, 1);
plotCellData(model.G, states{LastSteps.cushion(1)}.s(:, 2));
title('s_G');
colorbar;
subplot(2, 2, 2);
plotCellData(model.G, vH2InG_cush{1});
title('Surface H2 volume in gas (m^3)');
colorbar;
subplot(2, 2, 3);
plotCellData(model.G, vH2InW_cush{1});
title('Surface dissolved H2 volume (m^3)');
colorbar;
subplot(2, 2, 4);
plotCellData(model.G, totGV_cush{1});
title('Total surface H2 volume (m^3)');
colorbar;
sgtitle('V_{H2} after build-up phase');
%% Dissolved fraction of stored hydrogen at discharge endpoints
timeMonths = convertTo(cumsum(schedule.step.val), 30 * day);
discharge = summarizeH2StorageStates(model, ...
    states(LastSteps.discharge), ws(LastSteps.discharge));
figure;
plot(timeMonths(LastSteps.discharge), discharge.dissolvedFractionPercent, ...
    'LineWidth', 2, 'Color', 'b');
xlabel('Time (months)');
ylabel('Dissolved fraction (%)');
title('Dissolved Fraction of Stored Hydrogen');
grid on;

%% Plot dissolved-hydrogen mass fraction at storage-stage endpoints
endpointData = getH2CycleEndpointData(model, states, schedule);
for k = 1:numel(endpointData.steps)
    plotCellData(model.G, endpointData.massFraction{k}, 'LineStyle', 'none');
    title(sprintf('Dissolved H2 mass fraction at time = %.2f days', ...
        convertTo(endpointData.time(k), day)));
    colorbar;
    pause(0.01);
end
%% Copyright Notice
%
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
