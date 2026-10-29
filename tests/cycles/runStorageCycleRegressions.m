function cases = runStorageCycleRegressions(mrstRoot, phreeqcRoot)
    % RUNSTORAGECYCLEREGRESSIONS Verify complete cycles and serialized restarts.
    %
    % SYNOPSIS:
    %   cases = runStorageCycleRegressions()
    %   cases = runStorageCycleRegressions(mrstRoot, phreeqcMatlabRoot)
    %
    % Run locally with MATLAB and initialized dependencies. A working PHREEQC
    % engine is required; missing dependencies fail rather than skip tests.
    % Checks black-oil dissolution/vaporization, sequential PHREEQC chemistry,
    % well control changes, physical bounds, restart agreement and the saved
    % numerical reference. This runner never regenerates reference outputs.
    folder = fileparts(mfilename('fullpath'));
    root = fileparts(fileparts(folder));
    if nargin < 1
        mrstRoot = fullfile(root, 'submodules', 'mrst');
    end
    if nargin < 2
        phreeqcRoot = fullfile(root, 'submodules', 'PhreeqcMatlab');
    end
    assert(isfile(fullfile(mrstRoot, 'startup.m')) && ...
        isfile(fullfile(phreeqcRoot, 'startup.m')), ...
        'h2sim:cycles:Dependencies', 'Initialize MRST and PhreeqcMatlab or pass their paths.');
    originalPath = path;
    originalFolder = pwd;
    cleanup = onCleanup(@() restoreEnvironment(originalPath, originalFolder));
    initializeDependency(fullfile(mrstRoot, 'startup.m'));
    initializeDependency(fullfile(phreeqcRoot, 'startup.m'));
    addpath(genpath(fullfile(root, 'h2-store')));
    addpath(genpath(fullfile(root, 'h2-biochem')));
    addpath(fullfile(root, 'utils'));
    activateH2simBiochemistry(root);
    % Activation excludes test folders from the runtime module path.
    addpath(folder);
    mrstModule add ad-core ad-props ad-blackoil compositional deckformat;
    reference = load(fullfile(folder, 'storage-cycle-reference.mat'), 'cases');
    [cases, restartChecks] = runStorageCycleCases();
    compareStorageCycleValues(cases, reference.cases, 'reference');
    assert(all(structfun(@(x) x.passed, restartChecks)), ...
        'h2sim:cycles:Restart', 'A serialized restart differed; inspect CYCLE_RESTART_FAIL output.');
    fprintf('STORAGE_CYCLE_REGRESSIONS_PASS models=2 stepsPerCycle=6 restartStep=4\n');
end

function initializeDependency(startupFile)
    % Dependency startup scripts use their own workspace for local variables.
    run(startupFile);
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
