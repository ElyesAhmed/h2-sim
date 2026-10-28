function [description, options, state0, model, schedule, deck, plotOptions] = modelForDome3DAquifer(deck, varargin)
    % MODELFORDOME3DAQUIFER Set up cyclic storage in a layered 3D dome aquifer.
    %   The default grid is 5000 m by 5000 m horizontally, with 51 by 51 by 32
    %   cells and a Gaussian dome centered at [2500, 2500] m. The model uses
    %   dissolved gas and vaporized brine, with gravity along negative z.
    %   See the returned options for rates, durations and initial conditions.
    %
    %   Grid geometry and rock properties are constructed by makeDomeAquiferGrid
    %   and makeDomeAquiferRock. Model setup does not open a layer plot; run
    %   dome3DModel to display that plot separately.
    %
    % Reference: Ahmed, E., et al. (2024). Phase behavior and black-oil simulations
    % of hydrogen storage in saline aquifers. Advances in Water Resources, 191,
    % 104772.
    %
    % SEE ALSO:
    %   makeDomeAquiferGrid, makeDomeAquiferRock, findDomeAquiferWellCells

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

    % Description
    description = 'Conceptual model for hydrogen storage with multiple injection/production cycles';

    % Optional input arguments
    K0 = 273.15 * Kelvin;    % Reference temperature in Kelvin

    % Define simulation options
    options = struct( ...
        'rateCharge',       4.0e5 * meter^3 / day,    ... % Charge rate
        'rateIdle',         0.0 * kilogram / day,      ... % Idle rate
        'rateCushion',      2.0e5 * meter^3 / day,    ... % Cushion-H2 injection rate
        'rateDischarge',    4.0e5 * meter^3 / day,    ... % Discharge rate
        'bhp',              35.0 * barsa,              ... % Produced bottom hole pressure (BHP)
        'tempCharge',       K0 + 50 * Kelvin,          ... % Charge temperature
        'tempDischarge',    K0 + 50 * Kelvin,          ... % Discharge temperature
        'tempCushion',      K0 + 50 * Kelvin,          ... % Cushion temperature
        'timeCushion',      365 * day,                 ... % Cushion time
        'timeCharge',       10 * day,                  ... % Charging time
        'timeIdle',         3 * day,                   ... % Idle time
        'timeShut',         90 * day,                  ... % Shut-in time
        'timeDischarge',    10 * day,                  ... % Discharging time
        'dtCharge',         1 * day,                ... % Time step during charging
        'dtCushion',        1 * day,                ... % Time step during cushioning
        'dtIdle',           8.4 * hour,                ... % Time step during idle
        'dtShut',           8.4 * hour,                ... % Time step during shut-in
        'dtDischarge',      1 * day,                ... % Time step during discharging
        'numCycles',        4,                        ... % Number of operational cycles
        'chargeOnly',       0,                         ... % Flag to simulate only the charging phase
        'cushionOnly',      0,                         ... % Flag to simulate only the cushioning phase
        'dischargeOnly',    0,                         ... % Flag to simulate only the discharging phase
        'useGroupCtrl',     false,                     ... % Use group control for injection/production
        'initPres',         37 * barsa,                ... % Initial reservoir pressure
        'initSat',          [1 0],                     ... % Initial reservoir saturation
        'initTemp',         273.15 + 50,               ... % Initial temperature
        'use_bc',           true,                      ... % Use boundary conditions
        'use_cushion',      true,                      ... % Use cushion phase
        'use_bhp',          false                      ... % Use bottom hole pressure control
        );

    % Process optional input arguments
    [options, fullSetup, ~] = processTestCaseInput(mfilename, options, description, varargin{:});
    options = checkOptions(options); % Validate options

    if ~fullSetup
        return
    end
    require ad-core ad-props ad-blackoil deckformat vemmech;

    [G, layers] = makeDomeAquiferGrid();
    rock = makeDomeAquiferRock(G, layers);
    deck = convertDeckUnits(deck);
    deck.GRID.ACTNUM = ones(G.cells.num, 1);
    deck.REGIONS.SATNUM = rock.regions.saturation;
    deck.GRID.PORO = rock.poro;
    deck.GRID.PERMX = rock.perm(:, 1);
    deck.GRID.PERMY = rock.perm(:, 2);
    deck.GRID.PERMZ = rock.perm(:, 3);

    %% Initialize fluid tables from the deck
    [~, model, ~] = initEclipseProblemAD(deck, 'G', G, 'getSchedule', false, 'getInitialState', false);
    fluid = model.fluid;
    deck = model.inputdata;

    %% blackoil model setup
    gravity reset on;
    model = GenericBlackOilModel(G, rock, fluid, 'water', false, 'disgas', true, 'vapoil', true, ...
        'gravity', [0, 0, -norm(gravity)], 'inputdata', deck);

    %% Setup schedule
    schedule = setUpSchedule(G, rock, fluid, options);

    %% Setup initial state
    state0 = makeDomeAquiferInitialState(model, schedule.control(1).W, options);

    %% Plotting options
    plotOptions = {'View', [0, 0], ...
        'PlotBoxAspectRatio', [1, 1, 0.25], ...
        'Projection', 'orthographic', ...
        'Size', [800, 300]};

end

function W = setUpWells(G, rock, options)
    cells = findDomeAquiferWellCells(G);
    W = addWell([], G, rock, cells, 'Name', 'Prod', ...
        'Radius', 12.5 * centi * meter, 'type', 'rate', ...
        'val', options.rateCharge, 'compi', [0, 1]);
    if options.useGroupCtrl
        [W.group] = deal({'Inj', 'Prod'});
    end
end

function schedule = setUpSchedule(G, rock, fluid, options)
    W = setUpWells(G, rock, options);
    schedule = makeDomeAquiferSchedule(W, options);
    if options.use_bc
        bc = makeDomeAquiferBoundaryConditions(G, fluid, options);
        for i = 1:numel(schedule.control)
            schedule.control(i).bc = bc;
        end
    end
end

% -------------------------------------------------------------------------%
function options = checkOptions(options)

    assert(~(options.chargeOnly && options.dischargeOnly), ...
        'Cannot simulate only charge and only discharge at the same time');

end
