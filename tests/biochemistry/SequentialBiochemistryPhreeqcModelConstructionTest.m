classdef SequentialBiochemistryPhreeqcModelConstructionTest < matlab.unittest.TestCase
    % Construction/configuration validation for SequentialBiochemistryPhreeqcModel.
    %
    % These tests deliberately never enable phreeqcTimestepCoupling, so they
    % require neither a PHREEQC database file nor a registered IPhreeqcCOM
    % server: every scenario here is rejected by SequentialBiochemistry-
    % PhreeqcModel's own constructor-time validation before any PHREEQC-
    % specific code path would be reached. They therefore always run, with
    % no assumption-based skipping needed.
    %
    % SEE ALSO:
    %   SequentialBiochemistryPhreeqcModel, BiochemistryPhreeqcModel

    properties
        G
        rock
        fluid
        compFluid
        biochemFluid
        includeWater
        backend
    end

    properties (TestParameter)
        % Each entry is a cell array of extra property/value pairs passed
        % to the SequentialBiochemistryPhreeqcModel constructor (on top
        % of a valid grid/rock/fluid/compFluid/biochemFluid and, unless
        % overridden here, a valid reactionSubstepMaxDt), that must be
        % rejected during construction.
        invalidOptions = struct( ...
            'missingReactionSubstepMaxDt', struct('options', {{}}), ...
            'negativeReactionSubstepMaxDt', ...
            struct('options', {{'reactionSubstepMaxDt', -0.1}}), ...
            'zeroReactionSubstepMaxDt', ...
            struct('options', {{'reactionSubstepMaxDt', 0}}), ...
            'nonScalarReactionSubstepMaxDt', ...
            struct('options', {{'reactionSubstepMaxDt', [0.1, 0.2]}}), ...
            'nonFiniteReactionSubstepMaxDt', ...
            struct('options', {{'reactionSubstepMaxDt', Inf}}), ...
            'couplingDisabledByDefault', ...
            struct('options', {{'reactionSubstepMaxDt', 0.4 * day}}), ...
            'wrongBackendWithCouplingDisabled', ...
            struct('options', {{'reactionSubstepMaxDt', 0.4 * day, ...
            'phreeqcBackend', 'sequential-compositional-phreeqc'}}))
    end

    methods (TestClassSetup)

        function setupSharedComponents(testCase)
            mrstModule add ad-core ad-props compositional deckformat;
            [~, model] = setupH2StorageExampleWithSRB_benchmark( ...
                'gridCells', 3, 'domainLength', 5, 'scheduleMode', 'injection');
            testCase.G            = model.G;
            testCase.rock         = model.rock;
            testCase.fluid        = model.fluid;
            testCase.compFluid    = model.compFluid;
            testCase.biochemFluid = model.biochemFluid;
            testCase.includeWater = model.water;
            testCase.backend      = model.AutoDiffBackend;
        end

    end

    methods (Access = private)

        function model = constructModel(testCase, varargin)
            model = SequentialBiochemistryPhreeqcModel(testCase.G, testCase.rock, ...
                testCase.fluid, testCase.compFluid, testCase.biochemFluid, ...
                testCase.includeWater, testCase.backend, varargin{:});
        end

    end

    methods (Test)

        function testInvalidConfigurationIsRejected(testCase, invalidOptions)
            testCase.verifyError( ...
                @() testCase.constructModel(invalidOptions.options{:}), ...
                ?MException);
        end

        function testValidConfigurationConstructsWithFlowAndReactionStages(testCase)
            % flowNonLinearSolver/reactionNonLinearSolver are deliberately
            % left at their defaults here to prove the model builds
            % successfully with a bare-minimum valid configuration. A
            % syntactically valid, existing h2_biogeochemistry.dat path is
            % required by BiochemistryPhreeqcModel's constructor-time
            % validation whenever phreeqcTimestepCoupling is true, even
            % though construction alone never opens a live IPhreeqcCOM
            % connection; skip cleanly (via assumeTrue) if none is found.
            databaseFile = resolveConstructionTestDatabaseFile();
            testCase.assumeTrue(~isempty(databaseFile), ...
                'No h2_biogeochemistry.dat could be found on this machine.');
            model = testCase.constructModel('reactionSubstepMaxDt', 0.4 * day, ...
                'phreeqcBackend', 'sequential-h2biochem-phreeqc', ...
                'phreeqcTimestepCoupling', true, ...
                'phreeqcDatabaseFile', databaseFile, ...
                'carbonateBuffer', true, 'carbonateBufferPH', 6.24);
            testCase.verifyClass(model.flowStageModel, 'BiochemistryPhreeqcModel');
            testCase.verifyClass(model.reactionStageModel, 'BiochemistryPhreeqcModel');
            testCase.verifyFalse(isa(model.flowStageModel, ...
                'SequentialBiochemistryPhreeqcModel'));
            testCase.verifyFalse(isa(model.reactionStageModel, ...
                'SequentialBiochemistryPhreeqcModel'));
        end

        function testInvalidFlowNonLinearSolverTypeIsRejected(testCase)
            % Isolated from the parameterized table above because it must
            % reach past the phreeqcTimestepCoupling/backend checks (and
            % therefore needs a database file) to actually exercise the
            % flowNonLinearSolver type validation; skip cleanly if no
            % h2_biogeochemistry.dat can be found.
            databaseFile = resolveConstructionTestDatabaseFile();
            testCase.assumeTrue(~isempty(databaseFile), ...
                'No h2_biogeochemistry.dat could be found on this machine.');
            testCase.verifyError(@() testCase.constructModel( ...
                'reactionSubstepMaxDt', 0.4 * day, ...
                'phreeqcBackend', 'sequential-h2biochem-phreeqc', ...
                'phreeqcTimestepCoupling', true, ...
                'phreeqcDatabaseFile', databaseFile, ...
                'carbonateBuffer', true, 'carbonateBufferPH', 6.24, ...
                'flowNonLinearSolver', 'not-a-solver'), ...
                ?MException);
        end

        function testReactionSubstepMaxDtIsStoredOnModel(testCase)
            databaseFile = resolveConstructionTestDatabaseFile();
            testCase.assumeTrue(~isempty(databaseFile), ...
                'No h2_biogeochemistry.dat could be found on this machine.');
            model = testCase.constructModel('reactionSubstepMaxDt', 0.4 * day, ...
                'phreeqcBackend', 'sequential-h2biochem-phreeqc', ...
                'phreeqcTimestepCoupling', true, ...
                'phreeqcDatabaseFile', databaseFile, ...
                'carbonateBuffer', true, 'carbonateBufferPH', 6.24);
            testCase.verifyEqual(model.reactionSubstepMaxDt, 0.4 * day);
        end

    end
end

function databaseFile = resolveConstructionTestDatabaseFile()
    % Best-effort h2_biogeochemistry.dat lookup. Returns '' (rather than
    % throwing) when the database cannot be located, so calling tests can
    % gate on it via assumeTrue and skip cleanly.
    databaseFile = getenv('PHREEQC_DATABASE_FILE');
    if isempty(strtrim(databaseFile))
        databaseFile = which('h2_biogeochemistry.dat');
    end
    if isempty(strtrim(databaseFile)) || ~isfile(databaseFile)
        databaseFile = '';
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
