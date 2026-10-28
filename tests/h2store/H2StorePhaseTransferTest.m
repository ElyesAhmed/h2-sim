classdef H2StorePhaseTransferTest < matlab.unittest.TestCase
    % H2STOREPHASETRANSFERTEST PVT round-trip and phase-transfer regressions.
    properties
        Cases
    end
    methods (TestClassSetup)

        function simulate(test)
            test.Cases = runH2StorePhaseTransferCases();
        end

    end
    methods (Test)

        function dissolution(test)
            checkCase(test, 'dissolution', true, false);
        end

        function vaporization(test)
            checkCase(test, 'vaporization', false, true);
        end

        function combined(test)
            checkCase(test, 'combined', true, true);
        end

    end
end

function checkCase(test, name, disgas, vapoil)
    reference = jsondecode(fileread(fullfile(fileparts(mfilename('fullpath')), ...
        'phase-transfer-reference.json')));
    actual = test.Cases.(name);
    expected = reference.cases.(name);
    for k = 1:numel(actual)
        test.verifyEqual(actual(k).pressure, expected(k).pressure, ...
            'AbsTol', 0.01, 'RelTol', 1e-9);
        test.verifyEqual(actual(k).saturation, expected(k).saturation, ...
            'AbsTol', 1e-9, 'RelTol', 1e-7);
        for field = {'rs', 'rv', 'dissolved', 'vaporized', 'inventory'}
            f = field{1};
            test.verifyEqual(actual(k).(f), expected(k).(f), ...
                'AbsTol', 1e-12, 'RelTol', 1e-7);
        end
        test.verifyGreaterThan(actual(k).pressure, 0);
        test.verifyGreaterThan(actual(k).saturation, 0);
        test.verifyLessThan(actual(k).saturation, 1);
        test.verifyEqual(sum(actual(k).saturation, 2), ones(4, 1), 'AbsTol', 1e-10);
        test.verifyEqual(actual(k).inventory, actual(1).inventory, ...
            'AbsTol', 1e-10, 'RelTol', 1e-6);
    end
    if disgas
        test.verifyGreaterThan(actual(end).rs, 0);
        test.verifyGreaterThan(norm(actual(end).rs - actual(1).rs, inf), 1e-8);
        test.verifyGreaterThan(norm(actual(end).dissolved - actual(1).dissolved, inf), 1e-8);
    else
        test.verifyEqual(actual(end).rs, zeros(4, 1));
        test.verifyEqual(actual(end).dissolved, zeros(4, 1));
    end
    if vapoil
        test.verifyGreaterThan(actual(end).rv, 0);
        test.verifyGreaterThan(norm(actual(end).rv - actual(1).rv, inf), 1e-12);
        test.verifyGreaterThan(norm(actual(end).vaporized - actual(1).vaporized, inf), 1e-10);
    else
        test.verifyEqual(actual(end).rv, zeros(4, 1));
        test.verifyEqual(actual(end).vaporized, zeros(4, 1));
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
