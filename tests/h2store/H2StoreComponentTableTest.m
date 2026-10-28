classdef H2StoreComponentTableTest < matlab.unittest.TestCase
    %H2STORECOMPONENTTABLETEST Offline NIST response and CSV checks.
    properties (TestParameter)
        generator = {@generateComponentProperties, @generatePureComponentProperties}
        responseType = {'char', 'string', 'bytes'}
    end
    methods (Test)
        function responseRoundTrip(test, generator, responseType)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            reader = @(url) fixtureResponse(url, responseType);
            data = generator('min_temp', 10, 'max_temp', 30, 'n_temp', 2, ...
                'min_press', 1e5, 'max_press', 4e5, 'n_press', 4, ...
                'comp_name', 'H2', 'outputPath', folder, ...
                'fileName', 'fluid.csv', 'webReader', reader);
            test.verifyEqual(data.Properties.VariableNames, ...
                {'# temperature [°C]', 'pressure [Pa]', 'density [kg/m3]', ...
                 'viscosity [Pa.s]', 'enthalpy [J/kg]'});
            actual = table2array(data);
            % The two middle rows straddle a phase transition.
            expected = [10, 1e5, 2, 1e-5, 1000; ...
                        10, 4e5, 5, 4e-5, 4000; ...
                        20, 1e5, 2, 1e-5, 1000; ...
                        20, 4e5, 5, 4e-5, 4000];
            test.verifyEqual(actual, expected, 'AbsTol', 1e-12);
            original = fileread(fullfile(folder, 'fluid.csv'));
            cached = generator('outputPath', folder, 'fileName', 'fluid.csv', ...
                'reCompute', false, 'webReader', @unexpectedRequest);
            test.verifyEqual(table2array(cached), expected, 'AbsTol', 1e-12);
            test.verifyEqual(fileread(fullfile(folder, 'fluid.csv')), original);
        end
        function singlePhase(test, generator)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            data = generator('n_temp', 1, 'outputPath', folder, ...
                'fileName', 'fluid.csv', 'webReader', @singlePhaseResponse);
            test.verifySize(table2array(data), [4, 5]);
            test.verifyEqual(table2array(data(:, 2)), (1:4)'*1e5);
        end
    end
end

function response = fixtureResponse(url, responseType)
    assert(contains(url, 'ID=C1333740') && contains(url, 'PUnit=Pa'));
    response = sprintf(['Pressure (Pa)\tDensity (kg/m3)\tViscosity (uPa*s)\tEnthalpy (kJ/kg)\tPhase\n', ...
        '100000\t2\t10\t1\tgas\n200000\t3\t20\t2\tgas\n', ...
        '300000\t4\t30\t3\tliquid\n400000\t5\t40\t4\tliquid\n']);
    switch responseType
        case 'string'
            response = string(response);
        case 'bytes'
            response = uint8(response(:));
    end
end

function response = singlePhaseResponse(url)
    assert(contains(url, 'ID=C7732185'));
    response = fixtureResponse(strrep(url, 'C7732185', 'C1333740'), 'char');
    response = strrep(response, 'liquid', 'gas');
end

function unexpectedRequest(~)
    error('h2sim:test:UnexpectedRequest', 'Cached tables must not request data.');
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
