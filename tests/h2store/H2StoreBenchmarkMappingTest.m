classdef H2StoreBenchmarkMappingTest < matlab.unittest.TestCase
    %H2STOREBENCHMARKMAPPINGTEST Active-cell properties and completion identity.
    properties (TestParameter)
        inactive = {1, [1, 2, 6]}
    end
    methods (TestMethodSetup)
        function saveGravity(test)
            saved = gravity;
            test.addTeardown(@() gravity(saved));
        end
    end
    methods (Test)
        function rockMapping(test, inactive)
            deck.GRID = cartesianGrdecl(0:4, 0:2, 0:2);
            ids = (1:prod(deck.GRID.cartDims))';
            deck.GRID.ACTNUM = ones(size(ids));
            deck.GRID.ACTNUM(inactive) = 0;
            deck.GRID.PERMX = ids*milli*darcy;
            deck.GRID.PERMY = 2*ids*milli*darcy;
            deck.GRID.PERMZ = 3*ids*milli*darcy;
            deck.GRID.PORO = 0.1+ids/100;
            deck.REGIONS.SATNUM = mod(ids-1, 3)+1;
            G = processGRDECL(deck.GRID);
            rock = makeBenchmarkRock(G, deck);
            expected = setdiff(ids, inactive(:));
            test.verifyEqual(G.cells.indexMap, expected);
            test.verifyEqual(rock.perm, [expected, 2*expected, 3*expected]*milli*darcy);
            test.verifyEqual(rock.poro, 0.1+expected/100);
            test.verifyEqual(rock.regions.saturation, mod(expected-1, 3)+1);
        end
        function fullSetup(test)
            mrstModule add test-suite;
            deck = makeBenchmarkTestDeck();
            ids = (1:prod(deck.GRID.cartDims))';
            deck.GRID.ACTNUM = ones(size(ids));
            deck.GRID.ACTNUM(1) = 0;
            deck.GRID.PERMX = 100+ids/numel(ids);
            deck.GRID.PERMY = 200+ids/numel(ids);
            deck.GRID.PERMZ = 50+ids/numel(ids);
            deck.GRID.PORO = 0.2+0.1*ids/numel(ids);
            deck.REGIONS.SATNUM = mod(ids-1, 3)+1;
            [~, ~, state, model, schedule] = ...
                modelForUHSModifiedBenchmark(deck, 'chargeOnly', 1);
            converted = convertDeckUnits(deck);
            cells = ids(2:end);
            test.verifyEqual(model.G.cells.indexMap, cells);
            expectedPerm = [converted.GRID.PERMX(cells), ...
                converted.GRID.PERMY(cells), converted.GRID.PERMZ(cells)];
            test.verifyEqual(model.rock.perm, expectedPerm);
            test.verifyEqual(model.rock.poro, deck.GRID.PORO(cells));
            test.verifyEqual(model.rock.regions.saturation, deck.REGIONS.SATNUM(cells));
            regions = handleRegions(model.inputdata, model.G);
            test.verifyEqual(regions.SATNUM, model.rock.regions.saturation);
            expectedCompletions = (5891:3721:43101)';
            for k = 1:numel(schedule.control)
                W = schedule.control(k).W;
                test.verifyEqual(model.G.cells.indexMap(W.cells), expectedCompletions);
            end
            test.verifyNumElements(state.pressure, numel(cells));
        end
        function rejectInactiveCompletion(test)
            mrstModule add test-suite;
            deck = makeBenchmarkTestDeck();
            deck.GRID.ACTNUM = ones(prod(deck.GRID.cartDims), 1);
            deck.GRID.ACTNUM(5891) = 0;
            test.verifyError(@() buildBenchmarkModel(deck), ...
                'h2sim:h2store:InactiveBenchmarkCompletion');
        end
    end
end

function buildBenchmarkModel(deck)
    [~, ~, ~, ~] = modelForUHSModifiedBenchmark(deck, 'chargeOnly', 1);
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
