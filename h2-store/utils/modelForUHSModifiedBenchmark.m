function [description, options, state0, model, schedule, plotOptions] = modelForUHSModifiedBenchmark(deck,varargin)
% Example modified from:
% Hogeweg, S., Strobel, G., & Hagemann, B. (2022). Benchmark study for the simulation of underground 
% hydrogen storage operations. Comput Geosci, 26, 1367–1378. 
% https://doi.org/10.1007/s10596-022-10163-5
%
% For further details on this case, refer to:
% Ahmed, E., et al. (2024). Phase behavior and black-oil simulations of hydrogen storage in saline aquifers. 
% Advances in Water Resources, 191, 104772.
%
% SEE ALSO:
%   `MRSTExample`, `example_template`, `exampleSuiteTutorial`
%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}
% Step 1: Test case description and options
% Description
description = ['Modified benchmark for hydrogen storage with ', ...
               'multiple injection/production cycles using the black-oil model'];

%% Optional input arguments: options corresponds to scenario 2 of the paper
K0 = 273.15 * Kelvin;
options = struct( ...
    'rateCharge',       6.14062 * 10^5 * meter^3/day/2,   ... % Charge rate (m³/day)
    'rateIdle',         0.0 * kilogram/day/2,             ... % Idle rate (kg/day)
    'rateCushion',      6.14062 * 10^5 * meter^3/day/2,   ... % Cushion (H₂) injection rate (m³/day)
    'rateDischarge',    6.14062 * 10^5 * meter^3/day/2,   ... % Discharge rate (m³/day)
    'bhp',              90.0 * barsa,                     ... % Production bottom hole pressure (BHP) in bar
    'tempCharge',       K0 + 60 * Kelvin,                 ... % Charging temperature (K)
    'tempDischarge',    K0 + 60 * Kelvin,                 ... % Discharging temperature (K)
    'tempCushion',      K0 + 60 * Kelvin,                 ... % Cushion temperature (K)
    'timeCushion',      120 * day,                        ... % Duration of cushioning phase (days)
    'timeCharge',       30 * day,                         ... % Duration of charging phase (days)
    'timeIdle',         15 * day,                         ... % Duration of idle phase (days)
    'timeShut',         30 * day,                         ... % Duration of shut phase (days)
    'timeDischarge',    30 * day,                         ... % Duration of discharging phase (days)
    'dtCharge',         3.0 * day,                        ... % Time step during charging (days)
    'dtCushion',        3.0 * day,                        ... % Time step during cushioning (H₂) (days)
    'dtIdle',           3.0 * day,                        ... % Time step during idle (days)
    'dtShut',           3.0 * day,                        ... % Time step during shut phase (days)
    'dtDischarge',      3.0 * day,                        ... % Time step during discharging (days)
    'numCycles',        4,                               ... % Total number of cycles (charging and discharging)
    'numCyclesCushions',6,                                ... % Number of cycles for cushion gas (H₂)
    'chargeOnly',       0,                                ... % Flag to simulate only the charging phase (0: No, 1: Yes)
    'cushionOnly',      0,                                ... % Flag to simulate only the cushioning phase (0: No, 1: Yes)
    'dischargeOnly',    0,                                ... % Flag to simulate only the discharging phase (0: No, 1: Yes)
    'useGroupCtrl',     false,                            ... % Flag to use group control (true/false)
    'initPres',         81.6 * barsa,                     ... % Initial pressure (bar)
    'initSat',          [1, 0],                           ... % Initial saturation
    'initTemp',         273.15 + 60,                      ... % Initial temperature (°C)
    'use_bc',           true,                             ... % Flag to use boundary conditions (true/false)
    'use_cushion',      true,                             ... % Flag to use cushion phase (true/false)
    'use_bhp',          true                              ... % Flag to use bottom hole pressure (true/false)
    );

%% Process optinal input arguments
[options, fullSetup, ~] = processTestCaseInput(mfilename, ...
    options, description, varargin{:});
