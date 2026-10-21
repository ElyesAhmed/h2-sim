classdef BiochemistryPhreeqcConfigurationTest < matlab.unittest.TestCase
    properties
        baseModel
    end

    methods (TestClassSetup)
        function setupModel(test)
            [~, test.baseModel] = setupH2StorageExampleWithSRB_benchmark('gridCells', 3);
        end
    end

    methods (Test)
        function normalizesBackendAndFlagsWithoutEngine(test)
            model = construct(test.baseModel, 'phreeqcBackend', ...
                ' SEQUENTIAL-H2BIOCHEM-PHREEQC ', 'carbonateBuffer', true);
            test.verifyEqual(model.phreeqcBackend, 'sequential-h2biochem-phreeqc');
            test.verifyTrue(model.carbonateBuffer);
            test.verifyFalse(model.phreeqcTimestepCoupling);
            test.verifyEmpty(model.phreeqcDatabaseFile);
        end

        function rejectsInvalidAndReservedOptions(test)
            options = {{'phreeqcBackend', 'unknown'}, {'carbonateBuffer', 2}, ...
                {'sequentialSplitActive', true}, ...
                {'sequentialH2BiochemPhreeqcPicardActive', true}, ...
                {'bacterialDecayOrder', 3}, {'carbonateBuffer', NaN}};
            for k = 1:numel(options)
                test.verifyError(@() construct(test.baseModel, options{k}{:}), ?MException);
            end
        end

        function validatesDatabaseOnlyWhenCouplingEnabled(test)
            file = fullfile(tempname, 'h2_biogeochemistry.dat');
            model = construct(test.baseModel, 'phreeqcDatabaseFile', file);
            test.verifyEqual(model.phreeqcDatabaseFile, file);
            test.verifyError(@() construct(test.baseModel, ...
                'phreeqcTimestepCoupling', true, 'phreeqcDatabaseFile', file), ?MException);
        end

        function acceptsCouplingDatabaseFallback(test)
            file = which('h2_biogeochemistry.dat');
            model = construct(test.baseModel, 'carbonateBuffer', true, ...
                'phreeqcTimestepCoupling', true, ...
                'phreeqcCouplingOptions', struct('databaseFile', file));
            test.verifyEmpty(model.phreeqcDatabaseFile);
            test.verifyEqual(model.phreeqcCouplingOptions.databaseFile, file);
            test.verifyTrue(model.isSequentialCompositionalPhreeqcBackend());
        end

        function explicitDatabaseTakesPrecedenceAndCouplingNeedsTracers(test)
            file = which('h2_biogeochemistry.dat');
            model = construct(test.baseModel, 'carbonateBuffer', true, ...
                'phreeqcTimestepCoupling', true, 'phreeqcDatabaseFile', file, ...
                'phreeqcCouplingOptions', struct('databaseFile', 'missing.dat'));
            test.verifyEqual(model.phreeqcDatabaseFile, file);
            test.verifyError(@() construct(test.baseModel, ...
                'phreeqcTimestepCoupling', true, 'phreeqcDatabaseFile', file, ...
                'carbonateBuffer', false), ?MException);
        end
    end
end

function model = construct(base, varargin)
    model = BiochemistryPhreeqcModel(base.G, base.rock, base.fluid, ...
        base.compFluid, base.biochemFluid, base.water, base.AutoDiffBackend, ...
        varargin{:});
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
