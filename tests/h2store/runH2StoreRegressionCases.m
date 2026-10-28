function result = runH2StoreRegressionCases()
    % RUNH2STOREREGRESSIONCASES Small, deterministic oil-gas storage checks.
    % Brine occupies the oil phase. Generated local SGOF data and the hydrogen
    % Z correlation supply the fluid properties. These synthetic cases check
    % numerical stability across edits; they do not validate the correlations.
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() rmdir(folder, 's'));
    getFluidH2BrineSGOF('plot', false, 'n', 21, 'outputPath', folder);
    fid = fopen(fullfile(folder, 'SGOF_UHS.txt'), 'r');
    tables = readSGOFTables(fid, 'SGOF', 1, 4);
    sgof = tables{1};
    G = computeGeometry(cartGrid([4, 1, 1], [4, 1, 1]));
    rock = makeRock(G, 100 * milli * darcy, 0.2);
    p0 = 40 * barsa;
    Z = calculateBrillBreggsZfactorHydrogen(313.15, p0);
    rhoGas = p0 * 0.002016 / (8.314462618 * 313.15 * Z);
    result = struct();
    for k = 1:2
        fluid = initSimpleADIFluid('phases', 'OG', ...
            'mu', [1e-3, 9e-6], 'rho', [1000, rhoGas], ...
            'c', [1e-9, 1 / p0], 'pRef', p0, 'n', [2, 2]);
        fluid.krG = @(s) interpTable(sgof(:, 1), sgof(:, 2), s);
        fluid.krO = @(s) interpTable(1 - flipud(sgof(:, 1)), ...
            flipud(sgof(:, 3)), s);
        model = GenericBlackOilModel(G, rock, fluid, 'water', false, ...
            'disgas', false, 'vapoil', false, 'gravity', [0, 0, 0]);
        state0 = initResSol(G, p0, [0.8, 0.2]);
        if k == 1
            bc = pside([], G, 'LEFT', p0 + barsa, 'sat', [0, 1]);
            bc = pside(bc, G, 'RIGHT', p0, 'sat', [1, 0]);
            schedule = simpleSchedule([10; 10], 'bc', bc);
            name = 'injection';
        else
            state0.pressure = p0 + [1; 0; 0; -1] * barsa;
            schedule = simpleSchedule([10; 10]);
            name = 'closed';
        end
        solver = NonLinearSolver('maxIterations', 20);
        [~, states, report] = simulateScheduleAD(state0, model, schedule, ...
            'NonLinearSolver', solver);
        assert(all(report.Converged) && numel(states) == 2, ...
            'h2sim:h2store:RegressionConvergence', 'Storage case failed.');
        result.(name).pressure = cellfun(@(s) s.pressure, states, 'UniformOutput', false);
        result.(name).saturation = cellfun(@(s) s.s, states, 'UniformOutput', false);
    end
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
