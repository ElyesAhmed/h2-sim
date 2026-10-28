%% Cyclic hydrogen storage in a layered anticlinal dome aquifer
% Read the anticlinal_dome dataset, construct the dome case and run its packed
% black-oil simulation. Brine occupies the oil phase and hydrogen the gas phase.
% Geometry, initial pressure, buildup and storage cycles are configured by
% modelForDome3DAquifer. Change options at that call to vary the case.
%
% The external dataset is located through getDatasetPath('anticlinal_dome').
% This script selects DOME_RSRV.DATA. Model setup, simulation and plotting
% may take substantial time. Applied phase-transfer settings are defined in
% the setup function.
%
% Diagnostics report surface hydrogen inventory, arithmetic cell averages
% and signed surface well rates. The dissolved fraction is a fraction of
% currently stored hydrogen, not cumulative loss or recovery efficiency.
%
% Reference: Ahmed et al. (2024), Phase behavior and black-oil simulations of
% hydrogen storage in saline aquifers. Advances in Water Resources, 191, 104772.
%
% SEE ALSO:
%   modelForDome3DAquifer, summarizeH2StorageStates

mrstModule add ad-core ad-blackoil ad-props deckformat mrst-gui vemmech test-suite 
%% Notice on Computational Cost
warning('ComputationalCost:High', ...
    'This example runs a full storage schedule and may take substantial time.');

name = 'H2_Storage';

dataPath = getDatasetPath('anticlinal_dome');
dataFile = fullfile(dataPath, 'DOME_RSRV.DATA');
deck = readEclipseDeck(dataFile);
%% Initialize the dome case simulation with specified parameters
[~, ~, state0, model, schedule] = modelForDome3DAquifer(deck);

%% Plot rock parameters
figure;
% porosity
subplot(1, 2, 1);
plotCellData(model.G, model.rock.poro, model.G.cells.centroids(:,2) > 2500, 'LineStyle', 'none');
colorbar;
title('Porosity Distribution');
xlabel('X [m]');
ylabel('Y [m]');
view(3);
% permeability
subplot(1, 2, 2);
plotCellData(model.G, log10(model.rock.perm(:,1)), model.G.cells.centroids(:,2) > 2500, 'LineStyle', 'none');
colorbar;
title('log10(k_x / m^2)');
xlabel('X [m]');
ylabel('Y [m]');
view(3);
sgtitle('Porosity and Permeability Distribution in the Dome Aquifer');

%% Add custom output functions to the model for analysis
model.OutputStateFunctions{end + 1} = 'CapillaryPressure';
model.OutputStateFunctions{end + 1} = 'SurfaceDensity';
model.OutputStateFunctions{end + 1} = 'ShrinkageFactors';
model.outputFluxes = false;

%% Setup the non-linear solver and select the linear solver
nls = NonLinearSolver();
lsolve = selectLinearSolverAD(model);
nls.LinearSolver = lsolve;

%% Pack the simulation problem for execution
problem = packSimulationProblem(state0, model, schedule, name, ...
    'NonLinearSolver', nls);

%% Run the simulation
simulatePackedProblem(problem, 'restartStep', 1);
%% Retrieve reservoir and well states
[ws, states] = getPackedSimulatorOutput(problem);
%% Plot well states
plotWellSols(ws);
%%
figure;
plotToolbar(model.G, states);
title(name);
%% Summarize surface hydrogen inventory and well histories
diagnostics = summarizeH2StorageStates(model, states, ws);

%% Plotting results over time (in months)
timeMonths = convertTo(cumsum(schedule.step.val), 30*day);

figure;
subplot(4, 1, 1);
plot(timeMonths, diagnostics.meanGasSaturation, 'LineWidth', 1.5);
ylabel('Average Saturation');
title('Average Saturation Over Time');

subplot(4, 1, 2);
plot(timeMonths, diagnostics.meanPressure, 'LineWidth', 1.5);
ylabel('Average Pressure (Pa)');
title('Average Pressure Over Time');

subplot(4, 1, 3);
plot(timeMonths, diagnostics.totalHydrogenVolume, 'LineWidth', 1.5);
ylabel('Surface H2 volume (m^3)');
title('Stored Hydrogen');

subplot(4, 1, 4);
plot(timeMonths, diagnostics.dissolvedHydrogenVolume, 'LineWidth', 1.5);
ylabel('Surface H2 volume (m^3)');
title('Dissolved H2 Volume Over Time');
xlabel('Time (months)');

figure;
subplot(4, 1, 1);
plot(timeMonths, diagnostics.bhp, 'LineWidth', 1.5);
ylabel('BHP (Pa)');
title('Bottom Hole Pressure Over Time');

subplot(4, 1, 2);
plot(timeMonths, diagnostics.gasRate, 'LineWidth', 1.5);
ylabel('Gas rate (m^3/s)');
title('Gas Rate Over Time');

subplot(4, 1, 3);
plot(timeMonths, diagnostics.brineRate, 'LineWidth', 1.5);
ylabel('Brine rate (m^3/s)');
title('Water Rate Over Time');

subplot(4, 1, 4);
plot(timeMonths, diagnostics.dissolvedFractionPercent, 'LineWidth', 1.5);
ylabel('Dissolved fraction (%)');
title('Dissolved Fraction of Stored Hydrogen');
xlabel('Time (months)');
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
