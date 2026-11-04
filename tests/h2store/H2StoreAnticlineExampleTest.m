classdef H2StoreAnticlineExampleTest < matlab.unittest.TestCase
    % Geometry, operations, hydrogen conservation and rendering of the small case.
    properties (Access = private)
        storageCase
    end
    methods (TestClassSetup)

        function runSmallStorageCycle(test)
            test.storageCase = exampleHydrogenAnticline( ...
                'horizontalCells', [9, 9], 'buildupDays', 90, ...
                'shutInDays', 20, 'numCycles', 1);
        end

    end
    methods (Test)

        function fourLayersAndCrestCompletion(test)
            [model, state, schedule, config] = setupHydrogenAnticline( ...
                'horizontalCells', [5, 7]);
            region = model.rock.regions.saturation;
            test.verifyEqual(model.G.cells.num, 5 * 7 * 9);
            test.verifyGreaterThan(model.G.cells.volumes, 0);
            for layer = 1:4
                test.verifyEqual(model.rock.poro(region == layer), ...
                    config.layerPorosity(layer) * ones(nnz(region == layer), 1));
                test.verifyEqual(model.rock.perm(region == layer), ...
                    config.layerPermeabilityM2(layer) * ones(nnz(region == layer), 1));
            end
            cells = schedule.control(1).W.cells;
            test.verifyNumElements(cells, 4);
            test.verifyEqual(region(cells), 3 * ones(4, 1));
            test.verifyEqual(model.G.cells.centroids(cells, 1:2), ...
                2500 * ones(4, 2), 'AbsTol', 1e-8);
            test.verifyEqual(state.s(:, 2), zeros(model.G.cells.num, 1));
        end

        function scheduleHasExactPublishedStageTotals(test)
            [~, ~, schedule] = setupHydrogenAnticline('horizontalCells', [3, 3]);
            dt = schedule.step.val / day;
            control = schedule.step.control;
            test.verifyEqual(sum(dt), 525, 'AbsTol', 1e-10);
            test.verifyEqual(sum(dt(control == 1)), 365, 'AbsTol', 1e-10);
            test.verifyEqual(sum(dt(control == 2)), 90, 'AbsTol', 1e-10);
            test.verifyEqual(sum(dt(control == 3)), 35, 'AbsTol', 1e-10);
            test.verifyEqual(sum(dt(control == 4)), 35, 'AbsTol', 1e-10);
            test.verifyGreaterThan(dt, 0);
            test.verifyFalse(schedule.control(2).W.status);
            test.verifyEqual(schedule.control(3).W.type, 'grat');
            test.verifyEqual(schedule.control(3).W.val * day, -400000);
        end

        function capillaryRegionsAndGasCompressibility(test)
            [model, ~, ~, config] = setupHydrogenAnticline('horizontalCells', [3, 3]);
            for layer = 1:4
                pressure = model.fluid.pcOG{layer}([0; 0.4]);
                test.verifyEqual(pressure(1), config.capillaryEntryPa(layer));
                test.verifyGreaterThan(pressure(2), pressure(1));
            end
            test.verifyGreaterThan(model.fluid.bG(8e6), model.fluid.bG(4e6));
            test.verifyEqual(model.fluid.krG([0; 0.1]), [0; 0]);
            test.verifyEqual(model.fluid.krO(1), 0.8, 'AbsTol', 1e-14);
        end

        function inventoryMatchesIndependentOperationalVolume(test)
            result = test.storageCase;
            stage = result.schedule.step.control;
            inventory = result.diagnostics.hydrogenSurfaceVolumeM3;
            build = find(stage == 1, 1, 'last') + 1;
            shut = find(stage == 2, 1, 'last') + 1;
            withdrawal = find(stage == 3, 1, 'last') + 1;
            expected = 90 * 200000;
            test.verifyEqual(inventory(build), expected, 'RelTol', 1e-5);
            test.verifyEqual(inventory(shut), expected, 'RelTol', 1e-5);
            test.verifyEqual(inventory(withdrawal), expected - 7 * 400000, 'RelTol', 1e-5);
            test.verifyEqual(inventory(end), expected, 'RelTol', 1e-5);
            test.verifyLessThan(result.diagnostics.maximumRelativeHydrogenBalanceError, 1e-5);
            test.verifyGreaterThan(max(result.diagnostics.maximumGasSaturation), 0.1);
        end

        function activeWellSignsAndPublicInventoryAgree(test)
            result = test.storageCase;
            stage = result.schedule.step.control;
            rates = result.diagnostics.wellGasSurfaceRateM3PerSecond;
            test.verifyGreaterThan(rates(stage == 1 | stage == 4), 0);
            test.verifyLessThan(rates(stage == 3), 0);
            test.verifyEqual(rates(stage == 2), zeros(nnz(stage == 2), 1));
            states = [{result.state0}; result.states(:)];
            total = computeGasVolumes(result.model, states, 1:numel(states));
            actual = cellfun(@sum, total);
            test.verifyEqual(actual, result.diagnostics.hydrogenSurfaceVolumeM3, ...
                'RelTol', 1e-12, 'AbsTol', 1e-8);
        end

        function rejectsInvalidResolutionAndCycleCounts(test)
            test.verifyError(@() setupHydrogenAnticline('horizontalCells', [4, 5]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            test.verifyError(@() setupHydrogenAnticline('numCycles', -1), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function exportsActualStateFrames(test)
            folder = tempname;
            cleanup = onCleanup(@() rmdir(folder, 's'));
            result = test.storageCase;
            files = animateHydrogenAnticline(result, folder, ...
                'writeVideo', false, 'maxFrames', 20);
            frames = imfinfo(files.gif);
            test.verifyNumElements(frames, numel(files.sourceStateIndices));
            test.verifyLessThanOrEqual(numel(frames), 20);
            endpoints = find([diff(result.schedule.step.control) ~= 0; true]) + 1;
            test.verifyTrue(all(ismember(endpoints, files.sourceStateIndices)));
            region = result.model.rock.regions.saturation;
            test.verifyEqual(unique(region(files.sectionCellIndices)), (1:4).');
            test.verifyNumElements(files.sectionCellIndices, ...
                result.model.G.cartDims(1) * result.model.G.cartDims(3));
            test.verifyTrue(isfile(files.poster));
            test.verifyEmpty(files.video);
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
