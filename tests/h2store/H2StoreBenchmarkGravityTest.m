classdef H2StoreBenchmarkGravityTest < matlab.unittest.TestCase
    %H2STOREBENCHMARKGRAVITYTEST Boundary and model accelerations agree at setup.
    properties (TestParameter)
        incomingGravity = {[0, 0, 0], [2, -1, 3], [0, 0, 9.80665]}
    end
    properties
        deck
    end
    methods (TestClassSetup)
        function prepareDeck(test)
            mrstModule add test-suite;
            test.deck = makeBenchmarkTestDeck();
        end
    end
    methods (TestMethodSetup)
        function saveGravity(test)
            saved = gravity;
            test.addTeardown(@() gravity(saved));
        end
    end
    methods (Test)
        function fullSetup(test, incomingGravity)
            gravity reset on;
            expectedGravity = gravity;
            gravity(incomingGravity);
            [~, options, state, model, schedule] = ...
                modelForUHSModifiedBenchmark(test.deck, 'chargeOnly', 1);
            test.verifyEqual(model.gravity, expectedGravity);
            test.verifyEqual(gravity, expectedGravity);
            G = model.G;
            faces = boundaryFaces(G);
            faces = faces(~(G.faces.normals(faces, 3) > 2.48));
            expectedPressure = options.initPres + ...
                998*(G.faces.centroids(faces, 3) - 1140)*expectedGravity(3);
            for k = 1:numel(schedule.control)
                bc = schedule.control(k).bc;
                test.verifyEqual(bc.face, faces);
                test.verifyEqual(bc.value, expectedPressure, 'AbsTol', 1e-9);
            end
            test.verifyEqual(state.pressure, ...
                repmat(options.initPres, G.cells.num, 1));
        end
        function metadataPreservesGravity(test)
            incoming = [2, -1, 3];
            gravity(incoming);
            [~, options] = modelForUHSModifiedBenchmark(test.deck);
            test.verifyTrue(options.use_bc);
            test.verifyEqual(gravity, incoming);
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
