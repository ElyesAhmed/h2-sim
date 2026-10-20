classdef NativeIPhreeqcTest < matlab.unittest.TestCase
    % Exercise the Linux interface, also runnable with Windows native DLLs.
    methods (Test)
        function selectedOutputAndRepeatedRuns(test)
            iph = H2simNativeIPhreeqc();
            cleanup = onCleanup(@() delete(iph)); %#ok<NASGU>
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
