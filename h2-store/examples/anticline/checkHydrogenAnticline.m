function diagnostics = checkHydrogenAnticline(result)
    % CHECKHYDROGENANTICLINE Bounds and hydrogen inventory/flux accounting.
    %
    % Inventories and integrated gas exchanges use surface cubic metres.
    % Pressure boundaries are included explicitly. Shut-in well rates are
    % multiplied by their active flag because MRST can retain a previous rate.
    model = result.model;
    states = [{result.state0}; result.states(:)];
    count = numel(states);
    inventory = zeros(count, 1);
    boundaryRates = zeros(count - 1, 1);
    wellRates = zeros(count - 1, 1);
    maximumSaturation = zeros(count, 1);
    for index = 1:count
        state = states{index};
        assert(all(isfinite(state.pressure)) && all(state.pressure > 0), ...
            'H2sim:AnticlinePressure', 'Pressure must be finite and positive.');
        assert(all(isfinite(state.s(:))) && all(state.s(:) >= -1e-8) && ...
            all(state.s(:) <= 1 + 1e-8) && ...
            all(abs(sum(state.s, 2) - 1) < 1e-8), ...
            'H2sim:AnticlineSaturation', 'Invalid phase saturation.');
        [factors, pv] = model.getProps(state, 'ShrinkageFactors', 'PoreVolume');
        gas = model.getPhaseIndex('G');
        inventory(index) = sum(value(pv .* state.s(:, gas) .* factors{gas}));
        maximumSaturation(index) = max(state.s(:, gas));
        if index == 1
            continue
        end
        step = index - 1;
        control = result.schedule.control(result.schedule.step.control(step));
        wellRates(step) = result.wellSolutions{step}.qGs * control.W.status;
        [pressures, saturations, mobility, density, b] = model.getProps(state, ...
            'PhasePressures', 's', 'Mobility', 'Density', 'ShrinkageFactors');
        if ~iscell(saturations)
            saturations = expandMatrixToCell(saturations);
        end
        if ~iscell(density)
            density = expandMatrixToCell(density);
        end
        q = getBoundaryConditionFluxesAD(model, pressures, saturations, ...
            mobility, density, b, control.bc);
        boundaryRates(step) = sum(value(q{gas}));
    end
    duration = result.schedule.step.val;
    integrated = cumsum(duration .* (wellRates + boundaryRates));
    residual = inventory(2:end) - inventory(1) - integrated;
    scale = max(1, max(abs(integrated)));
    maximumError = max(abs(residual)) / scale;
    assert(maximumError < 1e-5, 'H2sim:AnticlineMassBalance', ...
        'Hydrogen inventory residual %g exceeds 1e-5 relative.', maximumError);
    diagnostics = struct('hydrogenSurfaceVolumeM3', inventory, ...
        'wellGasSurfaceRateM3PerSecond', wellRates, ...
        'boundaryGasSurfaceRateM3PerSecond', boundaryRates, ...
        'hydrogenBalanceResidualM3', residual, ...
        'maximumRelativeHydrogenBalanceError', maximumError, ...
        'maximumGasSaturation', maximumSaturation);
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
