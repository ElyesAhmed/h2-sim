classdef H2StoreDomeStateTest < matlab.unittest.TestCase
    % H2STOREDOMESTATETEST Prescribed boundary pressure and initial solution ratios.
    properties (TestParameter)
        acceleration = {[0, 0, -9.81], [2, -1, 3], [0, 0, 0]}
        wellCount = {1, 2}
    end
    methods (TestMethodSetup)

        function saveGravity(test)
            saved = gravity;
            test.addTeardown(@() gravity(saved));
            gravity reset on;
        end

    end
    methods (Test)

        function prescribed3DPressure(test, acceleration)
            gravity(acceleration);
            G = computeGeometry(cartGrid([2, 3, 2], [50, 30, 20]));
            G.faces.centroids(:, 3) = G.faces.centroids(:, 3) - 700;
            fluid.rhoOS = 998;
            options = struct('initPres', 37e5, 'initSat', [0.8, 0.2]);
            bc = makeDomeAquiferBoundaryConditions(G, fluid, options);
            faces = find(G.faces.centroids(:, 1) == 0);
            xyz = G.faces.centroids(faces, :);
            gradient = ((xyz(:, 1) + 100) * acceleration(1) + ...
                (xyz(:, 2) + 100) * acceleration(2) + ...
                (xyz(:, 3) + 100) * acceleration(3)) / 15;
            expected = options.initPres + 5e4 - 998 * gradient;
            test.verifyEqual(bc.face, faces);
            test.verifyEqual(bc.value, expected, 'AbsTol', 1e-9);
            test.verifyEqual(bc.sat, repmat([0.8, 0.2], numel(faces), 1));
            test.verifyEqual(bc.type, repmat({'pressure'}, 1, numel(faces)));
        end

        function planarPressure(test)
            gravity([3, 4, 0]);
            G = computeGeometry(cartGrid([2, 3], [50, 30]));
            fluid.rhoOS = 1000;
            options = struct('initPres', 37e5, 'initSat', [1, 0]);
            bc = makeDomeAquiferBoundaryConditions(G, fluid, options);
            y = G.faces.centroids(bc.face, 2);
            expected = 37e5 + 5e4 + 1000 * (y + 100) * 5 / 15;
            test.verifyEqual(bc.value, expected, 'AbsTol', 1e-9);
            test.verifyEqual(gravity, [3, 4, 0]);
        end

        function initialSolution(test, wellCount)
            G = computeGeometry(cartGrid([2, 2, 2], [50, 50, 20]));
            rock = makeRock(G, 10 * milli * darcy, 0.25);
            fluid = initSimpleADIFluid('phases', 'OG', 'mu', [1, 0.1], ...
                'rho', [1000, 1], 'n', [2, 2]);
            model = GenericBlackOilModel(G, rock, fluid, ...
                'water', false, 'disgas', true, 'vapoil', true);
            W = [];
            for k = 1:wellCount
                W = addWell(W, G, rock, k, 'Name', sprintf('Storage%d', k), ...
                    'Type', 'rate', 'Val', 1, 'Compi', [0, 1]);
            end
            options = struct('initPres', 37e5, 'initSat', [0.8, 0.2], 'initTemp', 333);
            state = makeDomeAquiferInitialState(model, W, options);
            test.verifyEqual(state.pressure, repmat(37e5, G.cells.num, 1));
            test.verifyEqual(state.s, repmat([0.8, 0.2], G.cells.num, 1));
            test.verifyEqual(state.rs, zeros(G.cells.num, 1));
            test.verifyEqual(state.rv, zeros(G.cells.num, 1));
            test.verifyEqual([state.wellSol.bhp], repmat(37e5, 1, wellCount));
            test.verifyEqual({state.wellSol.name}, {W.name});
            test.verifyFalse(isfield(state, 'T'));
        end

    end
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
