function [description, options, state0, model, schedule, plotOptions] = modelForSimple2DAquifer(deck,varargin)
% This example simulates the injection and behavior of hydrogen (H₂) in a 2D saline aquifer 
% using the black-oil model. The aquifer has a dome-shaped structure defined by the function 
% F(x) = σ + r*sin(π*x), with parameters σ = 25 and r = 5. 
% 
% The domain is 50 m × 50 m, with caprock and bedrock layers providing containment through 
% high entry (capillary) pressure and low permeability. 
% 
% A single well is placed at the top of the trap, in the uppermost cell beneath the caprock. 
% We apply fixed hydrostatic pressure at the lateral boundaries and enforce no-flux conditions 
% at the top and bottom boundaries.
%
% Relative permeability and capillary pressure follow the Brooks-Corey model, with varying 
% residual saturations for different rock types.
%
% SEE ALSO:
%   `MRSTExample`, `example_template`, `exampleSuiteTutorial`.

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify it under the terms of the GNU 
General Public License as published by the Free Software Foundation, either version 3 of 
the License, or (at your option) any later version.

MRST is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with MRST. If not, 
see <http://www.gnu.org/licenses/>.
%}
% Step 1: Test Case Description and Options
%---------------------------------------------------------------------%
% Description of the conceptual model for hydrogen storage with multiple
% injection/production (Inj/Prod) cycles.

description = 'Conceptual model for Hydrogen storage with multiple Inj/Prod cycles';

% Time units
K0    = 273.15 * Kelvin;  % Absolute temperature offset
% Optional input arguments
options = struct( ...
    'rateCharge'   , 18 * meter^3/day   , ... % Gas surface-volume rate during charging (m^3/day)
    'rateIdle'     , 0.0 * meter^3/day  , ... % No injection during idle periods
    'rateCushion'  , 10 * meter^3/day   , ... % Cushion gas surface-volume rate (m^3/day)
    'rateDischarge', 18 * meter^3/day   , ... % Gas surface-volume rate during discharge (m^3/day)
    'bhp'          , 35.0 * barsa        , ... % Bottom hole pressure during production
    'tempCharge'   , K0 + 40 * Kelvin    , ... % Injection temperature during charging
    'tempDischarge', K0 + 40 * Kelvin    , ... % Production temperature during discharge
    'tempCushion'  , K0 + 40 * Kelvin    , ... % Temperature for cushion gas phase
    'timeCushion'  , 120 * day            , ... % Duration of cushion gas phase
    'timeCharge'   , 30 * day            , ... % Duration of hydrogen charging
    'timeIdle'     , 10 * day            , ... % Idle period between charge/discharge cycles
    'timeShut'     , 30 * day            , ... % Shut-in period (no activity)
    'timeDischarge', 30 * day            , ... % Duration of hydrogen production (discharge)
    'dtCharge'     , 3*day          , ... % Timestep during charging
    'dtCushion'    , 3*day          , ... % Timestep during cushion phase
    'dtIdle'       , 8.4 * hour          , ... % Timestep during idle phase
    'dtShut'       , 3*day          , ... % Timestep during shut-in phase
    'dtDischarge'  , 3*day          , ... % Timestep during discharge
    'gridSpacing'  , [0.5,0.5]          , ... % PEBI target cell sizes (m)
    'numCycles'    , 5                  , ... % Number of injection/production cycles
    'chargeOnly'   , 0                   , ... % Simulate only charging period
    'cushionOnly'  , 0                   , ... % Simulate only cushion gas phase
    'dischargeOnly', 0                   , ... % Simulate only discharge period
    'useGroupCtrl' , false               , ... % Group control for wells (optional)
    'initPres'     , 37 * barsa          , ... % Initial reservoir pressure
    'initTemp'     , K0 + 40             , ... % Initial reservoir temperature
    'initSat'      ,[1 0]                , ... % Initial reservoir saturation
    'use_bc'       , true                , ... % Use boundary conditions
    'use_cushion'  , true                , ... % Include cushion gas in the simulation
    'use_bhp'      , false                 ... % Use bottom hole pressure control
);

