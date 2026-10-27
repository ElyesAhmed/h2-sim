classdef H2StoreTest < matlab.unittest.TestCase
    %H2STORETEST Local property, schedule and numerical regression checks.
    methods (Test)
        function solubilityPressureScaling(test)
            tab = HenrySetschenowH2BrineEos([313.15; 313.15; 313.15], 1, [0; 1e6; 2e6]);
            test.verifyEqual(tab.x_H2(1), 0);
            test.verifyEqual(tab.x_H2(3), 2*tab.x_H2(2), 'RelTol', 1e-14);
            test.verifyGreaterThan(tab.x_H2(2), 0);
            test.verifyEqual(tab.("# temperature [°C]"), [40; 40; 40], 'AbsTol', 1e-12);
        end
        function salinityReducesSolubility(test)
            fresh = HenrySetschenowH2BrineEos(313.15, 0, 1e6);
            saline = HenrySetschenowH2BrineEos(313.15, 2, 1e6);
            test.verifyLessThan(saline.x_H2, fresh.x_H2);
            test.verifyGreaterThan(saline.x_H2, 0);
        end
        function zeroPressureZ(test)
            test.verifyEqual(calculateBrillBreggsZfactorHydrogen([298.15; 333.15], 0), [1; 1]);
        end
        function vectorizedZ(test)
            T = [298.15; 313.15; 333.15]; p = [1e5; 4e6; 1e7];
            expected = arrayfun(@calculateBrillBreggsZfactorHydrogen, T, p);
            test.verifyEqual(calculateBrillBreggsZfactorHydrogen(T, p), expected, 'AbsTol', 1e-14);
        end
        function stageEndpoints(test)
            schedule = makeSchedule({'charge', 'charge', 'discharge', 'shut'}, [1, 2, 3, 3, 4]);
            last = getCyclesLastSteps(schedule);
            test.verifyEqual(last.charge, 2);
            test.verifyEqual(last.discharge, 4);
            test.verifyEqual(last.shut, 5);
            test.verifyEmpty(last.cushion);
        end
        function repeatedCyclesAndNameFallback(test)
            schedule = makeSchedule({'charge', 'discharge'}, [1, 2, 1, 2]);
            for k = 1:2
                schedule.control(k).W = struct('name', schedule.control(k).W.stage);
            end
            last = getCyclesLastSteps(schedule);
            test.verifyEqual(last.charge, [1, 3]);
            test.verifyEqual(last.discharge, [2, 4]);
        end
        function emptyAndSingleStage(test)
            schedule = makeSchedule({'cushion'}, []);
            last = getCyclesLastSteps(schedule);
            test.verifyEmpty(last.cushion);
            schedule.step.control = [1, 1];
            last = getCyclesLastSteps(schedule);
            test.verifyEqual(last.cushion, 2);
        end
        function generatedRelativePermeabilities(test)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            getFluidH2BrineSGOF('plot', false, 'n', 11, 'outputPath', folder);
            fid = fopen(fullfile(folder, 'SGOF_UHS.txt'), 'r');
            tables = readSGOFTables(fid, 'SGOF', 1, 4);
            data = tables{1};
            test.verifySize(data, [11, 4]);
            test.verifyEqual(data([1, end], 1), [0; 1]);
            test.verifyEqual(data([1, end], 2:3), [0, 1; 1, 0]);
            test.verifyGreaterThanOrEqual(diff(data(:, 1:2)), zeros(10, 2));
            test.verifyLessThanOrEqual(diff(data(:, 3)), zeros(10, 1));
            test.verifyTrue(all(isfinite(data), 'all'));
        end
        function propertyReferences(test)
            ref = readReference();
            T = [298.15; 313.15; 333.15]; p = [1e5; 4e6; 1e7];
            tab = HenrySetschenowH2BrineEos(T, 1, p);
            test.verifyEqual(tab.x_H2, ref.solubility, 'RelTol', 1e-12);
            test.verifyEqual(calculateBrillBreggsZfactorHydrogen(T, p), ref.Z, 'RelTol', 1e-12);
        end
        function storageReferences(test)
            ref = readReference();
            actual = runH2StoreRegressionCases();
            names = fieldnames(actual);
            for k = 1:numel(names)
                name = names{k};
                for step = 1:2
                    state = ref.storage.(name);
                    test.verifyEqual(actual.(name).pressure{step}, state.pressure(:, step), ...
                        'AbsTol', 0.01, 'RelTol', 1e-9);
                    test.verifyEqual(actual.(name).saturation{step}, state.saturation(:, :, step), ...
                        'AbsTol', 1e-9, 'RelTol', 1e-7);
                    test.verifyEqual(sum(actual.(name).saturation{step}, 2), ones(4, 1), 'AbsTol', 1e-10);
                    test.verifyGreaterThan(actual.(name).pressure{step}, 0);
                    test.verifyGreaterThanOrEqual(actual.(name).saturation{step}, -1e-10);
                    test.verifyLessThanOrEqual(actual.(name).saturation{step}, 1 + 1e-10);
                end
            end
        end
    end
end

function schedule = makeSchedule(names, controls)
    schedule.step.control = controls;
    for k = 1:numel(names)
        schedule.control(k).W = struct('stage', names{k});
    end
end

function ref = readReference()
    ref = jsondecode(fileread(fullfile(fileparts(mfilename('fullpath')), 'reference-solutions.json')));
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
