classdef H2StoreSGOFTest < matlab.unittest.TestCase
    % H2STORESGOFTEST Region ordering, permeability bounds and file ownership.
    properties (TestParameter)
        points = {2, 11, 100}
        regions = {1, 2}
    end
    methods (Test)

        function regionRoundTrip(test, points, regions)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            sw = [0.1, 0.2];
            sg = [0.1, 0.15];
            entry = [0.4, 0.8];
            bound = [9.5e4, 1.2e5];
            getFluidH2BrineSGOF('plot', false, 'n', points, 'nreg', regions, ...
                'sw_imm', sw, 'sg_imm', sg, 'Pe', entry, 'P_c_max', bound, ...
                'outputPath', folder, 'fileName', 'regions.txt');
            fid = fopen(fullfile(folder, 'regions.txt'), 'r');
            test.assertGreaterThanOrEqual(fid, 0);
            tables = readSGOFTables(fid, 'SGOF', regions, 4);
            test.verifyFalse(ismember(fid, openFileIdentifiers()));
            test.verifySize(tables, [regions, 1]);
            for k = 1:regions
                data = tables{k};
                test.verifySize(data, [points, 4]);
                test.verifyTrue(all(isfinite(data), 'all'));
                test.verifyEqual(data([1, end], 1:3), [0, 0, 1; 1, 1, 0]);
                test.verifyGreaterThanOrEqual(diff(data(:, 1:2)), 0);
                test.verifyLessThanOrEqual(diff(data(:, 3)), 0);
                test.verifyGreaterThanOrEqual(diff(data(:, 4)), 0);
                test.verifyGreaterThanOrEqual(data(:, 2:3), 0);
                test.verifyLessThanOrEqual(data(:, 2:3), 1);
                % Metric deck capillary pressure is stored in bar.
                test.verifyEqual(data(end, 4), bound(k) / 1e5, 'AbsTol', 1e-8);
            end
            if regions == 2
                test.verifyNotEqual(tables{1}(:, 4), tables{2}(:, 4));
            end
        end

        function keepsExistingFile(test)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            getFluidH2BrineSGOF('plot', false, 'n', 11, 'outputPath', folder);
            file = fullfile(folder, 'SGOF_UHS.txt');
            original = fileread(file);
            getFluidH2BrineSGOF('plot', false, 'n', 100, ...
                'reCompute', false, 'outputPath', folder);
            test.verifyEqual(fileread(file), original);
        end

        function closesMalformedInput(test)
            file = tempname;
            cleanup = onCleanup(@() delete(file));
            fid = fopen(file, 'w');
            fprintf(fid, '-- SG KRG KROG PCOG\nSGOF\n0 0 1 /\n');
            fclose(fid);
            fid = fopen(file, 'r');
            caught = false;
            try
                readSGOFTables(fid, 'SGOF', 1, 4);
            catch
                caught = true;
            end
            test.verifyTrue(caught, 'Malformed region must raise an error.');
            test.verifyFalse(ismember(fid, openFileIdentifiers()));
        end

    end
end

function identifiers = openFileIdentifiers()
    if exist('openedFiles', 'builtin') || exist('openedFiles', 'file')
        identifiers = openedFiles();
    else
        identifiers = fopen('all');
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