% Process optional input arguments
[options, fullSetup, ~] = processTestCaseInput(mfilename, ...
options, description, varargin{:});  % Process test case inputs
options = checkOptions(options);          % Check the validity of options

if ~fullSetup
    return;  % If setup is incomplete, exit early
end
% Merge optional input arguments with the existing options
options = merge_options(options, varargin{:});
% If the number of output arguments is less than or equal to 2, return early
if nargout <= 2
    return;
end

% Define module dependencies for the simulation
require ad-core ad-props ad-blackoil spe10 upr

% Grid setup
% Generate a constraint path along the x-axis and define the grid shape
x = linspace(0.0, 1.0);       % Generate linearly spaced points for x-axis
y = 25 + 5 * sin(pi * x);     % Define y-axis using a sinusoidal function for dome shape
w = {[50 .* x', y']};         % Combine x and y to form 2D points for grid constraints

% Grid size scaling and dimensions
validateattributes(options.gridSpacing,{'numeric'},{'vector','numel',2,'positive','finite'});
gS = options.gridSpacing;              % Scaling factors for grid
pdims = [50, 50];             % Grid dimensions in x and y directions

% Generate two versions of a composite PEBI grid
G1 = compositePebiGrid2D(gS, pdims, 'cellConstraints', w, ...
    'interpolateCC', true, 'protLayer', false);  % Without protection layer

% G2 = compositePebiGrid2D(gS, pdims, 'cellConstraints', w, ...
%     'interpolateCC', true, 'protLayer', true);   % With protection layer

% Compute geometry for the grid
G = computeGeometry(G1);

  
% Slight adjustment to the y-axis values for accuracy
y = y + 0.1;  % Adjust y-values to ensure correct positioning above the grid
% Create a polygon representation of the line
linePolygon = [[0, 50]; [50 .* x', y']; [50, 50]];  % Define the polygon that represents the dome structure

% Define the cell vertices from the grid
cellVertices = G.cells.centroids;  % Extract centroids of the grid cells

% Use inpolygon to find which cells are above the line
aboveLineMask = inpolygon(cellVertices(:, 1), cellVertices(:, 2), linePolygon(:, 1), linePolygon(:, 2)); 

% Create rock properties
rock = makeRock(G, [10 * milli * darcy, 10 * milli * darcy], 0.25);  % Define rock permeability and porosity
caprock = aboveLineMask;  % Assign mask for caprock
bedrock = find(G.cells.centroids(:, 2) < 5);  % Identify bedrock cells based on their centroid positions

% Set permeability for caprock and bedrock
rock.perm(caprock, :) = 1.0e-04 * milli * darcy;  % Caprock permeability
rock.perm(bedrock, :) = 1.0e-02 * milli * darcy;  % Bedrock permeability

% Set porosity for caprock and bedrock
rock.poro(caprock) = 0.1;  % Caprock porosity
rock.poro(bedrock) = 0.1;  % Bedrock porosity

% Convert deck units for simulation
deck = convertDeckUnits(deck);
% Initialize activity and saturation numbers in the deck
deck.GRID.ACTNUM = ones(G.cells.num, 1);  % Set active cells
deck.REGIONS.SATNUM = ones(G.cells.num, 1);  % Set saturation numbers to 1

% Update saturation numbers for specific regions
deck.REGIONS.SATNUM(bedrock) = 2;  % Bedrock saturation number
deck.REGIONS.SATNUM(caprock) = 3;  % Caprock saturation number
rock.regions.saturation = deck.REGIONS.SATNUM;  % Assign saturation regions to rock properties
% We update indexmap and rock in G
G.cells.indexMap = [1:G.cells.num]';
deck.GRID.PORO=rock.poro;
deck.GRID.PERMX=rock.perm(:,1);
deck.GRID.PERMY=rock.perm(:,2);
deck.GRID = rmfield(deck.GRID,'PERMZ');
% Initialize Eclipse problem for AD (Automatic Differentiation)
[~, model, ~] = initEclipseProblemAD(deck,'getSchedule',false,'G',G,'getInitialState', false);  

