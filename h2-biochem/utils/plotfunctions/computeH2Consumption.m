function [H2_rate_per_cell, H2_cum_per_cell] = computeH2Consumption(states, schedule, model, idxReaction)
    % Collect reaction-specific hydrogen consumption from accepted states
    %
    % SYNOPSIS:
    %   [rate, cumulative] = computeH2Consumption(states, schedule, model, reaction)
    %
    % PARAMETERS:
    %   states      - Cell array with one accepted state per schedule step,
    %                 excluding the initial state. Consumption fields contain
    %                 one row per cell and one column per biochemical reaction.
    %   schedule    - Schedule whose step.val contains timestep lengths in seconds.
    %   model       - Model supplying G.cells.num and biochemFluid.nbioreact.
    %   idxReaction - Reaction column to collect. The standard three-reaction
    %                 setup uses 1 = MET, 2 = ACE, 3 = SRB.
    %
    % RETURNS:
    %   H2_rate_per_cell - nCells-by-nSteps H2 consumption in mol/s. For saved
    %                      mole increments or cumulative histories this is the
    %                      average over each schedule step, not an endpoint rate.
    %   H2_cum_per_cell  - nCells-by-nSteps cumulative H2 consumption in mol.
    %
    % NOTES:
    %   Sources are selected separately for each state, in this order:
    %     1. Compositional PHREEQC step increments in
    %        sequentialCompositionalPhreeqcH2ConsumptionByReactionMoles.
    %     2. Multirate PHREEQC cumulative values in
    %        sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles.
    %     3. Generic cumulativeH2ConsumptionMoles.
    %     4. Converged h2ConsumptionRate, integrated using schedule.step.val.
    %   The first two sources require the corresponding BiochemistryPhreeqcModel
    %   backend. Generic cumulative values take precedence over saved rates.
    %   A cumulative history must contain the preceding state's matching field.
    %   Its first saved cumulative value is used as the first increment; provide
    %   the full history from the simulation origin for step-average rates.
    %   Values are used as stored, without clipping or recomputing reactions.
    %   Empty states and schedule return nCells-by-0 arrays.
    %
    % SEE ALSO:
    %   collectPhreeqcValidationDiagnostics, plotPhreeqcBackendComparison

    validateInputs(states, schedule, model, idxReaction);
    nCells = model.G.cells.num;
    nSteps = numel(states);
    H2_rate_per_cell = zeros(nCells, nSteps);
    H2_cum_per_cell = zeros(nCells, nSteps);

    for t = 1:nSteps
        state = states{t};
        dt = schedule.step.val(t);
        if isa(model, 'BiochemistryPhreeqcModel') && ...
            model.isSequentialCompositionalPhreeqcBackend() && ...
            isfield(state, 'sequentialCompositionalPhreeqcH2ConsumptionByReactionMoles')
            increment = ...
                state.sequentialCompositionalPhreeqcH2ConsumptionByReactionMoles(:, idxReaction);
            H2_rate_per_cell(:, t) = increment ./ dt;
            H2_cum_per_cell(:, t) = accumulateIncrement( ...
                H2_cum_per_cell, increment, t);
        elseif isa(model, 'BiochemistryPhreeqcModel') && ...
            model.isSequentialH2BiochemPhreeqcBackend() && ...
            isfield(state, 'sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles')
            [H2_rate_per_cell(:, t), H2_cum_per_cell(:, t)] = ...
                readCumulativeHistory(states, t, idxReaction, dt, ...
                'sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles');
        elseif isfield(state, 'cumulativeH2ConsumptionMoles')
            validateCumulativeHistory(states, t);
            [H2_rate_per_cell(:, t), H2_cum_per_cell(:, t)] = ...
                readCumulativeHistory(states, t, idxReaction, dt, ...
                'cumulativeH2ConsumptionMoles');
        else
            validateSavedRate(state);
            H2_rate_per_cell(:, t) = state.h2ConsumptionRate(:, idxReaction);
            increment = H2_rate_per_cell(:, t) .* dt;
            H2_cum_per_cell(:, t) = accumulateIncrement( ...
                H2_cum_per_cell, increment, t);
        end
    end
end

function validateInputs(states, schedule, model, idxReaction)
    nReactions = model.biochemFluid.nbioreact;
    assert(idxReaction >= 1 && idxReaction <= nReactions, ...
        'idxReaction must identify an existing biochemical reaction.');
    assert(numel(states) == numel(schedule.step.val), ...
        'states and schedule must contain the same number of timesteps.');
end

function cumulative = accumulateIncrement(history, increment, step)
    if step == 1
        cumulative = increment;
    else
        cumulative = history(:, step - 1) + increment;
    end
end

function [rate, cumulative] = readCumulativeHistory(states, step, reaction, dt, field)
    cumulative = states{step}.(field)(:, reaction);
    if step == 1
        increment = cumulative;
    else
        previous = states{step - 1}.(field)(:, reaction);
        increment = cumulative - previous;
    end
    rate = increment ./ dt;
end

function validateCumulativeHistory(states, step)
    if step > 1
        assert(isfield(states{step - 1}, 'cumulativeH2ConsumptionMoles'), ...
            ['Saved states contain an inconsistent cumulative H2 ', ...
            'consumption history.']);
    end
end

function validateSavedRate(state)
    assert(isfield(state, 'h2ConsumptionRate'), ...
        ['Saved states do not contain the converged H2 source rate. ', ...
        'Rerun the simulation before post-processing H2 consumption.']);
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
