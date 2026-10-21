function diagnostics = collectPhreeqcValidationDiagnostics(result)
%Collect hydrogen consumption and aqueous chemistry for a storage comparison
%
% SYNOPSIS:
%   diagnostics = collectPhreeqcValidationDiagnostics(result)
%
% PARAMETERS:
%   result - Structure with an h2sim run and, optionally, a reference run.
%            Each run contains model, schedule and a nonempty cell array of
%            accepted states, one per schedule step (excluding state0).
%            The model supplies cell geometry and facility pressure (Pa)
%            and temperature (K). State x(:, 2) is aqueous H2 mole fraction.
%            H2sim states supply phreeqcPH and phreeqcTotalCarbon (mol/kg
%            water); H2 consumption is obtained with computeH2Consumption.
%            Reference states supply Solution.pH, TotalDIC (mol/kg water),
%            Water (g), and MET_Rate, ACE_Rate, SRB_Rate (mol/kg water/day).
%            Legacy result.ugfact is read only when reference is absent.
%
% RETURNS:
%   diagnostics - Structure with h2sim and, when supplied, reference fields.
%                 Each entry contains:
%     timeDays      - nSteps-by-1 cumulative accepted times in days.
%     coordinates   - nCells-by-nDimensions cell centroids in metres.
%     h2, pH, dic   - nCells-by-nSteps aqueous H2 mole fraction, pH and
%                     total DIC molality (mol/kg water), respectively.
%     consumption   - nCells-by-nSteps-by-3 cumulative H2 consumption in mol,
%                     ordered MET, ACE, SRB.
%     injectedMoles - Positive total prescribed H2 injection in mol.
%     lossPercent   - nSteps-by-1 total cumulative reaction consumption as
%                     a percentage of injectedMoles.
%
% NOTES:
%   Injection uses active injectors with rate or grat controls, H2 component
%   index 2, and the facility ideal-gas conversion. Other control types are
%   skipped. This is prescribed injection, not measured well-solution flux.
%   Each run uses its own fixed denominator over the whole selected schedule,
%   including during injection. No interpolation or reference alignment is
%   performed here; the plotting function checks comparison coordinates.
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
        diagnostics.(names{j}) = collectRun(result.(names{j}), j == 1);
    end
end

function current = collectRun(run, isH2sim)
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
        if isH2sim
            current.pH(:, k) = state.phreeqcPH;
            current.dic(:, k) = state.phreeqcTotalCarbon;
        else
            validateReferenceChemistry(state.Solution);
            current.pH(:, k) = state.Solution.pH;
            current.dic(:, k) = state.Solution.TotalDIC;
        end
    end

    for reaction = 1:3
        if isH2sim
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
end

function validateStateCount(nSteps, timeDays)
    assert(nSteps > 0 && nSteps == numel(timeDays), ...
        'H2sim:ValidationStateCount', ...
        'States must match the nonempty accepted schedule.');
end

function validateReferenceChemistry(solution)
    assert(isfield(solution, 'TotalDIC'), ...
        'H2sim:ValidationReferenceDIC', ...
        'Reference Solution.TotalDIC (mol/kg water) is required.');
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
