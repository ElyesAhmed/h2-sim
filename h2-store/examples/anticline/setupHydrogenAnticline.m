function [model, state0, schedule, configuration] = setupHydrogenAnticline(varargin)
    % SETUPHYDROGENANTICLINE Small four-layer Gaussian hydrogen-storage case.
    %
    % SYNOPSIS:
    %   [model, state0, schedule, configuration] = setupHydrogenAnticline()
    %   [...] = setupHydrogenAnticline('horizontalCells', [9, 9])
    %
    % Adapted from Problem 4 of Okoroafor et al. (2023),
    % doi:10.1016/j.enconman.2023.117409. The analytical Gaussian geometry,
    % layer properties and storage operations follow that description.
    % The grid and PVT approximations differ; no benchmark validation is claimed.
    %
    % OPTIONS:
    %   horizontalCells - Odd [nx,ny] counts >= 3 (default [25,25]).
    %   buildupDays     - Initial injection duration [days] (default 365).
    %   shutInDays      - Shut-in duration [days] (default 90).
    %   numCycles       - Withdrawal/reinjection cycle count (default 5).
    %   cycleStageDays  - Duration of each cyclic operation [days] (default 7).
    %   injectionRate   - Cushion injection [surface m^3/day] (default 200000).
    %   cycleRate       - Gas withdrawal/reinjection [surface m^3/day] (400000).
    %
    % The fixed 9 vertical cells resolve shallow aquifer, cap rock, storage
    % formation and underburden with 1,2,4,2 cells. Brine occupies phase O;
    % hydrogen occupies phase G. Dissolution, vaporization, hysteresis and
    % microbial reactions are disabled. Temperature is fixed at 323.15 K.
    % No files, plots or external data downloads are required.
    parser = inputParser();
    parser.PartialMatching = false;
    addParameter(parser, 'horizontalCells', [25, 25], @validGrid);
    addParameter(parser, 'buildupDays', 365, @positiveScalar);
    addParameter(parser, 'shutInDays', 90, @nonnegativeScalar);
    addParameter(parser, 'numCycles', 5, ...
        @(x) nonnegativeScalar(x) && x == fix(x));
    addParameter(parser, 'cycleStageDays', 7, @positiveScalar);
    addParameter(parser, 'injectionRate', 200000, @positiveScalar);
    addParameter(parser, 'cycleRate', 400000, @positiveScalar);
    parse(parser, varargin{:});
    configuration = parser.Results;
    configuration.layerNames = {'Shallow aquifer', 'Cap rock', ...
        'Storage formation', 'Underburden'};
    configuration.layerThicknessM = [10, 50, 20, 25];
    configuration.layerPorosity = [0.1, 0.1, 0.25, 0.1];
    configuration.layerPermeabilityM2 = [9.87e-15, 9.87e-20, 6.91e-13, 9.87e-18];
    configuration.capillaryEntryPa = [0.4e6, 4e6, 0.4e6, 4e6];
    configuration.temperatureK = 323.15;
    configuration.referencePressurePa = 4.1e6;
    configuration.referenceDepthM = 415;
    configuration.surfaceTemperatureK = 288.71;
    configuration.surfacePressurePa = 101325;
    mrstModule add ad-core ad-props ad-blackoil;

    [G, region, completion] = makeGrid(configuration);
    permeability = configuration.layerPermeabilityM2(region).';
    porosity = configuration.layerPorosity(region).';
    rock = makeRock(G, permeability, porosity);
    rock.regions.saturation = region;
    fluid = makeFluid(configuration);
    model = GenericBlackOilModel(G, rock, fluid, 'water', false, ...
        'disgas', false, 'vapoil', false, 'gravity', [0, 0, 9.80665]);
    model.minimumPressure = barsa;
    model.toleranceCNV = 1e-8;
    model.toleranceMB = 1e-10;
    model = model.validateModel();
    pressure = hydrostaticPressure(G.cells.centroids(:, 3), configuration);
    state0 = initResSol(G, pressure, [1, 0]);
    state0.T = configuration.temperatureK * ones(G.cells.num, 1);

    boundary = boundaryFaces(G);
    locations = G.faces.centroids(boundary, :);
    lateral = locations(:, 1) < 1e-8 | locations(:, 1) > 5000 - 1e-8 | ...
        locations(:, 2) < 1e-8 | locations(:, 2) > 5000 - 1e-8;
    boundary = boundary(lateral);
    bc = addBC([], boundary, 'pressure', hydrostaticPressure( ...
        G.faces.centroids(boundary, 3), configuration), 'sat', [1, 0]);
    W = addWell([], G, rock, completion, 'Name', 'Storage', ...
        'Type', 'rate', 'Val', configuration.injectionRate / day, ...
        'Comp_i', [0, 1], 'Radius', 0.125, 'Sign', 1, 'Dir', 'z', ...
        'refDepth', configuration.referenceDepthM);
    schedule = makeSchedule(W, bc, configuration);
