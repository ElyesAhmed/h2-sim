function results = benchmarkSequentialPhreeqcVolumeFlash(databaseFile)
%Compare local and global pressure brackets for the sequential volume flash
%
% SYNOPSIS:
%   results = benchmarkSequentialPhreeqcVolumeFlash(databaseFile)
%
% DESCRIPTION:
%   Run three pairs of two-step simulations with and without the local
%   pressure bracket. Alternate the run order and report elapsed times,
%   pressure differences, and component-inventory differences. Timings
%   include example setup and reporting. Grid, timesteps, and conservation
%   tolerances are identical in each pair.
%
% PARAMETERS:
%   databaseFile - Absolute path to h2_biogeochemistry.dat. Initialize
%                  H2sim and the platform's IPhreeqc interface first.
%
% RETURNS:
%   results - Paired timings, median speedup, and maximum relative
%             differences in pressure and component inventories.
%
% SEE ALSO:
%   exampleSequentialBiochemistryPhreeqc1D, profilePhreeqcWorkflows

previous = warning('error', 'H2Biochem:PhreeqcReflashInventory');
cleanup = onCleanup(@() warning(previous));
seconds = zeros(3, 2);
pressureRelativeDifference = zeros(3, 1);
inventoryRelativeDifference = zeros(3, 1);
for trial = 1:3
    order = [false, true];
    if mod(trial, 2) == 0
        order = fliplr(order);
    end
    summaries = cell(1, 2);
    for enabled = order
        timer = tic;
        summary = exampleSequentialBiochemistryPhreeqc1D( ...
            'maximumFlowSteps', 2, 'phreeqcDatabaseFile', databaseFile, ...
            'phreeqcReflashLocalBracket', enabled);
        seconds(trial, 1 + enabled) = toc(timer);
        summaries{1 + enabled} = summary;
        for step = 1:numel(summary.states)
            state = summary.states{step};
            assert(all(state.sequentialH2BiochemPhreeqcReflashPass(:)), ...
                'The post-flash inventory audit failed.');
        end
    end
    baseline = summaries{1};
    candidate = summaries{2};
    assert(numel(baseline.states) == numel(candidate.states));
    for step = 1:numel(baseline.states)
        a = baseline.states{step};
        b = candidate.states{step};
        pressureRelativeDifference(trial) = max(pressureRelativeDifference(trial), ...
            max(abs(a.pressure - b.pressure)./max(abs(a.pressure), 1)));
        am = a.sequentialH2BiochemPhreeqcReflashActualMoles;
        bm = b.sequentialH2BiochemPhreeqcReflashActualMoles;
        inventoryRelativeDifference(trial) = max(inventoryRelativeDifference(trial), ...
            max(abs(am(:) - bm(:))./max(abs(am(:)), 1e-7)));
    end
end
results = struct('seconds', seconds, ...
    'medianSeconds', median(seconds, 1), ...
    'speedup', median(seconds(:, 1))/median(seconds(:, 2)), ...
    'pressureRelativeDifference', pressureRelativeDifference, ...
    'inventoryRelativeDifference', inventoryRelativeDifference);
disp(results);
end

%{
Copyright 2026 H2sim contributors.

This file is part of H2sim.

H2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

H2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with H2sim. If not, see <https://www.gnu.org/licenses/>.
%}
