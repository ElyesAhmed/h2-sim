classdef H2StoreAquiferPresentationTest < matlab.unittest.TestCase
    % Presentation contracts using synthetic states, not numerical regressions.
    properties (Access = private)
        result
    end
    properties (TestParameter)
        gridSpacing = struct('coarse', [8, 8], 'teaching', [2, 2], ...
            'original', [0.5, 0.5]);
    end
    methods (TestClassSetup)

        function prepareSavedHistory(test)
            mrstModule add ad-core ad-props ad-blackoil deckformat upr test-suite spe10;
            deckFile = fullfile(fileparts(which('exampleBlackOilAquifer2D')), ...
                'data', 'Aquifer2D', 'H2STORAGE_RS.DATA');
            [~, setup, initial, model, schedule] = modelForSimple2DAquifer( ...
                readEclipseDeck(deckFile), 'gridSpacing', [8, 8], 'numCycles', 1);
            for k = 1:numel(schedule.control)
                schedule.control(k).W.stage = schedule.control(k).W.name;
            end
            state = initial;
            state.s(:, :) = repmat([0.9, 0.1], model.G.cells.num, 1);
            count = numel(schedule.step.val);
            test.result = struct('model', model, 'state0', initial, ...
                'states', {repmat({state}, count, 1)}, 'schedule', schedule, ...
                'setup', setup, 'wellSols', {repmat({struct('qGs', 1, ...
                'bhp', 4e6, 'cdp', 0)}, count, 1)});
        end

    end
    methods (Test)

        function rockInterfacesFollowGridFaces(test, gridSpacing)
            deckFile = fullfile(fileparts(which('exampleBlackOilAquifer2D')), ...
                'data', 'Aquifer2D', 'H2STORAGE_RS.DATA');
            [~, ~, ~, model, schedule] = modelForSimple2DAquifer( ...
                readEclipseDeck(deckFile), 'gridSpacing', gridSpacing, 'numCycles', 1);
            G = model.G;
            region = model.rock.regions.saturation;
            interior = find(all(G.faces.neighbors > 0, 2));
            adjacent = region(G.faces.neighbors(interior, :));
            caprock = interior(any(adjacent == 3, 2) & any(adjacent == 1, 2));
            bedrock = interior(any(adjacent == 2, 2) & any(adjacent == 1, 2));
            nodeFaces = rldecode((1:G.faces.num)', diff(G.faces.nodePos));
            top = G.nodes.coords(G.faces.nodes(ismember(nodeFaces, caprock)), :);
            bottom = G.nodes.coords(G.faces.nodes(ismember(nodeFaces, bedrock)), :);
            x = linspace(0, 50, 100);
            expected = interp1(x, 25.1 + 5 * sin(pi * x / 50), top(:, 1));
            test.verifyNotEmpty(top);
            test.verifyNotEmpty(bottom);
            % clippedPebi2D rounds grid vertices to micrometres.
            test.verifyEqual(top(:, 2), expected, 'AbsTol', 1e-6);
            test.verifyEqual(bottom(:, 2), 5 * ones(size(bottom, 1), 1), 'AbsTol', 1e-8);
            test.verifyEqual([min(top(:, 1)), max(top(:, 1))], [0, 50], 'AbsTol', 1e-8);
            test.verifyEqual([min(bottom(:, 1)), max(bottom(:, 1))], [0, 50], 'AbsTol', 1e-8);
            test.verifyGreaterThan(min(G.cells.volumes), 0);
            test.verifyEqual(sum(G.cells.volumes), 2500, 'AbsTol', 1e-6);
            test.verifyEqual(region(schedule.control(1).W.cells), ...
                ones(numel(schedule.control(1).W.cells), 1));
        end

        function shutInBhpUsesZeroDrawdownBalance(test)
            data = aquiferPresentationData(test.result);
            shut = strcmp(data.stages, 'shut');
            test.verifyTrue(any(shut));
            test.verifyEqual(data.rate(shut), zeros(nnz(shut), 1));
            well = test.result.schedule.control(1).W;
            expected = test.result.states{1}.pressure(well.cells) / barsa;
            test.verifyEqual(data.shutInBhp(shut), ...
                repmat(expected, nnz(shut), 1), 'AbsTol', 1e-10);
            test.verifyTrue(all(isnan(data.shutInBhp(~shut))));
            test.verifyTrue(all(isfinite(data.bhp)));
            test.verifyEqual(data.bhp(~shut), 40 * ones(nnz(~shut), 1), 'AbsTol', 1e-10);
            test.verifyEqual(data.rate(~shut), day * ones(nnz(~shut), 1));
            test.verifyEqual(data.total, data.free + data.dissolved);
        end

        function plotsUseSavedValuesAndFixedLimits(test)
            figures = plotBlackOilAquifer2D(test.result);
            cleanup = onCleanup(@() close(figures));
            data = aquiferPresentationData(test.result);
            line = findobj(figures(2), 'Tag', 'aquifer-well-rate');
            test.verifyEqual(line.XData(:), data.times);
            test.verifyEqual(line.YData(:), [data.rate; data.rate(end)]);
            pressure = findobj(figures(2), 'Tag', 'aquifer-pressure');
            test.verifyEqual(pressure.YData(:), data.bhp, 'AbsTol', 1e-10);
            test.verifyEqual(figures(1).UserData.saturationLimits, ...
                [0, data.saturationMaximum]);
            test.verifyEqual(figures(3).UserData.dissolvedSurfaceM3, data.dissolved(2:end));
        end

        function shutInUsesCurrentStateNotStaleWellBhp(test)
            result = test.result;
            original = aquiferPresentationData(result);
            index = find(strcmp(original.stages, 'shut'), 1);
            result.states{index}.pressure(:) = 38 * barsa;
            result.wellSols{index}.bhp = 99 * barsa;
            data = aquiferPresentationData(result);
            test.verifyEqual(data.bhp(index), 38, 'AbsTol', 1e-10);
            test.verifyEqual(data.shutInBhp(index), 38, 'AbsTol', 1e-10);
        end

        function nonzeroConnectionCorrectionIsRejected(test)
            result = test.result;
            data = aquiferPresentationData(result);
            index = find(strcmp(data.stages, 'shut'), 1);
            result.wellSols{index}.cdp = 100;
            test.verifyError(@() aquiferPresentationData(result), 'H2sim:AquiferShutInBhp');
        end

        function multipleCompletionsAreRejected(test)
            result = test.result;
            data = aquiferPresentationData(result);
            index = find(strcmp(data.stages, 'shut'), 1);
            control = result.schedule.step.control(index);
            result.schedule.control(control).W.cells = [1; 2];
            test.verifyError(@() aquiferPresentationData(result), 'H2sim:AquiferShutInBhp');
        end

        function gifRetainsEveryStageEndpoint(test)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            data = aquiferPresentationData(test.result);
            mandatory = unique([1; data.endpoints]);
            files = animateBlackOilAquifer2D(test.result, folder, ...
                'writeVideo', false, 'maxFrames', numel(mandatory));
            test.verifyEqual(files.sourceStateIndices, mandatory);
            test.verifyEqual(numel(imfinfo(files.gif)), numel(mandatory));
            test.verifyTrue(isfile(files.poster));
            test.verifyEmpty(files.video);
            test.verifyError(@() animateBlackOilAquifer2D(test.result, folder, ...
                'writeVideo', false, 'maxFrames', 2), 'H2sim:AquiferAnimationFrames');
        end

        function sharedPaletteMatchesReference(test)
            style = h2simStoragePlotStyle();
            test.verifySize(style.saturation, [256, 3]);
            test.verifyEqual(style.saturation([1, end], :), ...
                [0.12, 0.22, 0.35; 1, 0.65, 0.18], 'AbsTol', 1e-14);
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