end

function [G, region, completion] = makeGrid(configuration)
    counts = configuration.horizontalCells;
    horizontal = cell(1, 2);
    for direction = 1:2
        unit = linspace(-1, 1, counts(direction) + 1);
        horizontal{direction} = 2500 + 2500 * sign(unit) .* abs(unit).^1.6;
    end
    vertical = [0, 10, 35, 60, 65, 70, 75, 80, 92.5, 105];
    G = tensorGrid(horizontal{1}, horizontal{2}, vertical);
    x = G.nodes.coords(:, 1) - 2500;
    y = G.nodes.coords(:, 2) - 2500;
    base = 750 - 300 * exp(-(x.^2 + y.^2) / (2 * 500^2));
    G.nodes.coords(:, 3) = base - 105 + G.nodes.coords(:, 3);
    G = computeGeometry(G);
    [i, j, k] = ind2sub(G.cartDims, G.cells.indexMap);
    layer = [1, 2, 2, 3, 3, 3, 3, 4, 4];
    region = reshape(layer(k), [], 1);
    completion = find(i == (counts(1) + 1) / 2 & ...
        j == (counts(2) + 1) / 2 & region == 3);
end

function fluid = makeFluid(configuration)
    temperature = configuration.temperatureK;
    reference = configuration.referencePressurePa;
    gasConstant = 8.31446261815324;
    mass = 0.002016;
    surfaceP = configuration.surfacePressurePa;
    surfaceT = configuration.surfaceTemperatureK;
    surfaceDensity = surfaceP * mass / (gasConstant * surfaceT * ...
        calculateBrillBreggsZfactorHydrogen(surfaceT, surfaceP));
    fluid = initSimpleADIFluid('phases', 'OG', 'rho', [1000, surfaceDensity], ...
        'mu', [0.55e-3, 9e-6], 'c', [4.5e-10, 0], ...
        'pRef', reference, 'cR', 1.5e-12, 'n', [4, 3.5]);
    fluid.bG = @(p, varargin) p .* mass ./ (gasConstant * temperature .* ...
        calculateBrillBreggsZfactorHydrogen(temperature, p) * surfaceDensity);
    fluid.krO = @(s, varargin) 0.8 * min(max((s - 0.1) / 0.8, 0), 1).^4;
    fluid.krG = @(s, varargin) 0.2 * min(max((s - 0.1) / 0.8, 0), 1).^3.5;
    fluid.pcOG = cell(1, 4);
    for region = 1:4
        entry = configuration.capillaryEntryPa(region);
        fluid.pcOG{region} = @(sg, varargin) entry * ...
            max((1 - sg - 0.1) / 0.9, 1e-3).^(-1 / 1.2);
    end
end

function pressure = hydrostaticPressure(depth, configuration)
    compressibility = 4.5e-10;
    displacement = depth - configuration.referenceDepthM;
    pressure = configuration.referencePressurePa - ...
        log(1 - compressibility * 1000 * 9.80665 * displacement) / compressibility;
end

function schedule = makeSchedule(W, bc, configuration)
    controls = repmat(struct('W', W, 'bc', bc, 'src', []), 4, 1);
    controls(2).W.status = false;
    controls(3).W.type = 'grat';
    controls(3).W.val = -configuration.cycleRate / day;
    controls(3).W.sign = -1;
    controls(4).W.val = configuration.cycleRate / day;
    buildup = rampSteps(configuration.buildupDays * day, 15 * day);
    shutIn = rampSteps(configuration.shutInDays * day, 7 * day);
    cyclic = rampSteps(configuration.cycleStageDays * day, day);
    cyclicValues = repmat([cyclic; cyclic], configuration.numCycles, 1);
    cyclicControls = repmat([3 * ones(numel(cyclic), 1); ...
        4 * ones(numel(cyclic), 1)], configuration.numCycles, 1);
    schedule = struct('control', controls, 'step', struct( ...
        'val', [buildup; shutIn; cyclicValues], ...
        'control', [ones(numel(buildup), 1); ...
        2 * ones(numel(shutIn), 1); cyclicControls]));
end

function steps = rampSteps(duration, maximum)
    if duration == 0
        steps = zeros(0, 1);
        return
    end
    ramp = 0.05 * day * 2.^(0:8).';
    ramp = ramp(ramp < maximum & cumsum(ramp) < duration);
    remaining = duration - sum(ramp);
    count = ceil(remaining / maximum);
    steps = [ramp; repmat(remaining / count, count, 1)];
end

function valid = validGrid(value)
    valid = isnumeric(value) && isequal(size(value), [1, 2]) && ...
        all(isfinite(value)) && all(value >= 3) && all(mod(value, 2) == 1);
end

function valid = positiveScalar(value)
    valid = nonnegativeScalar(value) && value > 0;
end

function valid = nonnegativeScalar(value)
    valid = isnumeric(value) && isscalar(value) && isfinite(value) && value >= 0;
end

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
