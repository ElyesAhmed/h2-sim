classdef H2StoreDomeMappingTest < matlab.unittest.TestCase
    % H2STOREDOMEMAPPINGTEST Actual dome setup retains logical cell identity.
    properties
        model
    end
    methods (TestClassSetup)

        function buildDome(test)
            originalGravity = gravity;
            test.addTeardown(@() gravity(originalGravity));
            mrstModule add test-suite;
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            file = fullfile(root, 'h2-store', 'examples', 'data', ...
                'Aquifer2D', 'H2STORAGE_RS.DATA');
            deck = readEclipseDeck(file);
            [~, ~, ~, test.model] = modelForDome3DAquifer(deck, 'numCycles', 1);
        end

    end
    methods (Test)

        function logicalCellIdentity(test)
            G = test.model.G;
            test.verifyEqual(G.cells.indexMap, (1:G.cells.num)');
            test.verifyEqual(numel(unique(G.cells.indexMap)), G.cells.num);
        end

        function regionLookup(test)
            model = test.model;
            regions = handleRegions(model.inputdata, model.G);
            test.verifyEqual(regions.SATNUM, model.rock.regions.saturation);
            test.verifyEqual(unique(regions.SATNUM), [1; 2; 3]);
        end

        function deckRockCorrespondence(test)
            model = test.model;
            rock = initEclipseRock(model.inputdata);
            rock = compressRock(rock, model.G.cells.indexMap);
            test.verifyEqual(rock.poro, model.rock.poro);
            test.verifyEqual(rock.perm, model.rock.perm);
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
