classdef H2StoreInventoryTest < matlab.unittest.TestCase
    % H2STOREINVENTORYTEST Analytical component inventories in surface m^3.
    methods (Test)

        function heterogeneousPorosityAndPhaseVolumes(test)
            [model, state] = fixture(true, false);
            [total, dissolved, gas] = computeGasVolumes(model, {state}, 1);
            % Bulk volumes [2;2], porosity [.1;.4], bO=2, bG=3, Rs=.2.
            test.verifyEqual(dissolved{1}, [0.06; 0.08], 'AbsTol', 1e-14);
            test.verifyEqual(gas{1}, [0.15; 1.8], 'AbsTol', 1e-14);
            test.verifyEqual(total{1}, [0.21; 1.88], 'AbsTol', 1e-14);
        end

        function noGasPhaseStillHasDissolvedHydrogen(test)
            [model, state] = fixture(true, false);
            state.s = [1, 0; 1, 0];
            [total, dissolved, gas] = computeGasVolumes(model, {state}, 1);
            test.verifyEqual(dissolved{1}, [0.08; 0.32], 'AbsTol', 1e-14);
            test.verifyEqual(gas{1}, zeros(2, 1));
            test.verifyEqual(total, dissolved);
        end

        function noLiquidHasNoDissolvedHydrogen(test)
            [model, state] = fixture(true, false);
            state.s = [0, 1; 0, 1];
            [total, dissolved, gas] = computeGasVolumes(model, {state}, 1);
            test.verifyEqual(dissolved{1}, zeros(2, 1));
            test.verifyEqual(gas{1}, [0.6; 2.4], 'AbsTol', 1e-14);
            test.verifyEqual(total, gas);
        end

        function immiscibleWithoutSavedPVTOrRs(test)
            [model, state] = fixture(false, false);
            state = rmfield(state, 'PVTProps');
            if isfield(state, 'rs')
                state = rmfield(state, 'rs');
            end
            [~, dissolved, gas] = computeGasVolumes(model, {state}, 1);
            test.verifyEqual(dissolved{1}, zeros(2, 1));
            test.verifyEqual(gas{1}, [0.15; 1.8], 'AbsTol', 1e-14);
        end

        function selectedStepsAndEmptySelection(test)
            [model, state] = fixture(true, false);
            other = state;
            other.rs = 2 * state.rs;
            [total, dissolved] = computeGasVolumes(model, {state, other}, [2, 1, 2]);
            test.verifySize(total, [3, 1]);
            test.verifyEqual(dissolved{1}, 2 * dissolved{2});
            test.verifyEqual(total{1}, total{3});
            [total, dissolved, gas] = computeGasVolumes(model, {state}, []);
            test.verifySize(total, [0, 1]);
            test.verifyEmpty(dissolved);
            test.verifyEmpty(gas);
        end

        function effectivePoreVolume(test)
            [model, state] = fixture(true, true);
            [total, dissolved, gas] = computeGasVolumes(model, {state}, 1);
            test.verifyEqual(dissolved{1}, [0.06; 0.08] * 2, 'AbsTol', 1e-14);
            test.verifyEqual(gas{1}, [0.15; 1.8] * 2, 'AbsTol', 1e-14);
            test.verifyEqual(total{1}, [0.21; 1.88] * 2, 'AbsTol', 1e-14);
        end

        function threePhaseIndices(test)
            [model, state] = fixture(true, false, true);
            [~, dissolved, gas] = computeGasVolumes(model, {state}, 1);
            test.verifyEqual(dissolved{1}, [0.048; 0.064], 'AbsTol', 1e-14);
            test.verifyEqual(gas{1}, [0.15; 1.8], 'AbsTol', 1e-14);
        end

    end
end

function [model, state] = fixture(disgas, compressible, water)
    if nargin < 3
        water = false;
    end
    G = computeGeometry(cartGrid([2, 1, 1], [4, 1, 1]));
    rock = makeRock(G, 100 * milli * darcy, [0.1; 0.4]);
    phases = 'OG';
    sat = [0.75, 0.25; 0.25, 0.75];
    if water
        phases = 'WOG';
        sat = [0.15, 0.6, 0.25; 0.05, 0.2, 0.75];
    end
    fluid = initSimpleADIFluid('phases', phases, 'mu', ones(1, numel(phases)), ...
        'rho', ones(1, numel(phases)));
    fluid.bO = @(p, varargin) 2 + 0 * p;
    fluid.bG = @(p, varargin) 3 + 0 * p;
    fluid.rsSat = @(p) 0.2 + 0 * p;
    if compressible
        fluid.pvMultR = @(p) exp(log(2) * (p / (40 * barsa) - 1));
    end
    model = GenericBlackOilModel(G, rock, fluid, 'water', water, ...
        'disgas', disgas, 'vapoil', false, 'gravity', [0, 0, 0]);
    model.minimumPressure = barsa;
    model = model.validateModel();
    pressure = 40 * barsa;
    if compressible
        pressure = 80 * barsa;
    end
    state = initResSol(G, pressure, sat);
    if disgas
        state.rs = 0.2 * ones(2, 1);
    end
    state = model.validateState(state);
    % Populate a genuine MRST cache; old code requires this saved field.
    [~, state] = model.getProp(state, 'ShrinkageFactors');
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
