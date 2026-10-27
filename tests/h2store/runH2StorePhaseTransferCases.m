function cases = runH2StorePhaseTransferCases()
%RUNH2STOREPHASETRANSFERCASES Closed, four-cell black-oil PVT regressions.
% Synthetic pure-fluid data avoid network access. Local solubility, SGOF and
% PVT writers are exercised before MRST reads the generated deck tables.
% Oil denotes brine, gas denotes hydrogen. Inventories are surface volumes.
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() rmdir(folder, 's'));
    G = computeGeometry(cartGrid([4, 1, 1], [4, 1, 1]));
    rock = makeRock(G, 100*milli*darcy, 0.2);
    p = (5:5:100)'*barsa;
    T = repmat(313.15, size(p));
    water = table(T-273.15, p, 1000*exp(1e-9*(p-40*barsa)), ...
        repmat(1e-3, size(p)), 'VariableNames', ...
        {'# temperature [°C]', 'pressure [Pa]', 'density [kg/m3]', 'viscosity [Pa.s]'});
    rhoG = p*0.002016./(8.314462618*T.*calculateBrillBreggsZfactorHydrogen(T, p));
    gas = water;
    gas.("density [kg/m3]") = rhoG;
    gas.("viscosity [Pa.s]") = repmat(9e-6, size(p));
    solubility = HenrySetschenowH2BrineEos(T, 1, p);
    % A prescribed 7 kPa water partial pressure, not a vapor-pressure model.
    solubility.y_H2O = 7000./p;
    getFluidH2BrineSGOF('plot', false, 'n', 21, 'outputPath', folder);
    names = {'dissolution', 'vaporization', 'combined'};
    cases = struct();
    for k = 1:3
        disgas = k ~= 2;
        vapoil = k ~= 1;
        getFluidH2BrineProps(water, gas, solubility, ...
            'rs', disgas, 'rv', vapoil, 'plot', false, ...
            'nusat', 3, 'outputPath', folder);
        deckFile = writeFixtureDeck(folder, p, rhoG, disgas, vapoil);
        deck = convertDeckUnits(readEclipseDeck(deckFile));
        fluid = initDeckADIFluid(deck, 'ignoreErrors', false);
        model = GenericBlackOilModel(G, rock, fluid, 'water', false, ...
            'disgas', disgas, 'vapoil', vapoil, 'gravity', [0, 0, 0]);
        model.minimumPressure = barsa;
        state0 = initResSol(G, [38; 39; 41; 42]*barsa, [0.8, 0.2]);
        state0.rs = zeros(4, 1);
        state0.rv = zeros(4, 1);
        if disgas
            state0.rs = fluid.rsSat(state0.pressure);
        end
        if vapoil
            state0.rv = fluid.rvSat(state0.pressure + fluid.pcOG(state0.s(:, 2)));
        end
        schedule = simpleSchedule([10; 10]);
        solver = NonLinearSolver('maxIterations', 20);
        [~, states, report] = simulateScheduleAD(state0, model, schedule, ...
            'NonLinearSolver', solver);
        assert(all(report.Converged) && numel(states) == 2, ...
            'h2sim:h2store:PhaseTransferConvergence', 'Phase-transfer case failed.');
        snapshots = cellfun(@(s) snapshot(s, fluid, rock, G, disgas, vapoil), ...
            [{state0}; states], 'UniformOutput', false);
        cases.(names{k}) = [snapshots{:}];
    end
end

function data = snapshot(state, fluid, rock, G, disgas, vapoil)
    p = state.pressure;
    saturated = true(size(p));
    if disgas
        bO = fluid.bO(p, state.rs, saturated);
    else
        bO = fluid.bO(p);
    end
    pG = p + fluid.pcOG(state.s(:, 2));
    if vapoil
        bG = fluid.bG(pG, state.rv, saturated);
    else
        bG = fluid.bG(pG);
    end
    oil = rock.poro.*G.cells.volumes.*state.s(:, 1).*bO;
    gas = rock.poro.*G.cells.volumes.*state.s(:, 2).*bG;
    data = struct('pressure', p, 'saturation', state.s, ...
        'rs', state.rs, 'rv', state.rv, 'dissolved', oil.*state.rs, ...
        'vaporized', gas.*state.rv, ...
        'inventory', [sum(oil + gas.*state.rv); sum(gas + oil.*state.rs)]);
end

function file = writeFixtureDeck(folder, p, rhoG, disgas, vapoil)
    file = fullfile(folder, 'fixture.DATA');
    fid = fopen(file, 'w');
    assert(fid >= 0, 'Could not create test deck.');
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'RUNSPEC\nMETRIC\nDIMENS\n4 1 1 /\nOIL\nGAS\n');
    if disgas
        fprintf(fid, 'DISGAS\n');
    end
    if vapoil
        fprintf(fid, 'VAPOIL\n');
    end
    fprintf(fid, 'GRID\nPROPS\nDENSITY\n998.207150467 1000 0.0851 /\n');
    include(fid, 'SGOF_UHS.txt');
    if disgas
        include(fid, 'PVTO_UHS.txt');
    else
        include(fid, 'PVDO_UHS.txt');
    end
    if vapoil
        include(fid, 'PVTG_UHS.txt');
    else
        % The local writer has no dry-gas PVDG output. This test-only table
        % supplies the disabled-vaporization branch from the same gas data.
        fprintf(fid, 'PVDG\n');
        fprintf(fid, '%.12g %.12g %.12g\n', [p/barsa, 0.0851./rhoG, ...
            repmat(0.009, size(p))]');
        fprintf(fid, '/\n');
    end
    fprintf(fid, 'END\n');
end

function include(fid, name)
    fprintf(fid, 'INCLUDE\n''%s'' /\n', name);
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
