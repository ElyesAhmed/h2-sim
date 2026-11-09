function data = biochemistryStoragePresentationData(result)
    % BIOCHEMISTRYSTORAGEPRESENTATIONDATA Histories for the 2D microbial case.
    %
    % SYNOPSIS:
    %   data = biochemistryStoragePresentationData(result)
    %
    % Uses the initial and saved accepted states of a completed case. Times
    % are days, signed component well rates kg/day and BHP bar.
    % Inactive-well rates are zero; their pressure follows a local
    % zero-net-reservoir-volume well balance. Reaction consumption
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
    data.shutInBhp = false(count, 1);
    data.shutInRateResidual = zeros(count, 1);
    data.stages = cell(count, 1);
    model = result.model;
    if isa(model, 'PhysicalModel')
        model = model.setupStateFunctionGroupings();
        model.FacilityModel = model.FacilityModel.setReservoirModel(model);
        model.FacilityModel = model.FacilityModel.setupWells( ...
            result.schedule.control(1).W);
    end
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
                if wi == 1
                    [pressure, residual] = shutInPressure( ...
                        model, result.states{k}, wells(wi), well);
                    data.bhp(k) = pressure / barsa;
                    data.shutInBhp(k) = true;
                    data.shutInRateResidual(k) = residual;
                end
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

function [pressure, residual] = shutInPressure(model, state, W, wellSol)
    assert(model.FacilityModel.WellModels{1}.allowCrossflow, ...
        'H2sim:BiochemistryShutInCrossflow', ...
        'The multi-completion local balance requires a crossflow-enabled well.');
    assert(isfield(state, 'pressure'), 'H2sim:BiochemistryShutInPressureMissing', ...
        'Shut-in BHP requires saved reservoir pressures.');
    assert(isfield(W, 'dZ') && all(W.dZ == 0) && ...
        isfield(wellSol, 'cdp') && all(wellSol.cdp == 0), ...
        'H2sim:BiochemistryShutInPressureCorrection', ...
        'The local BHP balance requires zero well depth and pressure corrections.');
    cells = W.cells;
    mobility = model.getProp(state, 'Mobility');
    mobility = cellfun(@(phase) value(phase(cells)), mobility, ...
        'UniformOutput', false);
    mobility = horzcat(mobility{:});
    assert(all(isfinite(mobility(:))) && all(mobility(:) >= 0), ...
        'H2sim:BiochemistryShutInMobility', ...
        'Completion phase mobilities must be finite and nonnegative.');
    assert(numel(W.WI) == numel(cells) && ...
        all(isfinite(W.WI)) && all(W.WI >= 0) && ...
        numel(W.cstatus) == numel(cells) && ...
        numel(wellSol.cstatus) == numel(cells), ...
        'H2sim:BiochemistryShutInConnections', ...
        'Well indices and connection statuses must match the completion cells.');
    conductance = W.WI(:) .* sum(mobility, 2) .* ...
        W.cstatus(:) .* wellSol.cstatus(:);
    total = sum(conductance);
    assert(isfinite(total) && total > 0, 'H2sim:BiochemistryShutInConductance', ...
        'Shut-in BHP requires a positive total completion conductance.');
    cellPressure = state.pressure(cells);
    assert(all(isfinite(cellPressure)) && all(cellPressure > 0), ...
        'H2sim:BiochemistryShutInPressure', ...
        'Completion pressures must be finite and positive.');
    % MRST sums phase mobilities on injection and production connections.
    % Its crossflow phase redistribution preserves this total volume rate.
    pressure = sum((conductance / total) .* cellPressure(:));
    residual = sum(conductance .* (pressure - cellPressure(:)));
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
