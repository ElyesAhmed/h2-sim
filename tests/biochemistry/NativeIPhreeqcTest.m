classdef NativeIPhreeqcTest < matlab.unittest.TestCase
    % Exercise the Linux interface, also runnable with Windows native DLLs.
    methods (Test)

        function selectedOutputAndRepeatedRuns(test)
            iph = H2simNativeIPhreeqc();
            cleanup = onCleanup(@() delete(iph));
            test.assertEqual(iph.LoadDatabase(which('h2_biogeochemistry.dat')), 0);
            input = sprintf(['SOLUTION 1\npH 7\nNa 0.123456789\nCl 0.123456789\n' ...
                'SELECTED_OUTPUT 1\n-reset false\n-pH true\n-totals Na Cl\nEND\n']);
            for iteration = 1:2
                test.assertEqual(iph.RunString(input), 0, iph.GetErrorString());
                raw = iph.GetSelectedOutputArray();
                [headers, values] = parseH2StorageIPhreeqcCOMSelectedOutput(raw);
                test.verifyEqual(size(values), [1, 3]);
                test.verifyEqual(values(1, strcmp(headers, 'ph')), 7, 'AbsTol', 1e-10);
                test.verifyEqual(values(1, startsWith(headers, 'na')), ...
                    0.123456789e-3, 'AbsTol', 1e-12);
            end
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
