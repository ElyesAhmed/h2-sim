classdef H2StoreSolubilityTest < matlab.unittest.TestCase
    %H2STORESOLUBILITYTEST Scalar references, grid ordering and CSV reuse.
    properties (TestParameter)
        model = {'Brine', 'Water'}
        nTemp = {1, 3}
        salt = {0, 1, 3}
    end
    methods (Test)
        function scalarReferencesAndOrdering(test, model, nTemp, salt)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            tab = generate(model, folder, nTemp, 4, salt, true);
            reference = jsondecode(fileread(fullfile(fileparts(mfilename('fullpath')), ...
                'solubility-reference.json')));
            key = sprintf('%s_%d_%d', model, nTemp, salt);
            test.verifyEqual(tab{:,:}, reference.values.(key), 'RelTol', 2e-13, 'AbsTol', 1e-15);
            test.verifySize(tab, [nTemp*4, 4]);
            if nTemp == 1
                temperatures = 25;
            else
                temperatures = linspace(25, 60, nTemp)';
            end
            test.verifyEqual(tab.("# temperature [°C]"), reshape(repelem(temperatures(:), 4), [], 1));
            test.verifyEqual(tab.("pressure [Pa]"), repmat(linspace(5e5, 1e7, 4)', nTemp, 1));
            test.verifyGreaterThan(tab{:,3:4}, 0);
            test.verifyLessThan(tab{:,3:4}, 1);
        end
        function reuseCSV(test, model)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            original = generate(model, folder, 3, 4, 1, true);
            files = dir(fullfile(folder, '*.csv'));
            file = fullfile(folder, files(1).name);
            contents = fileread(file);
            cached = generate(model, folder, 3, 4, 1, false);
            test.verifyEqual(cached.Properties.VariableNames, original.Properties.VariableNames);
            test.verifyEqual(cached{:,:}, original{:,:}, 'RelTol', 6e-5, 'AbsTol', 1e-12);
            test.verifyEqual(fileread(file), contents);
            test.verifyTrue(contains(contents, ...
                '# min phase pressure = 5.00e+05, max phase pressure = 1.00e+07'));
        end
        function smallestGrid(test, model)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            tab = generate(model, folder, 1, 2, 0, true);
            test.verifySize(tab, [2, 4]);
            test.verifyEqual(tab.("# temperature [°C]"), [25; 25]);
            test.verifyEqual(tab.("pressure [Pa]"), [5e5; 1e7]);
            test.verifyTrue(all(isfinite(tab{:,:}), 'all'));
        end
        function rejectsOnePressure(test, model)
            test.verifyError(@() generate(model, tempname, 1, 1, 0, true), ...
                'h2sim:SolubilityTable:PressureCount');
        end
    end
end

function tab = generate(model, folder, nTemp, nPress, salt, recompute)
    tab = feval(['generateH2', model, 'SolubilityTable'], ...
        'min_temp', 25, 'max_temp', 60, 'n_temp', nTemp, ...
        'min_press', 5e5, 'max_press', 1e7, 'n_press', nPress, ...
        'ms', salt, 'outputPath', folder, 'outputDisplay', false, 'reCompute', recompute);
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
