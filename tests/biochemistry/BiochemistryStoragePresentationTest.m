classdef BiochemistryStoragePresentationTest < matlab.unittest.TestCase
    % Saved-state plotting contracts; synthetic histories, not flow regressions.
    properties (Access = private)
        result
    end
    methods (TestMethodSetup)

        function makeHistory(test)
            G = computeGeometry(cartGrid([4, 4], [50, 50]));
            count = G.cells.num;
            region = ones(count, 1);
            region(G.cells.centroids(:, 2) < 10) = 2;
            region(G.cells.centroids(:, 2) > 30) = 3;
            model = struct('G', G, 'bacteriamodel', true, ...
                'rock', struct('regions', struct('saturation', region)), ...
                'compFluid', struct('molarMass', [0.018, 0.002, 0.044, 0.016]));
            state = struct('s', repmat([0.9, 0.1], count, 1), ...
                'y', repmat([0, 0.1, 0.1, 0.8], count, 1), ...
                'nbact', 15 * ones(count, 3));
            initial = state;
            names = {'cushion', 'shut', 'charge', 'shut', 'discharge'};
            controls = repmat(struct('W', struct('stage', '', 'status', true, ...
                'type', 'rate', 'val', 1, 'cells', 6)), 1, 5);
            states = cell(5, 1);
            wells = cell(5, 1);
            for k = 1:5
                controls(k).W.stage = names{k};
                controls(k).W.status = ~strcmp(names{k}, 'shut');
                state.nbact = repmat(15 + k * [1, 2, 3], count, 1);
                state.y(:, 2) = k / 10;
                state.y(:, 4) = 0.9 - k / 10;
                state.cumulativeH2ConsumptionMoles = repmat(k * [1, 2, 3], count, 1);
                states{k} = state;
                rate = 0.01;
                if k == 5
                    rate = -rate;
                end
                wells{k} = struct('H2', rate, 'CO2', 0.02, 'C1', 0.03, ...
                    'bhp', 4e6, 'status', true);
            end
            schedule = struct('control', controls, 'step', ...
                struct('val', [120; 30; 30; 10; 30] * day, 'control', (1:5).'));
            test.result = struct('name', 'bacterial', 'complete', true, ...
                'model', model, 'state0', initial, 'states', {states}, ...
                'wellSols', {wells}, 'schedule', schedule);
        end

    end
    methods (Test)

        function omitsStaleInactiveWellValues(test)
            data = biochemistryStoragePresentationData(test.result);
            test.verifyEqual(data.massRate([2, 4], :), zeros(2, 3));
            test.verifyTrue(all(isnan(data.bhp([2, 4]))));
            test.verifyEqual(data.massRate(5, 1), -0.01 * day);
        end

        function consumptionUsesPositiveInjectionOnly(test)
            data = biochemistryStoragePresentationData(test.result);
            expectedInjection = 150 * day * 0.01 / 0.002;
            test.verifyEqual(data.injectedMoles(end), expectedInjection, 'RelTol', 1e-12);
            test.verifyEqual(data.percent(end, :), ...
                100 * 16 * 5 * [1, 2, 3] / expectedInjection, 'RelTol', 1e-12);
            test.verifyEqual(data.biomassLimits, [0, 20; 0, 25; 0, 30]);
        end

        function figuresShareAnimationLimitsAndIntervalRates(test)
            figures = plotCompositionalBacterial2DThreeReactions(test.result);
            cleanup = onCleanup(@() close(figures));
            data = biochemistryStoragePresentationData(test.result);
            line = findobj(figures(2), 'Tag', 'bacterial-rate-1');
            test.verifyEqual(line.XData(:), data.times);
            test.verifyEqual(line.YData(:), [data.massRate(:, 1); data.massRate(end, 1)]);
            test.verifyEqual(figures(3).UserData.biomassLimits, data.biomassLimits);
            test.verifyEqual(figures(4).UserData.consumptionPercent, data.percent(2:end, :));
        end

        function gifKeepsEveryStageAndPoster(test)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            files = animateCompositionalBacterial2DThreeReactions(test.result, folder, ...
                'writeVideo', false, 'maxFrames', 6);
            test.verifyEqual(files.sourceStateIndices, (1:6).');
            test.verifyEqual(numel(imfinfo(files.gif)), 6);
            test.verifyTrue(isfile(files.poster));
            test.verifyEmpty(files.video);
            test.verifyError(@() animateCompositionalBacterial2DThreeReactions( ...
                test.result, folder, 'writeVideo', false, 'maxFrames', 2), ...
                'H2sim:BiochemistryAnimationFrames');
        end

        function rejectsIncompleteAndMissingReactionHistory(test)
            result = test.result;
            result.complete = false;
            test.verifyError(@() biochemistryStoragePresentationData(result), ...
                'H2sim:BiochemistryIncomplete');
            result = test.result;
            result.states{1} = rmfield(result.states{1}, 'cumulativeH2ConsumptionMoles');
            test.verifyError(@() biochemistryStoragePresentationData(result), ...
                'H2sim:BiochemistryConsumptionMissing');
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