% Extract fluid and input data from the model
fluid = model.fluid;  
deck = model.inputdata;  


% Reset gravity for the model
gravity reset on;

% Create the black-oil model with gravity effects and input data
model = GenericBlackOilModel(G, rock, fluid, ...
    'water', false, 'disgas', true, 'gravity', [0 -norm(gravity)], 'inputdata', deck);

% Set up the simulation schedule based on the grid, rock properties, fluid model, and options
schedule = setUpSchedule(G, rock, fluid, options);

% Set up the initial state for the simulation using the first control well from the schedule
state0 = setUpInitialState(model, schedule.control(1).W, options);

% Define plotting options for visualization
plotOptions = {'View'              , [0,0]         , ...
    'PlotBoxAspectRatio', [1,1,0.25]    , ...
    'Projection'        , 'orthographic', ...
    'Size'              , [800, 300]    };
% Optional: Set title for the simulation run in the deck (commented out)
% deck.RUNSPEC.TITLE = 'H2_illustration_storage';

% Optional: Convert the model to a deck format (commented out)
% deck_new = model2Deck(model, schedule, 'deck', deck);

end

function W = setUpWells(G, rock, options)
    % Complete the gas well beneath the crest of the 2D aquifer.
    cells = findAquifer2DWellCells(G, rock);
    W = addWell([], G, rock, cells, ...
        'Name', 'Prod', ...
        'Radius', 5 * centi * meter, ...
        'Type', 'rate', ...
        'Val', options.rateCharge, ...
        'Compi', [0, 1]);
    if options.useGroupCtrl
        [W.group] = deal({'Inj', 'Prod'});
    end
end

function schedule = setUpSchedule(G, rock, fluid, options)
    W = setUpWells(G, rock, options);
    schedule = makeAquifer2DSchedule(W, options);
    if options.use_bc
        bc = makeAquifer2DBoundaryConditions(G, fluid, options);
        for i = 1:numel(schedule.control)
            schedule.control(i).bc = bc;
        end
    end
end

function state0 = setUpInitialState(model, W, options)
    % setUpInitialState - Initializes the state of the reservoir simulation.
    %
    % Syntax: state0 = setUpInitialState(model, W, options)
    %
    % Inputs:
    %   model  - Simulation model structure containing grid and rock properties
    %   W      - Well structure
    %   options - Simulation options structure
    %
    % Outputs:
    %   state0 - Initial state structure containing pressure and saturation

    % Initialize reservoir solution with specified initial pressure and default saturations
    state0 = initResSol(model.G, options.initPres, options.initSat);  % [1, 0] represents initial saturations

    % Initialize residual saturations (set to zero initially)
    state0.rs = 0 .* state0.pressure;

    % Uncomment and modify the following lines to adjust saturations based on bedrock properties
    % bedrock = find(model.G.cells.centroids(:, 2) < 15);
    % state0.s(bedrock, 1) = 1 - (model.rock.poro(bedrock, 1) .* model.G.cells.centroids(bedrock, 2) ./ 5);
    % state0.s(bedrock, 2) = (model.rock.poro(bedrock, 1) .* model.G.cells.centroids(bedrock, 2) ./ 5);

    % Initialize well solutions
    wellSol = initWellSolAD(W, model, state0);
    wellSol.bhp = options.initPres;  % Set initial bottom hole pressure for wells
    state0.wellSol = wellSol;         % Assign well solutions to the state

end


%-------------------------------------------------------------------------%
function options = checkOptions(options)
    
    assert(~(options.chargeOnly && options.dischargeOnly), ...
        'Cannot simulate only charge and only discharge at the same time');
    
end
