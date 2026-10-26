classdef BiochemistryPhreeqcConfigurationTest < matlab.unittest.TestCase
    properties
        baseModel
        initialState
    end

    methods (TestClassSetup)
        function setupModel(test)
            [~, test.baseModel, ~, test.initialState] = ...
                setupH2StorageExampleWithSRB_benchmark('gridCells', 3);
        end
    end

    methods (Test)
        function validationPreservesExistingChemistryHistory(test)
            model = construct(test.baseModel);
            % No wells are used in these state-validation checks.
            model.FacilityModel = [];
            model.bacteriamodel = true;
            model.carbonateBuffer = true;
            model.sulfateReduction = true;
            model.phreeqcTimestepCoupling = true;
            state = test.initialState;
            fields = {'nbact', 'tracerHCO3', 'tracerSO4', 'tracerHS', ...
                'h2sDissolvedLag', 'phreeqcPH', 'phreeqcCarbonatePka1', ...
                'tracerCa', 'tracerMg'};
            for k = 1:numel(fields)
                state.(fields{k}) = (1:model.G.cells.num)'*k;
            end
            state.sequentialCompositionalPhreeqcFirstStepBiomassConventionApplied = true;
            state.sequentialCompositionalPhreeqcBiomassMET = [1; 2; 3]*1e-12;
            state.phreeqcMineralCalcite = [0; 1; 2];
            actual = model.validateState(state);
            fields = [fields, {'sequentialCompositionalPhreeqcFirstStepBiomassConventionApplied', ...
                'sequentialCompositionalPhreeqcBiomassMET', 'phreeqcMineralCalcite'}];
            for k = 1:numel(fields)
                test.verifyEqual(actual.(fields{k}), state.(fields{k}), fields{k});
            end
        end

        function validationInitializesOnlyEnabledStateGroups(test)
            model = construct(test.baseModel);
            % No wells are used in these state-validation checks.
            model.FacilityModel = [];
            fields = {'nbact', 'tracerHCO3', 'tracerSO4', 'tracerHS', ...
                'h2sDissolvedLag', 'phreeqcPH', 'phreeqcCarbonatePka1', ...
                'tracerCa', 'tracerMg'};
            state = test.initialState;
            state = rmfield(state, intersect(fieldnames(state), fields));
            model.bacteriamodel = false;
            model.carbonateBuffer = false;
            model.sulfateReduction = false;
            model.phreeqcTimestepCoupling = false;
            actual = model.validateState(state);
            test.verifyFalse(any(isfield(actual, fields)));
            model.bacteriamodel = true;
            model.carbonateBuffer = true;
            model.sulfateReduction = true;
            model.phreeqcTimestepCoupling = true;
            actual = model.validateState(state);
            defaults = [1e6, 0, 0, 0, 0, model.carbonateBufferPH, ...
                model.carbonateBufferPka1, 0, 0];
            for k = 1:numel(fields)
                test.verifyEqual(actual.(fields{k}), ...
                    repmat(defaults(k), model.G.cells.num, 1), fields{k});
            end
        end

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
