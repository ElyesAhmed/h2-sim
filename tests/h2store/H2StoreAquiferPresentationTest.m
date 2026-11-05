classdef H2StoreAquiferPresentationTest < matlab.unittest.TestCase
    % Presentation contracts using synthetic states, not numerical regressions.
    properties (Access = private)
        result
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
                'bhp', 4e6)}, count, 1)});
        end

    end
    methods (Test)

        function inactiveWellValuesAreOmitted(test)
            data = aquiferPresentationData(test.result);
            shut = strcmp(data.stages, 'shut');
            test.verifyTrue(any(shut));
            test.verifyEqual(data.rate(shut), zeros(nnz(shut), 1));
            test.verifyTrue(all(isnan(data.bhp(shut))));
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
            test.verifyEqual(figures(1).UserData.saturationLimits, ...
                [0, data.saturationMaximum]);
            test.verifyEqual(figures(3).UserData.dissolvedSurfaceM3, data.dissolved(2:end));
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
