classdef H2StorePVTOTest < matlab.unittest.TestCase
    %H2STOREPVTOTEST PVTO block ordering for scalar and vector pressure grids.
    properties (TestParameter)
        nusat = {1, 3, 30}
    end
    methods (Test)
        function undersaturatedRecords(test, nusat)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            p = [10; 20; 40; 60]*barsa;
            T = repmat(313.15, size(p));
            water = table(T-273.15, p, 1000*exp(1e-9*(p-40*barsa)), ...
                repmat(1e-3, size(p)), 'VariableNames', ...
                {'# temperature [°C]', 'pressure [Pa]', 'density [kg/m3]', 'viscosity [Pa.s]'});
            gas = water;
            gas.("density [kg/m3]") = p*0.002016./(8.314462618*T);
            gas.("viscosity [Pa.s]") = repmat(9e-6, size(p));
            sol = HenrySetschenowH2BrineEos(T, 1, p);
            getFluidH2BrineProps(water, gas, sol, 'rs', true, 'rv', false, ...
                'plot', false, 'nusat', nusat, 'outputPath', folder);
            file = fullfile(folder, 'fixture.DATA');
            fid = fopen(file, 'w');
            test.assertGreaterThanOrEqual(fid, 0);
            fprintf(fid, ['RUNSPEC\nMETRIC\nDIMENS\n1 1 1 /\nOIL\nGAS\n' ...
                'DISGAS\nGRID\nPROPS\nINCLUDE\n''PVTO_UHS.txt'' /\nEND\n']);
            fclose(fid);
            deck = convertDeckUnits(readEclipseDeck(file));
            pvto = deck.PROPS.PVTO{1};
            % Four requested bubble points plus the writer's low-Rs endpoint.
            test.verifyNumElements(pvto.key, 5);
            test.verifyEqual(diff(pvto.pos), repmat(nusat+1, 5, 1));
            test.verifyTrue(all(isfinite(pvto.data), 'all'));
            test.verifyGreaterThan(pvto.data(:, 2:3), 0);
            for k = 1:5
                rows = pvto.pos(k):pvto.pos(k+1)-1;
                pressures = pvto.data(rows, 1);
                expected = linspace(pressures(1), 1.2*max(p), nusat+1)';
                test.verifyEqual(pressures, expected, 'AbsTol', 1e-3);
                test.verifyGreaterThan(diff(pressures), 0);
            end
        end
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
