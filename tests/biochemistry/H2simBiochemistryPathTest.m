classdef H2simBiochemistryPathTest < matlab.unittest.TestCase
    % Verify that H2sim sessions select the standalone biochemistry code.
    methods (Test)
        function replacesPreviouslyAddedMRSTModule(test)
            [root, upstream] = moduleRoots();
            test.addTeardown(@() activateH2simBiochemistry(root));
            mrstPath('reregister', 'h2-biochem', upstream);
            mrstModule add h2-biochem
            test.verifyEqual(which('BiochemistryModel'), ...
                fullfile(upstream, 'models', 'BiochemistryModel.m'));

            activateH2simBiochemistry(root);
            verifyLocalModule(test, root);
        end

        function oldModuleNameCannotReplaceH2sim(test)
            [root, ~] = moduleRoots();
            activateH2simBiochemistry(root);
            evalc('mrstModule add h2-biochem');
            verifyLocalModule(test, root);
        end

        function developmentPathsAreRemoved(test)
            [root, ~] = moduleRoots();
            addpath(fullfile(root, 'tests', 'biochemistry'));
            addpath(fullfile(root, 'research', 'biochemistry', '3d'));
            activateH2simBiochemistry(root);
            verifyDevelopmentPathsAbsent(test, root);
            verifySupportedExamples(test);
        end

        function reactivationPreservesRuntimeBoundary(test)
            [root, ~] = moduleRoots();
            activateH2simBiochemistry(root);
            modules = mrstModule();
            test.addTeardown(@() mrstModule('reset', modules{:}));
            mrstModule('reset', modules{:});
            verifyLocalModule(test, root);
            verifyDevelopmentPathsAbsent(test, root);
            verifySupportedExamples(test);
        end

        function repeatedActivationKeepsOneModule(test)
            [root, ~] = moduleRoots();
            activateH2simBiochemistry(root);
            activateH2simBiochemistry(root);
            modules = mrstModule();
            test.verifyEqual(nnz(strcmp(modules, 'h2sim-biochem')), 1);
            verifyLocalModule(test, root);
        end
    end
end

function [root, upstream] = moduleRoots()
    root = fileparts(fileparts(which('activateH2simBiochemistry')));
    mrstRoot = fileparts(fileparts(fileparts(which('mrstPath'))));
    upstream = fullfile(mrstRoot, 'modules', 'h2-biochem');
end

function verifyLocalModule(test, root)
    test.verifyEmpty(mrstPath('search', 'h2-biochem'));
    test.verifyEqual(mrstPath('search', 'h2sim-biochem'), fullfile(root, 'h2-biochem'));
    test.verifyEqual(which('BiochemistryModel'), ...
        fullfile(root, 'h2-biochem', 'models', 'BiochemistryModel.m'));
    entries = strsplit(strrep(path, '\', '/'), pathsep);
    fromMRST = ~cellfun(@isempty, ...
        regexpi(entries, '/modules/h2-biochem(/|$)', 'once'));
    test.verifyFalse(any(fromMRST));
end

function verifyDevelopmentPathsAbsent(test, root)
    entries = strrep(strsplit(path, pathsep), '\', '/');
    roots = {fullfile(root, 'tests'), fullfile(root, 'research')};
    for k = 1:numel(roots)
        directory = strrep(roots{k}, '\', '/');
        if ispc
            directory = lower(directory);
            entries = cellfun(@lower, entries, 'UniformOutput', false);
        end
        test.verifyFalse(any(strcmp(entries, directory) | ...
            startsWith(entries, [directory, '/'])));
    end
end

function verifySupportedExamples(test)
    names = {'simple1DBacterialExampleMetacet', ...
             'exampleCompositionalBacterial2DThreeReactions', ...
             'exampleCompositionalBacterial1DPhreeqcMinerals', ...
             'exampleSequentialBiochemistryPhreeqc1D', ...
             'runThreeBackendComparison', 'exampleH2BrineSolubilityStudy'};
    for k = 1:numel(names)
        test.verifyNotEmpty(which(names{k}), names{k});
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
