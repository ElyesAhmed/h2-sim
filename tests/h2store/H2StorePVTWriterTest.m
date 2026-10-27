classdef H2StorePVTWriterTest < matlab.unittest.TestCase
    %H2STOREPVTWRITERTEST Gas/brine table records, units and file reuse.
    properties (TestParameter)
        dissolution = {false, true}
        keyword = {'PVDO', 'PVTO', 'PVTG'}
    end
    methods (Test)
        function gasPressureBlocks(test, dissolution)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            [water, gas, sol, p] = inputs();
            getFluidH2BrineProps(water, gas, sol, 'rs', dissolution, 'rv', true, ...
                'plot', false, 'nusat', 3, 'outputPath', folder);
            props = readProperties(folder, 'PVTG');
            data = props.PVTG{1};
            test.verifyEqual(data.key, p, 'AbsTol', 1e-3);
            test.verifyEqual(diff(data.pos), 2*ones(4, 1));
            y = sol.y_H2O;
            expectedRv = 0.0851/998.207150467 * (y*18.01528e-3)./((1-y)*2.016e-3);
            for k = 1:4
                rows = data.pos(k):data.pos(k+1)-1;
                test.verifyEqual(data.data(rows, 1), [expectedRv(k); 0], ...
                    'RelTol', 1e-10, 'AbsTol', 1e-16);
                test.verifyEqual(data.data(rows, 3), repmat(9e-6, 2, 1), 'AbsTol', 1e-14);
                test.verifyGreaterThan(data.data(rows, 2), 0);
                test.verifyEqual(data.data(rows(1), 2), data.data(rows(2), 2));
            end
            test.verifyTrue(all(isfinite(data.data), 'all'));
        end
        function immiscibleBrineRecords(test)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            [water, gas, sol, p] = inputs();
            getFluidH2BrineProps(water, gas, sol, 'rs', false, 'rv', false, ...
                'plot', false, 'outputPath', folder);
            props = readProperties(folder, 'PVDO');
            data = props.PVDO{1};
            test.verifySize(data, [4, 3]);
            test.verifyEqual(data(:,1), p, 'AbsTol', 1e-3);
            test.verifyEqual(data(:,2), 998.207150467./water.("density [kg/m3]"), 'RelTol', 1e-9);
            test.verifyEqual(data(:,3), repmat(1e-3, 4, 1), 'AbsTol', 1e-14);
        end
        function keepsExistingTable(test, keyword)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            [water, gas, sol] = inputs();
            rs = strcmp(keyword, 'PVTO');
            rv = strcmp(keyword, 'PVTG');
            getFluidH2BrineProps(water, gas, sol, 'rs', rs, 'rv', rv, ...
                'plot', false, 'nusat', 3, 'outputPath', folder);
            file = fullfile(folder, [keyword, '_UHS.txt']);
            original = fileread(file);
            water.("viscosity [Pa.s]") = 2*water.("viscosity [Pa.s]");
            gas.("viscosity [Pa.s]") = 2*gas.("viscosity [Pa.s]");
            getFluidH2BrineProps(water, gas, sol, 'rs', rs, 'rv', rv, ...
                'plot', false, 'nusat', 3, 'reCompute', false, 'outputPath', folder);
            test.verifyEqual(fileread(file), original);
        end
    end
end

function [water, gas, sol, p] = inputs()
    p = [10;20;40;60]*barsa;
    T = repmat(313.15, size(p));
    water = table(T-273.15, p, 1000*exp(1e-9*(p-40*barsa)), ...
        repmat(1e-3, size(p)), 'VariableNames', ...
        {'# temperature [°C]', 'pressure [Pa]', 'density [kg/m3]', 'viscosity [Pa.s]'});
    gas = water;
    gas.("density [kg/m3]") = p*0.002016./(8.314462618*T);
    gas.("viscosity [Pa.s]") = repmat(9e-6, size(p));
    sol = HenrySetschenowH2BrineEos(T, 1, p);
    sol.y_H2O = 7000./p;
end

function props = readProperties(folder, keyword)
    file = fullfile(folder, 'fixture.DATA');
    fid = fopen(file, 'w');
    assert(fid >= 0, 'Could not create test deck.');
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'RUNSPEC\nMETRIC\nDIMENS\n1 1 1 /\nOIL\nGAS\n');
    if strcmp(keyword, 'PVTG'), fprintf(fid, 'VAPOIL\n'); end
    fprintf(fid, 'GRID\nPROPS\nINCLUDE\n''%s_UHS.txt'' /\nEND\n', keyword);
    clear cleanup;
    deck = convertDeckUnits(readEclipseDeck(file));
    props = deck.PROPS;
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
