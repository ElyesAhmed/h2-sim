function diagnostics = checkHydrogenMixing2D(result)
    % CHECKHYDROGENMIXING2D Check bounds and closed-system component masses.
    % Returns total component masses [kg] and maximum relative mass errors.
    % Reference agreement is not inferred from these physical checks.
    model = result.model;
    states = [{result.state0}; result.states(:)];
    masses = zeros(numel(states), 2);
    hydrogenDepth = zeros(numel(states), 1);
    for index = 1:numel(states)
        state = states{index};
        assert(all(isfinite(state.pressure)) && all(state.pressure > 0), ...
            'H2sim:MixingPressure', 'Pressure must be finite and positive.');
        z = state.components;
        assert(all(isfinite(z(:))) && all(z(:) >= -1e-10) && ...
            all(z(:) <= 1 + 1e-10) && all(abs(sum(z, 2) - 1) < 1e-8), ...
            'H2sim:MixingComposition', 'Invalid component fractions.');
        assert(all(isfinite(state.s(:))) && all(state.s(:) >= -1e-10) && ...
            all(state.s(:) <= 1 + 1e-10) && ...
            all(abs(sum(state.s, 2) - 1) < 1e-8), ...
            'H2sim:MixingSaturation', 'Invalid phase saturations.');
        componentMass = model.getProp(state, 'ComponentTotalMass');
        for component = 1:2
            masses(index, component) = sum(value(componentMass{component}));
        end
        hydrogenMass = value(componentMass{1});
        hydrogenDepth(index) = sum(hydrogenMass .* ...
            model.G.cells.centroids(:, 3)) / masses(index, 1);
    end
    relativeError = abs(masses ./ masses(1, :) - 1);
    maximum = max(relativeError, [], 1);
    assert(all(maximum < 1e-5), 'H2sim:MixingMassBalance', ...
        'Component mass errors [%g, %g] exceed 1e-5 relative.', maximum(1), maximum(2));
    diagnostics = struct('componentMassKg', masses, ...
        'maximumRelativeMassError', maximum, ...
        'hydrogenMeanDepthM', hydrogenDepth);
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
