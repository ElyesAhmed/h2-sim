classdef H2StoreBenchmarkStateTest < matlab.unittest.TestCase
    % H2STOREBENCHMARKSTATETEST Prescribed boundary pressure and initial solution ratios.
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
            options = struct('initPres', 37e5, 'initSat', [0.8, 0.2]);
            bc = makeBenchmarkBoundaryConditions(G, options);
            faces = boundaryFaces(G);
            faces = faces(G.faces.normals(faces, 3) <= 2.48);
            xyz = G.faces.centroids(faces, :);
            gradient = ((xyz(:, 1) - 1140) * acceleration(1) + ...
                (xyz(:, 2) - 1140) * acceleration(2) + ...
                (xyz(:, 3) - 1140) * acceleration(3));
            expected = options.initPres + 998 * gradient;
            test.verifyEqual(bc.face, faces);
            test.verifyEqual(bc.value, expected, 'AbsTol', 1e-9);
            test.verifyEqual(bc.sat, repmat([0.8, 0.2], numel(faces), 1));
            test.verifyEqual(gravity, acceleration);
            test.verifyEqual(bc.type, repmat({'pressure'}, 1, numel(faces)));
        end

        function faceAreaSelection(test)
            G = computeGeometry(cartGrid([2, 3, 2], [2, 3, 20]));
            options = struct('initPres', 37e5, 'initSat', [1, 0]);
            bc = makeBenchmarkBoundaryConditions(G, options);
            test.verifyEqual(bc.face, boundaryFaces(G));
            G = computeGeometry(cartGrid([2, 3, 2], [50, 30, 20]));
            bc = makeBenchmarkBoundaryConditions(G, options);
            exterior = boundaryFaces(G);
            excluded = exterior(G.faces.normals(exterior, 3) > 2.48);
            test.verifyNotEmpty(excluded);
            test.verifyEmpty(intersect(bc.face, excluded));
            downward = exterior(G.faces.normals(exterior, 3) < 0);
            test.verifyTrue(all(ismember(downward, bc.face)));
        end

        function initialSolution(test, wellCount)
            G = computeGeometry(cartGrid([2, 2, 2], [50, 50, 20]));
            rock = makeRock(G, 10 * milli * darcy, 0.25);
            fluid = initSimpleADIFluid('phases', 'OG', 'mu', [1, 0.1], ...
                'rho', [1000, 1], 'n', [2, 2]);
            model = GenericBlackOilModel(G, rock, fluid, ...
                'water', false, 'disgas', true);
            W = [];
            for k = 1:wellCount
                W = addWell(W, G, rock, k, 'Name', sprintf('Storage%d', k), ...
                    'Type', 'rate', 'Val', 1, 'Compi', [0, 1]);
            end
            options = struct('initPres', 37e5, 'initSat', [0.8, 0.2], 'initTemp', 333);
            state = makeBenchmarkInitialState(model, W, options);
            test.verifyEqual(state.pressure, repmat(37e5, G.cells.num, 1));
            test.verifyEqual(state.s, repmat([0.8, 0.2], G.cells.num, 1));
            test.verifyEqual(state.rs, zeros(G.cells.num, 1));
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
