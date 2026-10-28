%% Cyclic hydrogen storage in the modified benchmark aquifer
% Read the uhs_benchmark dataset, construct the black-oil case and run its
% packed simulation. Brine occupies the oil phase and hydrogen the gas phase.
% Buildup and storage-cycle controls are defined by modelForUHSModifiedBenchmark.
% Change options at that setup call to select a different operating schedule.
%
% The dataset is external to this repository and is located through
% getDatasetPath('uhs_benchmark'). The selected input is UHS_BENCHMARK_RS.DATA.
% Model setup, simulation and plotting may take substantial time.
%
% Diagnostics report hydrogen inventory at surface conditions, arithmetic
% cell-average pressure/saturation and signed surface well rates. The plotted
% dissolved fraction describes hydrogen currently stored in the aquifer;
% it does not measure cumulative loss or recovery efficiency.
%
% References: Hogeweg, Strobel and Hagemann (2022), Computational Geosciences,
% 26, 1367-1378, doi:10.1007/s10596-022-10163-5; Ahmed et al. (2024),
% Advances in Water Resources, 191, 104772.
%
% SEE ALSO:
%   modelForUHSModifiedBenchmark, summarizeH2StorageStates

clearvars;
%% Notice on Computational Cost
warning('ComputationalCost:High', ...
    'This example runs a full storage schedule and may take substantial time.');
%% Necessary MRST modules for simulation
mrstModule add ad-core ad-blackoil ad-props deckformat mrst-gui test-suite;

% Define the name of the simulation for output files
name = 'H2_STORAGE_RS_UHS_BENCHMARK';
%% Read the Eclipse deck file containing the simulation data
% Change input file by UHS_BENCHMARK_RS_SALT.DATA for SALT EFFECTS
dataPath = getDatasetPath('uhs_benchmark');
dataFile = fullfile(dataPath, 'UHS_BENCHMARK_RS.DATA');
deck = readEclipseDeck(dataFile);
% Note that the user can generate different PVT tables (see thermodynamics)

%% Prepare simulation parameters and initial state
[~, ~, state0, model, schedule] = modelForUHSModifiedBenchmark(deck);

%% Add custom output functions to the model for additional diagnostics
model.OutputStateFunctions{end + 1} = 'CapillaryPressure';
model.OutputStateFunctions{end + 1} = 'SurfaceDensity';
model.OutputStateFunctions{end + 1} = 'ShrinkageFactors';
model.outputFluxes = false;

%% Set up the linear and nonlinear solvers
lsolve = selectLinearSolverAD(model);
nls = NonLinearSolver();
nls.LinearSolver = lsolve;

%% Pack the simulation problem with the initial state, model, and schedule
problem = packSimulationProblem(state0, model, schedule, name, ...
    'NonLinearSolver', nls);

%% Run the simulation
tic;
simulatePackedProblem(problem, 'restartStep', 1);
elapsedTime = toc;
fprintf('Simulation completed in %.2f seconds. \n', elapsedTime);
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
timeMonths = convertTo(cumsum(schedule.step.val), 30 * day);

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
