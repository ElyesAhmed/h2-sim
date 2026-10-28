classdef H2StoreBoundaryTest < matlab.unittest.TestCase
    %H2STOREBOUNDARYTEST Aquifer pressure, composition and face selection.
    properties (TestParameter)
        acceleration = {[0, 0, 9.81], [3, 4, 0], [0, 0, 0]}
    end
    methods (TestMethodSetup)
        function preserveGravity(test)
            original = gravity;
            test.addTeardown(@() gravity(original));
            gravity reset on;
        end
    end
    methods (Test)
        function hydrostatic2D(test, acceleration)
            gravity(acceleration);
            [G, fluid, options] = makeInputs([4, 3], [50, 30]);
            bc = makeAquifer2DBoundaryConditions(G, fluid, options);
            faces = expectedFaces(G);
            expected = options.initPres + 3e5 - ...
                fluid.rhoOS*norm(acceleration)*G.faces.centroids(faces, 2);
            test.verifyEqual(bc.face, faces);
            test.verifyEqual(bc.value, expected, 'AbsTol', 1e-9);
            test.verifyEqual(bc.type, repmat({'pressure'}, 1, numel(faces)));
            test.verifyEqual(bc.sat, repmat(options.initSat, numel(faces), 1));
            test.verifyEqual(numel(faces), 2*G.cartDims(2));
        end
        function gravity3D(test)
            gravityVector = [1, -2, 3];
            gravity(gravityVector);
            [G, fluid, options] = makeInputs([2, 3, 2], [50, 30, 20]);
            bc = makeAquifer2DBoundaryConditions(G, fluid, options);
            faces = expectedFaces(G);
            xyz = G.faces.centroids(faces, :);
            expected = options.initPres + 3e5 + fluid.rhoOS * ...
                (xyz(:, 1) - 2*xyz(:, 2) + 3*xyz(:, 3));
            test.verifyEqual(bc.face, faces);
            test.verifyEqual(bc.value, expected, 'AbsTol', 1e-9);
            test.verifyEqual(numel(faces), 2*prod(G.cartDims(2:3)));
        end
        function pressureAndComposition(test)
            [G, fluid, options] = makeInputs([2, 2], [50, 20]);
            before = makeAquifer2DBoundaryConditions(G, fluid, options);
            options.initPres = options.initPres + 2e5;
            options.initSat = [0.8, 0.2];
            after = makeAquifer2DBoundaryConditions(G, fluid, options);
            test.verifyEqual(after.value - before.value, ...
                repmat(2e5, numel(after.face), 1), 'AbsTol', 1e-9);
            test.verifyEqual(after.sat, repmat([0.8, 0.2], numel(after.face), 1));
            test.verifyEqual(after.face, before.face);
        end
        function leavesGravityUnchanged(test)
            gravity([3, 4, 5]);
            before = gravity;
            [G, fluid, options] = makeInputs([2, 2], [50, 20]);
            makeAquifer2DBoundaryConditions(G, fluid, options);
            test.verifyEqual(gravity, before);
        end
    end
end

function [G, fluid, options] = makeInputs(dimensions, lengths)
    G = computeGeometry(cartGrid(dimensions, lengths));
    fluid.rhoOS = 998;
    options = struct('initPres', 37e5, 'initSat', [1, 0]);
end

function faces = expectedFaces(G)
    x = G.faces.centroids(:, 1);
    faces = [find(x == 0); find(x == 50)];
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
