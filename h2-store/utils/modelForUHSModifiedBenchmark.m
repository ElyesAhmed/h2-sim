function [description, options, state0, model, schedule, plotOptions] = ...
    modelForUHSModifiedBenchmark(deck, varargin)
    % MODELFORUHSMODIFIEDBENCHMARK Set up cyclic hydrogen storage in a saline aquifer.
    %
    % SYNOPSIS:
    %   [description, options] = modelForUHSModifiedBenchmark([], false)
    %   [description, options, state0, model, schedule, plotOptions] = ...
    %       modelForUHSModifiedBenchmark(deck, 'name', value, ...)
    %
    % PARAMETERS:
    %   deck - Metric ECLIPSE deck providing geometry, rock and fluid tables.
    %          Fixed logical well-cell IDs must be present and active.
    %   Optional name/value pairs override the default scenario options. Rates
    %   (rateCharge, rateCushion, rateDischarge and rateIdle) are surface volumes
    %   in m^3/s. Pressures bhp and initPres are in Pa; durations time* and target
    %   timesteps dt* are in seconds. Temperatures temp* and initTemp are in K.
    %   initSat gives oil/gas saturations, with brine occupying the oil phase.
    %
    %   numCycles sets the storage-cycle count. numCyclesCushions sets the positive
    %   integer number of cushion/shut-in pairs. use_cushion includes buildup;
    %   use_bhp selects BHP-controlled buildup; use_bc adds prescribed boundary
    %   pressures. Numeric 0/1 selectors chargeOnly, dischargeOnly and cushionOnly
    %   select schedule stages.
    %   Charge-only and discharge-only cannot both be enabled. useGroupCtrl assigns
    %   injection/production well groups.
    %
    % RETURNS:
    %   description - Case description used by the MRST test-suite interface.
    %   options     - Resolved setup options, in SI units.
    %   state0      - Uniform reservoir pressure/saturation, zero dissolved gas
    %                 and initialized well solutions.
    %   model       - Isothermal black-oil model with dissolved hydrogen in brine.
    %   schedule    - Well controls, timesteps and optional boundary conditions.
    %   plotOptions - View settings for MRST visualization.
    %
    % Full setup resets gravity to standard downward acceleration before building
    % boundary pressures and the model. Metadata-only calls leave gravity unchanged.
    % The isothermal state does not apply initTemp. Discharge well controls inherit
    % tempCushion; tempDischarge is retained as an option without being applied.
    %
    % REFERENCES:
    %   Hogeweg, S., Strobel, G. and Hagemann, B. (2022). Benchmark study for the
    %   simulation of underground hydrogen storage operations. Computational
    %   Geosciences, 26, 1367-1378. doi:10.1007/s10596-022-10163-5.
    %   Ahmed, E., et al. (2024). Phase behavior and black-oil simulations of
    %   hydrogen storage in saline aquifers. Advances in Water Resources, 191,
    %   104772.
    %
    % SEE ALSO:
    %   processTestCaseInput, makeBenchmarkRock, makeBenchmarkStorageSchedule,
    %   makeBenchmarkBoundaryConditions, makeBenchmarkInitialState

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

    description = ['Modified benchmark for hydrogen storage with ', ...
        'multiple injection/production cycles using the black-oil model'];

    % Default storage-cycle options.
    K0 = 273.15 * Kelvin;
    options = struct( ...
        'rateCharge',        6.14062 * 10^5 * meter^3 / day / 2, ...
        'rateIdle',          0.0 * meter^3 / day / 2, ...
        'rateCushion',       6.14062 * 10^5 * meter^3 / day / 2, ...
        'rateDischarge',     6.14062 * 10^5 * meter^3 / day / 2, ...
        'bhp',               90.0 * barsa, ...
        'tempCharge',        K0 + 60 * Kelvin, ...
        'tempDischarge',     K0 + 60 * Kelvin, ...
        'tempCushion',       K0 + 60 * Kelvin, ...
        'timeCushion',       120 * day, ...
        'timeCharge',        30 * day, ...
        'timeIdle',          15 * day, ...
        'timeShut',          30 * day, ...
        'timeDischarge',     30 * day, ...
        'dtCharge',          3.0 * day, ...
        'dtCushion',         3.0 * day, ...
        'dtIdle',            3.0 * day, ...
        'dtShut',            3.0 * day, ...
        'dtDischarge',       3.0 * day, ...
        'numCycles',         4, ...
        'numCyclesCushions', 6, ...
        'chargeOnly',        0, ...
        'cushionOnly',       0, ...
        'dischargeOnly',     0, ...
        'useGroupCtrl',      false, ...
        'initPres',          81.6 * barsa, ...
        'initSat',           [1, 0], ...
        'initTemp',          273.15 + 60, ...
        'use_bc',            true, ...
        'use_cushion',       true, ...
        'use_bhp',           true);

    [options, fullSetup, ~] = processTestCaseInput(mfilename, ...
        options, description, varargin{:});
    checkOptions(options);
    if ~fullSetup
        return
    end
    options = merge_options(options, varargin{:});
    if nargout <= 2
        return
    end
    require ad-core ad-props ad-blackoil;

    %% Grid and active-cell rock properties
    G = processGRDECL(deck.GRID, 'checkgrid', false);
    G = computeGeometry(G);
    deck = convertDeckUnits(deck);
    rock = makeBenchmarkRock(G, deck);

    %% Schedule and fluid properties
    gravity reset on;
    schedule = setUpSchedule(G, rock, options);
    [~, deckModel, ~] = initEclipseProblemAD(deck, 'G', G, ...
        'getSchedule', false, 'getInitialState', false);
    fluid = deckModel.fluid;
    deck = deckModel.inputdata;

    %% Flow model and initial state
    model = GenericBlackOilModel(G, rock, fluid, ...
        'water', false, 'disgas', true, 'inputdata', deck);
    state0 = makeBenchmarkInitialState(model, schedule.control(1).W, options);
    plotOptions = {'View',               [0, 0], ...
        'PlotBoxAspectRatio', [1, 1, 0.25], ...
        'Projection',         'orthographic', ...
        'Size',               [800, 300]};
end

function W = setUpWells(G, rock, options)
    % Fixed logical deck-cell completions and radii for the modified benchmark.
    logicalCells = [5891; 9612; 13333; 17054; 20775; 24496; ...
        28217; 31938; 35659; 39380; 43101];
    radii = [0.9479; 0.7354; 0.7338; 2.2337; 2.2337; 2.6778; ...
        2.6722; 5.1490; 5.1491; 0.7834; 0.7834];
    [active, cells] = ismember(logicalCells, G.cells.indexMap);
    assert(all(active), 'h2sim:h2store:InactiveBenchmarkCompletion', ...
        'Benchmark completion cells must be active: missing logical cells %s.', ...
        mat2str(logicalCells(~active)'));
    W = addWell([], G, rock, cells, 'Name', 'Prod', ...
        'Radius', radii, 'type', 'rate', ...
        'val', options.rateCharge, 'compi', [0, 1]);
    if options.useGroupCtrl
        [W.group] = deal({'Inj', 'Prod'});
    end
end

function schedule = setUpSchedule(G, rock, options)
    W = setUpWells(G, rock, options);
    schedule = makeBenchmarkStorageSchedule(W, options);
    if options.use_bc
        bc = makeBenchmarkBoundaryConditions(G, options);
        for k = 1:numel(schedule.control)
            schedule.control(k).bc = bc;
        end
    end
end

function checkOptions(options)
    assert(~(options.chargeOnly && options.dischargeOnly), ...
        'Cannot simulate only charge and only discharge at the same time');
end
