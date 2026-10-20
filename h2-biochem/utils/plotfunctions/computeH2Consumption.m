function [H2_rate_per_cell, H2_cum_per_cell] = computeH2Consumption(states, schedule, model, idxReaction)
% Compute reaction-specific H2 consumption from the model source terms.

bf = model.biochemFluid;
nReactions = bf.nbioreact;
assert(idxReaction >= 1 && idxReaction <= nReactions, ...
    'idxReaction must identify an existing biochemical reaction.');
assert(numel(states) == numel(schedule.step.val), ...
    'states and schedule must contain the same number of timesteps.');

nCells = model.G.cells.num;
nSteps = numel(states);
H2_rate_per_cell = zeros(nCells, nSteps);
H2_cum_per_cell = zeros(nCells, nSteps);

for t = 1:nSteps
    state = states{t};

    if isa(model, 'BiochemistryPhreeqcModel') && ...
            model.isSequentialCompositionalPhreeqcBackend() && ...
            isfield(state, 'sequentialCompositionalPhreeqcH2ConsumptionByReactionMoles')
        increment = state.sequentialCompositionalPhreeqcH2ConsumptionByReactionMoles(:, idxReaction);
        H2_rate_per_cell(:, t) = increment./schedule.step.val(t);
        if t == 1
            H2_cum_per_cell(:, t) = increment;
        else
            H2_cum_per_cell(:, t) = H2_cum_per_cell(:, t - 1) + increment;
        end
        continue;
    end

    if isa(model, 'BiochemistryPhreeqcModel') && ...
            model.isSequentialH2BiochemPhreeqcBackend() && ...
            isfield(state, 'sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles')
        cumulative = state.sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles(:, idxReaction);
        if t == 1
            increment = cumulative;
        else
            previous = states{t - 1}.sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles(:, idxReaction);
            increment = cumulative - previous;
        end
        H2_rate_per_cell(:, t) = increment./schedule.step.val(t);
        H2_cum_per_cell(:, t) = cumulative;
        continue;
    end

    if isfield(state, 'cumulativeH2ConsumptionMoles')
        cumulative = state.cumulativeH2ConsumptionMoles(:, idxReaction);
        if t == 1
            increment = cumulative;
        else
            assert(isfield(states{t - 1}, ...
                'cumulativeH2ConsumptionMoles'), ...
                ['Saved states contain an inconsistent cumulative H2 ', ...
                 'consumption history.']);
            previous = states{t - 1}.cumulativeH2ConsumptionMoles( ...
                :, idxReaction);
            increment = cumulative - previous;
        end
        H2_rate_per_cell(:, t) = increment./schedule.step.val(t);
        H2_cum_per_cell(:, t) = cumulative;
        continue;
    end

    assert(isfield(state, 'h2ConsumptionRate'), ...
        ['Saved states do not contain the converged H2 source rate. ', ...
         'Rerun the simulation before post-processing H2 consumption.']);
    H2_rate_per_cell(:, t) = state.h2ConsumptionRate(:, idxReaction);

    if t == 1
        H2_cum_per_cell(:, t) = H2_rate_per_cell(:, t).*schedule.step.val(t);
    else
        H2_cum_per_cell(:, t) = H2_cum_per_cell(:, t - 1) + ...
            H2_rate_per_cell(:, t).*schedule.step.val(t);
    end
end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).

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
