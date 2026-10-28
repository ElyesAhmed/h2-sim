classdef H2StoreSummaryTest < matlab.unittest.TestCase
    % H2STORESUMMARYTEST Analytical surface inventory and single-well diagnostics.
    methods (Test)

        function analyticalHistory(test)
            [model, state, well] = fixture();
            other = state;
            other.rs = state.rs / 2;
            secondWell = struct('bhp', 43 * barsa, 'qGs', -4, 'qOs', 1);
            data = summarizeH2StorageStates(model, {state, other}, {well, secondWell});
            test.verifyEqual(data.totalHydrogenVolume, [2.09, 2.02], 'AbsTol', 1e-14);
            test.verifyEqual(data.dissolvedHydrogenVolume, [0.14, 0.07], 'AbsTol', 1e-14);
            test.verifyEqual(data.gasHydrogenVolume, [1.95, 1.95], 'AbsTol', 1e-14);
            test.verifyEqual(data.meanPressure, [40, 40] * barsa);
            test.verifyEqual(data.meanGasSaturation, [0.5, 0.5]);
            test.verifyEqual(data.dissolvedFractionPercent, ...
                100 * [0.14 / 2.09, 0.07 / 2.02], 'AbsTol', 1e-13);
            test.verifyEqual(data.bhp, [42, 43] * barsa);
            test.verifyEqual(data.gasRate, [3, -4]);
            test.verifyEqual(data.brineRate, [-2, 1]);
        end

        function zeroInventory(test)
            [model, state, well] = fixture();
            state.s = [1, 0; 1, 0];
            state.rs(:) = 0;
            data = summarizeH2StorageStates(model, {state}, {well});
            test.verifyEqual(data.totalHydrogenVolume, 0);
            test.verifyEqual(data.dissolvedFractionPercent, 0);
        end

        function emptyHistory(test)
            [model, ~, ~] = fixture();
            data = summarizeH2StorageStates(model, {}, {});
            names = fieldnames(data);
            for k = 1:numel(names)
                test.verifySize(data.(names{k}), [1, 0]);
            end
        end

        function mismatchedHistories(test)
            [model, state, ~] = fixture();
            test.verifyError(@() summarizeH2StorageStates(model, {state}, {}), ...
                'h2sim:StorageSummary:HistoryLength');
        end

        function multipleWells(test)
            [model, state, well] = fixture();
            test.verifyError(@() summarizeH2StorageStates(model, {state}, {[well, well]}), ...
                'h2sim:StorageSummary:WellCount');
        end

    end
end

function [model, state, well] = fixture()
    G = computeGeometry(cartGrid([2, 1, 1], [4, 1, 1]));
    rock = makeRock(G, 100 * milli * darcy, [0.1; 0.4]);
    fluid = initSimpleADIFluid('phases', 'OG', 'mu', [1, 1], 'rho', [1, 1]);
    fluid.bO = @(p, varargin) 2 + 0 * p;
    fluid.bG = @(p, varargin) 3 + 0 * p;
    fluid.rsSat = @(p) 0.2 + 0 * p;
    model = GenericBlackOilModel(G, rock, fluid, 'water', false, ...
        'disgas', true, 'vapoil', false, 'gravity', [0, 0, 0]);
    model.minimumPressure = barsa;
    model = model.validateModel();
    state = initResSol(G, [38; 42] * barsa, [0.75, 0.25; 0.25, 0.75]);
    state.rs = [0.2; 0.2];
    state = model.validateState(state);
    well = struct('bhp', 42 * barsa, 'qGs', 3, 'qOs', -2);
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
