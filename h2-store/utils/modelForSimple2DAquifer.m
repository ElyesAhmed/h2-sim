function [description, options, state0, model, schedule, plotOptions] = ...
    modelForSimple2DAquifer(deck, varargin)
    % MODELFORSIMPLE2DAQUIFER Set up cyclic hydrogen storage in a layered aquifer.
    %
    % SYNOPSIS:
    %   [description, options] = modelForSimple2DAquifer(deck)
    %   [description, options, state0, model, schedule, plotOptions] = ...
    %       modelForSimple2DAquifer(deck, 'gridSpacing', [2, 2])
    %
    % PARAMETERS:
    %   deck - Eclipse deck with black-oil fluid and three saturation regions.
    %          Deck units are converted to SI during full setup.
    %   Optional name/value pairs override the options returned by this function.
    %
    % RETURNS:
    %   description, options - Case summary and defaults with supplied overrides.
    %   state0, model, schedule - Initial state, black-oil model and controls.
    %   plotOptions - Display settings for the 2D domain. Requesting only the
    %                 first two outputs returns before grid generation.
    %
    % The 50 m by 50 m PEBI grid follows y = 25 + 5*sin(pi*x/50). A caprock
    % polygon is offset 0.1 m above this curve; bedrock lies below y = 5 m.
    % Brine is the oil phase. The model includes dissolved gas and uses gravity
    % along negative y. With use_bc, lateral pressure boundaries are imposed.
    %
    % Grid and rock units are SI, rates are surface-volume rates [m^3/s], times
    % are in seconds, pressures in Pa and temperature options in Kelvin.
    % rateIdle, bhp, use_bhp, initTemp and tempDischarge are retained options but
    % are not applied by this setup. Discharge uses tempCushion.
    %
    % SEE ALSO:
    %   makeAquifer2DRock, makeAquifer2DInitialState, makeAquifer2DSchedule

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
    description = 'Conceptual model for Hydrogen storage with multiple Inj/Prod cycles';

    % Time units
    K0    = 273.15 * Kelvin;  % Absolute temperature offset
    % Optional input arguments
    options = struct( ...
        'rateCharge',       18 * meter^3 / day, ...
        'rateIdle',         0.0 * meter^3 / day, ...
        'rateCushion',      10 * meter^3 / day, ...
        'rateDischarge',    18 * meter^3 / day, ...
        'bhp',              35.0 * barsa, ...
        'tempCharge',       K0 + 40 * Kelvin, ...
        'tempDischarge',    K0 + 40 * Kelvin, ...
        'tempCushion',      K0 + 40 * Kelvin, ...
        'timeCushion',      120 * day, ...
        'timeCharge',       30 * day, ...
        'timeIdle',         10 * day, ...
        'timeShut',         30 * day, ...
        'timeDischarge',    30 * day, ...
        'dtCharge',         3 * day, ...
        'dtCushion',        3 * day, ...
        'dtIdle',           8.4 * hour, ...
        'dtShut',           3 * day, ...
        'dtDischarge',      3 * day, ...
        'gridSpacing',      [0.5, 0.5], ...
        'numCycles',        5, ...
        'chargeOnly',       0, ...
        'cushionOnly',      0, ...
        'dischargeOnly',    0, ...
        'useGroupCtrl',     false, ...
        'initPres',         37 * barsa, ...
        'initTemp',         K0 + 40, ...
        'initSat',          [1, 0], ...
        'use_bc',           true, ...
        'use_cushion',      true, ...
        'use_bhp',          false);

    % Process optional input arguments
    [options, fullSetup, ~] = processTestCaseInput(mfilename, ...
        options, description, varargin{:});
    options = checkOptions(options);

    if ~fullSetup
        return
    end
    % Merge optional input arguments with the existing options
    options = merge_options(options, varargin{:});
    % If the number of output arguments is less than or equal to 2, return early
    if nargout <= 2
        return
    end

    % Define module dependencies for the simulation
    require ad-core ad-props ad-blackoil upr;

    G = setUpGrid(options.gridSpacing);
    rock = makeAquifer2DRock(G);
    deck = convertDeckUnits(deck);
    deck.GRID.ACTNUM = ones(G.cells.num, 1);
    deck.REGIONS.SATNUM = rock.regions.saturation;
    G.cells.indexMap = (1:G.cells.num)';
    deck.GRID.PORO = rock.poro;
    deck.GRID.PERMX = rock.perm(:, 1);
    deck.GRID.PERMY = rock.perm(:, 2);
    deck.GRID = rmfield(deck.GRID, 'PERMZ');
    [~, deckModel, ~] = initEclipseProblemAD(deck, 'getSchedule', false, ...
        'G',                G, 'getInitialState', false);
    fluid = deckModel.fluid;
    deck = deckModel.inputdata;
    gravity reset on;
    model = GenericBlackOilModel(G, rock, fluid, 'water', false, ...
        'disgas',           true, 'gravity', [0, -norm(gravity)], 'inputdata', deck);
    schedule = setUpSchedule(G, rock, fluid, options);
    state0 = makeAquifer2DInitialState(model, schedule.control(1).W, options);
    plotOptions = {'View', [0, 0], 'PlotBoxAspectRatio', [1, 1, 0.25], ...
        'Projection',       'orthographic', 'Size', [800, 300]};
end

function G = setUpGrid(spacing)
    validateattributes(spacing, {'numeric'}, ...
        {'vector', 'numel', 2, 'positive', 'finite'});
    x = linspace(0, 1);
    y = 25 + 5 * sin(pi * x);
    constraints = {[50 .* x', y']};
    G = compositePebiGrid2D(spacing, [50, 50], ...
        'cellConstraints', constraints, 'interpolateCC', true, ...
        'protLayer', false);
    G = computeGeometry(G);
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

function options = checkOptions(options)

    assert(~(options.chargeOnly && options.dischargeOnly), ...
        'Cannot simulate only charge and only discharge at the same time');

end
