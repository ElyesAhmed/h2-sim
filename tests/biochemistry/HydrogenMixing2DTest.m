classdef HydrogenMixing2DTest < matlab.unittest.TestCase
    % Closed-domain transport, conservation and rendering of the mixing case.
    methods (Test)

        function setupUsesPublishedGeometryAndSealedSchedule(test)
            [model, initial, schedule, parameters] = setupHydrogenMixing2D( ...
                'gridSize', [4, 4], 'durationDays', 3, 'outputCount', 3);
            test.verifyEqual(model.G.cells.num, 16);
            test.verifyEqual(model.rock.poro, 0.1 * ones(16, 1));
            test.verifyEqual(model.rock.perm, 1e-14 * ones(16, 1));
            test.verifyEqual(model.gravity, [0, 0, 9.80665]);
            test.verifyEqual(sum(schedule.step.val), 3 * day, 'RelTol', 1e-12);
            test.verifyEmpty(schedule.control.W);
            test.verifyEmpty(schedule.control.bc);
            test.verifyClass(model, 'HydrogenMixingModel');
            test.verifyEqual(parameters.diffusionCoefficient, 7.26e-5);
            right = model.G.cells.centroids(:, 1) > 50;
            test.verifyGreaterThan(initial.components(right, 1), 0.999);
            test.verifyLessThan(initial.components(~right, 1), 1e-6);
        end

        function noGravityOrDiffusionPreservesInitialState(test)
            result = exampleHydrogenMixing2D('gridSize', [4, 4], ...
                'durationDays', 1, 'outputCount', 2, ...
                'gravityEnabled', false, 'diffusionCoefficient', 0);
            test.verifyEqual(result.states{end}.components, ...
                result.state0.components, 'AbsTol', 1e-10);
            test.verifyEqual(result.states{end}.pressure, ...
                result.state0.pressure, 'AbsTol', 0.01);
        end

        function diffusionMixesAndConservesBothSpecies(test)
            result = exampleHydrogenMixing2D('gridSize', [6, 6], ...
                'durationDays', 30, 'outputCount', 6, 'gravityEnabled', false);
            left = result.model.G.cells.centroids(:, 1) < 50;
            test.verifyGreaterThan(mean(result.states{end}.components(left, 1)), ...
                mean(result.state0.components(left, 1)) + 0.01);
            test.verifyLessThan(result.diagnostics.maximumRelativeMassError, ...
                [1e-5, 1e-5]);
            verifyIndependentInventory(test, result);
        end

        function gravityMovesHydrogenUpward(test)
            result = exampleHydrogenMixing2D('gridSize', [8, 8], ...
                'durationDays', 365, 'outputCount', 12);
            depth = result.diagnostics.hydrogenMeanDepthM;
            test.verifyLessThan(depth(end), depth(1) - 0.01);
            test.verifyLessThan(result.diagnostics.maximumRelativeMassError, ...
                [1e-5, 1e-5]);
            verifyIndependentInventory(test, result);
        end

        function rejectsInvalidGridAndDuration(test)
            test.verifyError(@() setupHydrogenMixing2D('gridSize', [3, 4]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            test.verifyError(@() setupHydrogenMixing2D('durationDays', 0), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function exportsGifAndPosterWithoutVideo(test)
            result = exampleHydrogenMixing2D('gridSize', [4, 4], ...
                'durationDays', 0.1, 'outputCount', 2);
            folder = tempname;
            cleanup = onCleanup(@() rmdir(folder, 's'));
            files = animateHydrogenMixing2D(result, folder, 'writeVideo', false);
            information = imfinfo(files.gif);
            test.verifyNumElements(information, 3);
            test.verifyTrue(isfile(files.poster));
            test.verifyEmpty(files.video);
        end

    end
end

function verifyIndependentInventory(test, result)
    % Gas-only PR molar inventory, independent of ComponentTotalMass grouping.
    model = result.model;
    states = [{result.state0}; result.states(:)];
    initial = [];
    for index = 1:numel(states)
        state = states{index};
        test.verifyEqual(state.s(:, model.getVaporIndex()), ...
            ones(model.G.cells.num, 1), 'AbsTol', 1e-8);
        moles = model.G.cells.volumes .* model.rock.poro .* ...
            state.pressure ./ (state.Z_V .* 8.31446261815324 .* state.T);
        mass = sum(moles .* state.components, 1) .* model.EOSModel.CompositionalMixture.molarMass;
        if isempty(initial)
            initial = mass;
        end
        test.verifyEqual(mass, initial, 'RelTol', 1e-5);
        test.verifyEqual(mass, ...
            result.diagnostics.componentMassKg(index, :), 'RelTol', 1e-6);
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
