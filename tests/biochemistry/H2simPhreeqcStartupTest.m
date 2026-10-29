classdef H2simPhreeqcStartupTest < matlab.unittest.TestCase
    % Explicit initialization, dependency errors and option validation.
    methods (TestClassSetup)

        function addStartupFolder(test)
            root = fileparts(fileparts(which('initializeH2simPhreeqc')));
            test.applyFixture(matlab.unittest.fixtures.PathFixture(root));
        end

    end
    methods (Test)

        function invalidOptionFailsBeforeDependencySetup(test)
            test.verifyError(@() startupH2sim('phreeqc', 1), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function unknownOptionFailsBeforeDependencySetup(test)
            test.verifyError(@() startupH2sim('unknown', true), ...
                'MATLAB:InputParser:UnmatchedParameter');
        end

        function missingCheckoutExplainsHowToInstall(test)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            test.verifyError(@() initializeH2simPhreeqc(folder), ...
                'h2sim:missingGitRepo');
        end

        function explicitInitializationCallsDependencyStartup(test)
            [folder, cleanup] = makeDependency('setenv(''H2SIM_STARTUP_TEST'', ''called'');');
            previous = getenv('H2SIM_STARTUP_TEST');
            restore = onCleanup(@() setenv('H2SIM_STARTUP_TEST', previous));
            setenv('H2SIM_STARTUP_TEST', '');
            initializeH2simPhreeqc(folder);
            test.verifyEqual(getenv('H2SIM_STARTUP_TEST'), 'called');
        end

        function explicitInitializationPropagatesFailure(test)
            [folder, cleanup] = makeDependency( ...
                'error(''H2sim:TestLibrarySetup'', ''Missing test library.'');');
            test.verifyError(@() initializeH2simPhreeqc(folder), ...
                'H2sim:TestLibrarySetup');
        end

    end
end

function [folder, cleanup] = makeDependency(statement)
    folder = tempname;
    dependency = fullfile(folder, 'submodules', 'PhreeqcMatlab');
    mkdir(dependency);
    cleanup = onCleanup(@() rmdir(folder, 's'));
    file = fullfile(dependency, 'startup.m');
    fid = fopen(file, 'w');
    assert(fid >= 0);
    closeFile = onCleanup(@() fclose(fid));
    fprintf(fid, 'function startup()\n%s\nend\n', statement);
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
