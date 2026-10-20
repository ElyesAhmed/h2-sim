function diagnostics = collectPhreeqcValidationDiagnostics(result)
%Collect hydrogen consumption and aqueous chemistry for a storage comparison
%
% SYNOPSIS:
%   diagnostics = collectPhreeqcValidationDiagnostics(result)
%
% PARAMETERS:
%   result - Comparison returned by exampleCompositionalPhreeqcValidation,
%            with an h2sim entry and an optional reference entry containing model,
%            schedule, and accepted states. Reference states must include
%            Solution.TotalDIC. Older saved reference data are also accepted.
%
% RETURNS:
%   diagnostics - Per-model times, cell coordinates, aqueous hydrogen mole
%                 fractions, pH, DIC molality, and cumulative consumption by
%                 reaction. Loss percentages use prescribed active-well H2
%                 injection as the common normalization basis.
%
% SEE ALSO:
%   exampleCompositionalPhreeqcValidation, plotCompositionalPhreeqcValidation

    % Compatibility with previously saved reference datasets.
    if ~isfield(result, 'reference') && isfield(result, 'ugfact')
        result.reference = result.ugfact;
    end
    names = {'h2sim'};
    if isfield(result, 'reference') && ~isempty(result.reference)
        names{end+1} = 'reference';
    end
    diagnostics = struct();
    for j = 1:numel(names)
        run = result.(names{j});
        timeDays = double(cumsum(run.schedule.step.val(:)))/day;
        nSteps = numel(run.states);
        validateStateCount(nSteps, timeDays);
        current = struct('timeDays',    timeDays, ...
                         'coordinates', run.model.G.cells.centroids, ...
                         'h2',          [], ...
                         'pH',          [], ...
                         'dic',         [], ...
                         'consumption', zeros(run.model.G.cells.num, nSteps, 3));

        for k = 1:nSteps
            state = run.states{k};
            current.h2(:, k) = state.x(:, 2);
            if j == 1
                current.pH(:, k) = state.phreeqcPH;
                current.dic(:, k) = state.phreeqcTotalCarbon;
            else
                validateReferenceChemistry(state.Solution);
                current.pH(:, k) = state.Solution.pH;
                current.dic(:, k) = state.Solution.TotalDIC;
            end
        end

        for reaction = 1:3
            if j == 1
                [~, current.consumption(:, :, reaction)] = computeH2Consumption( ...
                    run.states, run.schedule, run.model, reaction);
            else
                current.consumption(:, :, reaction) = ...
                    referenceConsumption(run, reaction);
            end
        end
        injected = prescribedInjectedH2(run);
        current.injectedMoles = injected;
        current.lossPercent = 100*reshape( ...
            sum(sum(current.consumption, 1), 3), nSteps, 1)/injected;
        diagnostics.(names{j}) = current;
    end
end

function validateStateCount(nSteps, timeDays)
    assert(nSteps > 0 && nSteps == numel(timeDays), ...
        'H2sim:ValidationStateCount', ...
        'States must match the nonempty accepted schedule.');
end

function validateReferenceChemistry(solution)
    assert(isfield(solution, 'TotalDIC'), ...
        'Reference total-DIC diagnostic required.');
end

function consumption = referenceConsumption(run, reaction)
    reactionNames = {'MET_Rate', 'ACE_Rate', 'SRB_Rate'};
    nSteps = numel(run.states);
    consumption = zeros(run.model.G.cells.num, nSteps);
    for k = 1:nSteps
        solution = run.states{k}.Solution;
        increment = solution.(reactionNames{reaction}).*solution.Water/1000* ...
            run.schedule.step.val(k)/day;
        if k == 1
            consumption(:, k) = increment;
        else
            consumption(:, k) = consumption(:, k-1) + increment;
        end
    end
end

function injected = prescribedInjectedH2(run)
    injected = 0;
    for k = 1:numel(run.states)
        wells = run.schedule.control(run.schedule.step.control(k)).W;
        for wi = 1:numel(wells)
            well = wells(wi);
            if well.sign <= 0 || ~well.status
                continue
            end
            if strcmp(well.type, 'rate')
                rate = well.val*well.compi(run.model.getVaporIndex());
            elseif strcmp(well.type, 'grat')
                rate = well.val;
            else
                continue
            end
            injected = injected + rate*well.components(2)*run.schedule.step.val(k)* ...
                run.model.FacilityModel.pressure/(8.314462618*run.model.FacilityModel.T);
        end
    end
    assert(isfinite(injected) && injected > 0, 'H2sim:ValidationInjection', ...
        'Validation requires a positive prescribed H2 injection.');
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
