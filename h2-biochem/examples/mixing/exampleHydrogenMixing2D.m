function result = exampleHydrogenMixing2D(varargin)
    % EXAMPLEHYDROGENMIXING2D Simulate binary hydrogen-methane segregation.
    %
    % SYNOPSIS:
    %   result = exampleHydrogenMixing2D()
    %   result = exampleHydrogenMixing2D('gridSize', [20, 20])
    %
    % Pass setup options through to setupHydrogenMixing2D. Returns the model,
    % initial and accepted states, schedule, parameters and conservation
    % diagnostics. No plots or files are created. Call animateHydrogenMixing2D
    % separately to render saved results without repeating the simulation.
    [model, state0, schedule, parameters] = setupHydrogenMixing2D(varargin{:});
    solver = NonLinearSolver('maxIterations', 20, 'maxTimestepCuts', 10);
    [wellSolutions, states, report] = simulateScheduleAD( ...
        state0, model, schedule, 'nonlinearSolver', solver);
    assert(~report.Failure && numel(states) == numel(schedule.step.val), ...
        'H2sim:MixingIncomplete', 'Hydrogen mixing did not finish its schedule.');
    result = struct('model', model, 'state0', state0, 'states', {states}, ...
        'schedule', schedule, 'parameters', parameters, ...
        'wellSolutions', {wellSolutions}, 'report', report);
    result.diagnostics = checkHydrogenMixing2D(result);
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