options = checkOptions(options);
if ~fullSetup, return; end
%% Optional input arguments
options = merge_options(options, varargin{:});
if nargout <= 2, return;
end
% just to be sure on the module dependencies
require ad-core ad-props ad-blackoil
%% perm, poro, and grid as in the benchmark
G = processGRDECL(deck.GRID, 'checkgrid', false);
G = computeGeometry(G);
deck = convertDeckUnits(deck);
PERMX = deck.GRID.PERMX;
PERMY = deck.GRID.PERMY;
PERMZ = deck.GRID.PERMZ;
perm =  [PERMX PERMY PERMZ];
poro =  deck.GRID.PORO; clear p
rock = makeRock(G, perm, poro);

%% Set up schedule and initiate model from deck
schedule = setUpSchedule(G, rock, options);
[~, model, ~] = initEclipseProblemAD(deck,'getSchedule',false,'getInitialState', false);
fluid = model.fluid;
deck = model.inputdata;
rock.regions.saturation=deck.REGIONS.SATNUM;
gravity reset on;
%% We reset a blackoil model and "oil" is the water phase
model = GenericBlackOilModel(G, rock, fluid, 'water', false, 'disgas', true, 'inputdata', deck);
%% Set up initial state
state0 = setUpInitialState(model, schedule.control(1).W, options);

%% Plotting
plotOptions = {'View'              , [0,0]         , ...
    'PlotBoxAspectRatio', [1,1,0.25]    , ...
    'Projection'        , 'orthographic', ...
    'Size'              , [800, 300]    };
% deck.RUNSPEC.TITLE ='H2_illustration_storage';
% deck_new = model2Deck(model, schedule, 'deck', deck);
end

function W = setUpWells(G, rock, options)

    %% We also reset the well in the highest point: we reset Well coordinates (wc) and radii (r)
    % ps this is slightly different from the benchmark
    wc = [5891; 9612; 13333; 17054; 20775; 24496; 28217; 31938; 35659; 39380; 43101];
    r  = [0.9479; 0.7354; 0.7338; 2.2337; 2.2337; 2.6778; 2.6722; 5.1490; 5.1491; 0.7834; 0.7834];
    
    %% Add production wells with specified parameters
    W = addWell([], G, rock, wc, 'Name', 'Prod', ...
                'Radius', r, 'type', 'rate', ...
                'val', options.rateCharge, 'compi', [0, 1]);
    
    %% Set groups if group control is used
    if options.useGroupCtrl
        [W.group] = deal({'Inj', 'Prod'});
    end

end

function schedule = setUpSchedule(G, rock, options)
    W = setUpWells(G, rock, options);
    schedule = makeBenchmarkStorageSchedule(W, options);
    if options.use_bc
        bc = setUpBc(G, options);
        for k = 1:numel(schedule.control)
            schedule.control(k).bc = bc;
        end
    end
end

function bc = setUpBc(G, options)
    %% Get boundary faces of the grid
    f = boundaryFaces(G);
    
    %% Select lateral faces
    dis = 2.48;
    f1 = (G.faces.normals(f, 3) > dis);
    faces = f(~f1);

    %% Calculate the displacement from a reference point (1140 units)
    Depth = 1140;
    dx = bsxfun(@minus, G.faces.centroids(faces, :), Depth);
    
    %% Calculate pressure drop due to gravity using omega and displacement
    rhoOS = 9.98e+02;
    dp = rhoOS .* (dx * reshape(gravity, [], 1));
    
    %% Define the pressure at the boundary (init pressure plus the gravity-induced pressure drop)
    pressure = options.initPres + dp;

    %% Set the boundary condition with the computed pressure and saturation
    bc = addBC([], faces, 'pressure', pressure, 'sat', options.initSat);    
end



function state0 = setUpInitialState(model, W, options)
    %% Initialize the reservoir solution based on the model grid and initial pressure
    state0 = initResSol(model.G, options.initPres, options.initSat);    
    state0.rs = zeros(size(state0.pressure));  % Set initial solution gas-to-oil ratio to zero
    %% Initialize well solutions
    wellSol = initWellSolAD(W, model, state0);
    wellSol.bhp = options.initPres;  % Set initial bottom hole pressure for all wells
    state0.wellSol = wellSol;  % Store well solutions in the state structure
end


%-------------------------------------------------------------------------%
function options = checkOptions(options)
    
    assert(~(options.chargeOnly && options.dischargeOnly), ...
        'Cannot simulate only charge and only discharge at the same time');
    
end
