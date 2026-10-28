classdef H2StoreDomeTest < matlab.unittest.TestCase
    % H2STOREDOMETEST Dome grid geometry, layers, rock and completion selection.
    properties (TestParameter)
        matches = {0, 1}
    end
    methods (Test)

        function gridLayers(test)
            [G, layers] = makeDomeAquiferGrid([3, 3]);
            test.verifyEqual(G.cartDims, [3, 3, 32]);
            test.verifyEqual(G.cells.num, 288);
            masks = [layers.underrock, layers.bedrock, layers.toprock, ...
                layers.caprock, layers.aquifer];
            test.verifyEqual(sum(masks, 2), ones(288, 1));
            test.verifyEqual(sum(masks, 1), 9 * [8, 4, 8, 5, 7]);
            test.verifyGreaterThan(G.cells.volumes, 0);
            test.verifyEqual(sort(G.cells.indexMap), (1:288)');
        end

        function rockProperties(test)
            [G, layers] = makeDomeAquiferGrid([3, 3]);
            rock = makeDomeAquiferRock(G, layers);
            names = {'aquifer', 'underrock', 'bedrock', 'caprock', 'toprock'};
            porosity = [0.25, 0.15, 0.1, 0.1, 0.15];
            regions = [1, 2, 2, 3, 3];
            permeability = [1000, 1000, 100; 1e-3, 1e-3, 1e-3; ...
                1e-2, 1e-2, 1e-2; 1e-4, 1e-4, 1e-4; 1e-3, 1e-3, 1e-3] * milli * darcy;
            for k = 1:numel(names)
                mask = layers.(names{k});
                count = nnz(mask);
                test.verifyEqual(rock.poro(mask), repmat(porosity(k), count, 1));
                test.verifyEqual(rock.regions.saturation(mask), repmat(regions(k), count, 1));
                test.verifyEqual(rock.perm(mask, :), repmat(permeability(k, :), count, 1));
            end
        end

        function completionOrdering(test)
            G.cells.centroids = [2500, 2500, -590; 2500, 2500, -580; ...
                2500, 2500, -570; 2500, 2500, -600; 2501, 2500, -550];
            test.verifyEqual(findDomeAquiferWellCells(G), [1; 2]);
        end

        function missingCompletions(test, matches)
            G.cells.centroids = repmat([2500, 2500, -590], matches, 1);
            test.verifyError(@() findDomeAquiferWellCells(G), ...
                'h2sim:h2store:DomeWellCells');
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
