function result = exampleHydrogenAnticline(varargin)
    % EXAMPLEHYDROGENANTICLINE Simulate cushion injection and cyclic storage.
    %
    % SYNOPSIS:
    %   result = exampleHydrogenAnticline()
    %   result = exampleHydrogenAnticline('horizontalCells', [9, 9])
    %
    % Returns actual accepted states, well solutions and inventory diagnostics.
    % Setup options are passed to setupHydrogenAnticline. No figures or files
    % are created. Use animateHydrogenAnticline to render the saved result.
    [model, state0, schedule, configuration] = setupHydrogenAnticline(varargin{:});
    solver = NonLinearSolver('maxIterations', 25, 'maxTimestepCuts', 12);
    timer = tic;
    [wells, states, report] = simulateScheduleAD(state0, model, schedule, ...
        'nonlinearSolver', solver);
    elapsed = toc(timer);
    assert(~report.Failure && numel(states) == numel(schedule.step.val), ...
        'H2sim:AnticlineIncomplete', 'The anticline schedule did not finish.');
    result = struct('model', model, 'state0', state0, 'states', {states}, ...
        'wellSolutions', {wells}, 'schedule', schedule, ...
        'configuration', configuration, 'report', report, ...
        'elapsedSeconds', elapsed);
    result.diagnostics = checkHydrogenAnticline(result);
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
