classdef H2StoreInitializationTest < matlab.unittest.TestCase
    %H2STOREINITIALIZATIONTEST Layer properties and uniform aquifer state.
    properties (TestParameter)
        saturation = {[1, 0], [0.7, 0.3]}
    end
    methods (Test)
        function layerProperties(test)
            G.cells.centroids = [25, 20; 25, 35; 25, 2; 25, 5];
            G.cells.num = 4;
            G.griddim = 2;
            rock = makeAquifer2DRock(G);
            test.verifyEqual(rock.regions.saturation, [1; 3; 2; 1]);
            test.verifyEqual(rock.poro, [0.25; 0.1; 0.1; 0.25]);
            expected = [10; 1e-4; 1e-2; 10]*milli*darcy;
            test.verifyEqual(rock.perm, repmat(expected, 1, 2));
        end
        function cartesianLayers(test)
            G = computeGeometry(cartGrid([10, 10], [50, 50]));
            rock = makeAquifer2DRock(G);
            x = G.cells.centroids(:, 1);
            y = G.cells.centroids(:, 2);
            expected = ones(G.cells.num, 1);
            expected(y < 5) = 2;
            expected(y > 25.1 + 5*sin(pi*x/50)) = 3;
            test.verifyEqual(rock.regions.saturation, expected);
            test.verifyEqual(unique(expected), [1; 2; 3]);
        end
        function uniformState(test, saturation)
            G = computeGeometry(cartGrid([2, 2], [50, 50]));
            rock = makeRock(G, 10*milli*darcy, 0.25);
            fluid = initSimpleADIFluid('phases', 'OG', 'mu', [1, 0.1], ...
                'rho', [1000, 1], 'n', [2, 2]);
            model = GenericBlackOilModel(G, rock, fluid, ...
                'water', false, 'disgas', true);
            W = addWell([], G, rock, 1, 'Name', 'Storage', ...
                'Type', 'rate', 'Val', 1, 'Compi', [0, 1]);
            options = struct('initPres', 37e5, 'initSat', saturation, 'initTemp', 333);
            state = makeAquifer2DInitialState(model, W, options);
            test.verifyEqual(state.pressure, repmat(37e5, G.cells.num, 1));
            test.verifyEqual(state.s, repmat(saturation, G.cells.num, 1));
            test.verifyEqual(state.rs, zeros(G.cells.num, 1));
            test.verifyEqual(state.wellSol.bhp, 37e5);
            test.verifyEqual(state.wellSol.name, 'Storage');
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
