function results = runH2StoreTests(mrstRoot)
%RUNH2STORETESTS Run local unit and small numerical regression tests.
%
% SYNOPSIS:
%   results = runH2StoreTests()
%   results = runH2StoreTests('/path/to/pinned/mrst')
%
% The default uses this repository's MRST submodule. No PHREEQC engine,
% downloaded fluid data or full paper examples are needed. Every test must
% pass; failed or incomplete tests cause this runner to raise an error.
    folder = fileparts(mfilename('fullpath'));
    root = fileparts(fileparts(folder));
    if nargin == 0
        mrstRoot = fullfile(root, 'submodules', 'mrst');
    end
    startupFile = fullfile(mrstRoot, 'startup.m');
    assert(isfile(startupFile), 'h2sim:h2store:MissingMRST', ...
        'Initialize the pinned MRST submodule or pass its location.');
    originalPath = path;
    originalFolder = pwd;
    cleanup = onCleanup(@() restoreEnvironment(originalPath, originalFolder));
    run(startupFile);
    mrstModule add ad-core ad-props ad-blackoil deckformat vemmech;
    addpath(genpath(fullfile(root, 'h2-store')));
    addpath(folder);
    suite = matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreTest.m'));
    suite = [suite, matlab.unittest.TestSuite.fromFile( ...
        fullfile(folder, 'H2StorePhaseTransferTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StorePVTOTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreSolubilityTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreInventoryTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreWaterDensityTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreSGOFTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StorePVTWriterTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreComponentTableTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreTimestepTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreWellPlacementTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreBoundaryTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreScheduleTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreInitializationTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreDomeTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreDomeTimingTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreDomeMappingTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreDomeStateTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreBenchmarkTimingTest.m')), ...
        matlab.unittest.TestSuite.fromFile(fullfile(folder, 'H2StoreBenchmarkStateTest.m'))];
    results = run(suite);
    assert(~isempty(results) && all([results.Passed]), ...
        'h2sim:h2store:TestFailure', 'All h2-store tests must pass without skips.');
end

function restoreEnvironment(originalPath, originalFolder)
    path(originalPath);
    cd(originalFolder);
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
