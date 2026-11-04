function [model, state0, schedule, parameters] = setupHydrogenMixing2D(varargin)
    % SETUPHYDROGENMIXING2D Closed binary-gas gravity and diffusion example.
    %
    % SYNOPSIS:
    %   [model, state0, schedule, parameters] = setupHydrogenMixing2D()
    %   [...] = setupHydrogenMixing2D('gridSize', [20, 20])
    %
    % Adaptation of Problem 2 of Okoroafor et al. (2023),
    % doi:10.1016/j.enconman.2023.117409. A 100-by-100 m vertical section
    % starts with methane on the left and hydrogen on the right. All
    % boundaries are sealed. No water, microbes, wells or PHREEQC are used.
    % The one-metre extrusion sets inventories per metre of section width.
    %
    % OPTIONS:
    %   gridSize             - [nx, nz] positive even integers (default [40,40]).
    %   durationDays         - Simulation duration [days] (default 1825).
    %   outputCount          - Number of logarithmically spaced steps (80).
    %   diffusionCoefficient - Binary diffusion [m^2/s] (default 7.26e-5).
    %   gravityEnabled       - Enable downward gravity (default true).
    %
    % The demonstration uses Peng-Robinson with zero binary interaction and
    % H2sim's mass-fraction Fickian flux, with unit tortuosity. It is not a
    % certified reproduction of the published cross-simulator comparison.
    % See also exampleHydrogenMixing2D, animateHydrogenMixing2D.

    parser = inputParser();
    parser.PartialMatching = false;
    addParameter(parser, 'gridSize', [40, 40], @validGrid);
    addParameter(parser, 'durationDays', 1825, @positiveScalar);
    addParameter(parser, 'outputCount', 80, ...
        @(x) positiveScalar(x) && x == fix(x));
    addParameter(parser, 'diffusionCoefficient', 7.26e-5, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    addParameter(parser, 'gravityEnabled', true, ...
        @(x) islogical(x) && isscalar(x));
    parse(parser, varargin{:});
    parameters = parser.Results;
    mrstModule add ad-core ad-props compositional;

    dimensions = parameters.gridSize;
    G = cartGrid([dimensions(1), 1, dimensions(2)], [100, 1, 100]);
    G.nodes.coords(:, 3) = G.nodes.coords(:, 3) + 400;
    G = computeGeometry(G);
    rock = makeRock(G, 1e-14, 0.1);
    mixture = TableCompositionalMixture({'Hydrogen', 'Methane'}, {'H2', 'C1'});
    fluid = initSimpleADIFluid('phases', 'OG', 'n', [1, 1], 'mu', [1e-5, 1e-5]);
    model = HydrogenMixingModel(G, rock, fluid, mixture, ...
        parameters.diffusionCoefficient);
    model.EOSModel = EquationOfStateModel(G, mixture, 'pr');
    model.gravity = [0, 0, 9.80665] * parameters.gravityEnabled;
    model.nonlinearTolerance = 1e-8;
    model = model.validateModel();

    minimum = model.EOSModel.minimumComposition;
    hydrogen = minimum + (1 - 2 * minimum) * (G.cells.centroids(:, 1) >= 50);
    composition = [hydrogen, 1 - hydrogen];
    temperature = 323.15;
    % Separate isothermal hydrostatic columns share the top pressure. This
    % leaves the lateral density imbalance that initiates gravity exchange.
    pressure = repmat(4e6, G.cells.num, 1);
    for iteration = 1:8
        trial = initCompositionalState(model, pressure, temperature, ...
            [0, 1], composition);
        density = model.getProp(trial, 'Density');
        gasDensity = value(density{model.getVaporIndex()});
        pressure = 4e6 + gasDensity .* model.gravity(3) .* ...
            (G.cells.centroids(:, 3) - 400);
    end
    state0 = initCompositionalState(model, pressure, temperature, ...
        [0, 1], composition);
    state0 = model.validateState(state0);
    lastTime = parameters.durationDays * day;
    firstTime = min(0.1 * day, lastTime / parameters.outputCount);
    times = exp(linspace(log(firstTime), log(lastTime), ...
        parameters.outputCount)).';
    if parameters.outputCount == 1
        times = lastTime;
    end
    schedule = simpleSchedule(diff([0; times]));
end

function valid = validGrid(value)
    valid = isnumeric(value) && isequal(size(value), [1, 2]) && ...
        all(isfinite(value)) && all(value >= 2) && ...
        all(mod(value, 2) == 0);
end

function valid = positiveScalar(value)
    valid = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
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
