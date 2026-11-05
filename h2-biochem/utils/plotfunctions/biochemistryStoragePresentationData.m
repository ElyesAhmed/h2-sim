function data = biochemistryStoragePresentationData(result)
    % BIOCHEMISTRYSTORAGEPRESENTATIONDATA Histories for the 2D microbial case.
    %
    % SYNOPSIS:
    %   data = biochemistryStoragePresentationData(result)
    %
    % Uses the initial and saved accepted states of a completed case. Times
    % are days, signed component well rates kg/day and active-well BHP bar.
    % Inactive-well rates are zero; their BHP is NaN. Reaction consumption
    % percentages use cumulative injected H2 moles, not retained inventory.
    % Biomass colour limits include the entire saved history, in model units.
    assert(result.complete, 'H2sim:BiochemistryIncomplete', ...
        'Presentation requires a completed simulation.');
    count = numel(result.schedule.step.val);
    assert(numel(result.states) == count && numel(result.wellSols) == count, ...
        'H2sim:BiochemistryStateCount', 'States and wells must match the schedule.');
    data.times = [0; cumsum(result.schedule.step.val)] / day;
    data.massRate = zeros(count, 3);
    data.bhp = nan(count, 1);
    data.stages = cell(count, 1);
    components = {'H2', 'CO2', 'C1'};
    injection = zeros(count, 1);
    for k = 1:count
        wells = result.schedule.control(result.schedule.step.control(k)).W;
        data.stages{k} = wells(1).stage;
        for wi = 1:numel(wells)
            well = result.wellSols{k}(wi);
            active = wells(wi).status && well.status && ...
                ~(~strcmp(wells(wi).type, 'bhp') && wells(wi).val == 0);
            if ~active
                continue
            end
            for component = 1:3
                rate = sum(well.(components{component}));
                data.massRate(k, component) = data.massRate(k, component) + rate * day;
            end
            injection(k) = injection(k) + max(sum(well.H2), 0);
            if wi == 1
                data.bhp(k) = well.bhp / barsa;
            end
        end
    end
    changes = ~strcmp(data.stages(1:end - 1), data.stages(2:end));
    data.endpoints = find([changes; true]) + 1;
    data.injectedMoles = [0; cumsum(injection .* result.schedule.step.val)] / ...
        result.model.compFluid.molarMass(2);
    data.consumedMoles = zeros(count + 1, 3);
    data.biomassLimits = zeros(3, 2);
    if result.model.bacteriamodel
        states = [{result.state0}; result.states(:)];
        for k = 1:count + 1
            state = states{k};
            if k > 1
                assert(isfield(state, 'cumulativeH2ConsumptionMoles'), ...
                    'H2sim:BiochemistryConsumptionMissing', ...
                    'Saved cumulative reaction diagnostics are required.');
            end
            if isfield(state, 'cumulativeH2ConsumptionMoles')
                data.consumedMoles(k, :) = sum(state.cumulativeH2ConsumptionMoles, 1);
            end
            data.biomassLimits(:, 2) = max(data.biomassLimits(:, 2), ...
                max(state.nbact, [], 1).');
        end
        data.biomassLimits(:, 2) = max(data.biomassLimits(:, 2), 1);
    end
    data.percent = 100 * data.consumedMoles ./ max(data.injectedMoles, eps);
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
