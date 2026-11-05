function data = aquiferPresentationData(result)
    % AQUIFERPRESENTATIONDATA Inventories and active well history for plotting.
    %
    % Uses the initial and saved accepted states. Volumes are surface m^3;
    % rates are surface m^3/day, time days and pressure bar. Dissolved hydrogen
    % is phase partitioning, not irreversible consumption. Shut-in rates are
    % zero and shut-in well BHP is NaN because saved well values may be stale.
    % Stage endpoints follow stage names, including ramped-rate controls.
    states = [{result.state0}; result.states(:)];
    data.times = [0; cumsum(result.schedule.step.val)] / day;
    assert(numel(states) == numel(data.times), 'H2sim:AquiferStateCount', ...
        'One saved state is required for each schedule step.');
    model = result.model.setupStateFunctionGroupings();
    data.dissolved = zeros(numel(states), 1);
    data.free = data.dissolved;
    data.rate = zeros(numel(states) - 1, 1);
    data.bhp = nan(size(data.rate));
    data.stages = cell(size(data.rate));
    for k = 1:numel(states)
        state = states{k};
        pv = value(model.getProp(state, 'PoreVolume'));
        b = model.getProp(state, 'ShrinkageFactors');
        data.dissolved(k) = sum(pv .* state.s(:, 1) .* value(b{1}) .* state.rs);
        data.free(k) = sum(pv .* state.s(:, 2) .* value(b{2}));
        if k > 1
            well = result.schedule.control(result.schedule.step.control(k - 1)).W(1);
            data.stages{k - 1} = well.stage;
            if well.status
                data.rate(k - 1) = result.wellSols{k - 1}(1).qGs * day;
                data.bhp(k - 1) = result.wellSols{k - 1}(1).bhp / barsa;
            end
        end
    end
    data.total = data.dissolved + data.free;
    data.fraction = 100 * data.dissolved ./ max(data.total, eps);
    changes = ~strcmp(data.stages(1:end - 1), data.stages(2:end));
    data.endpoints = find([changes; true]) + 1;
    data.saturationMaximum = max(0.01, max(cellfun(@(s) max(s.s(:, 2)), states)));
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
