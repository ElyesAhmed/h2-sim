classdef PhreeqcElementBalanceWarningTest < matlab.unittest.TestCase
% Reporting frequency must not alter conservation results or leak across cases.
    methods (TestMethodSetup)
        function configureWarnings(test)
            saved = warning('query', 'H2Biochem:PhreeqcElementBalance');
            trace = warning('query', 'backtrace');
            test.addTeardown(@() warning(saved));
            test.addTeardown(@() warning(trace));
            warning('on', 'H2Biochem:PhreeqcElementBalance');
            warning('off', 'backtrace');
        end
    end
    methods (Test)
        function repeatedFailureRetainsFullAuditWithoutSpam(test)
            [input, output, options] = fixture();
            [state, first] = audit(struct(), input, output, options, 'case');
            [next, second] = audit(state, input, output, options, 'case');
            test.verifyTrue(contains(first, 'PHREEQC elemental conservation failed'));
            test.verifyFalse(contains(second, 'PHREEQC elemental conservation failed'));
            test.verifyEqual(next.phreeqcElementBalancePass, state.phreeqcElementBalancePass);
            test.verifyFalse(next.phreeqcElementBalancePass(1, 1));
            test.verifyEqual(next.phreeqcElementBalanceAbsoluteResidual, ...
                state.phreeqcElementBalanceAbsoluteResidual);
            history = next.phreeqcElementBalanceWarningHistory;
            test.verifyEqual([history.failedCalls, history.reportedCalls, history.suppressedCalls], [2, 1, 1]);
        end

        function newElementIsReported(test)
            [input, output, options] = fixture();
            [state, ~] = audit(struct(), input, output, options, 'case');
            output(2, 2) = input(2, 2) + 3e-7;
            [state, text] = audit(state, input, output, options, 'case');
            test.verifyTrue(contains(text, 'element S:'));
            test.verifyFalse(state.phreeqcElementBalancePass(2, 2));
        end

        function tenfoldWorseningIsReported(test)
            [input, output, options] = fixture();
            [state, ~] = audit(struct(), input, output, options, 'case');
            output(1, 1) = input(1, 1) + 1.8e-6;
            [state, quiet] = audit(state, input, output, options, 'case');
            test.verifyFalse(contains(quiet, 'PHREEQC elemental conservation failed'));
            output(1, 1) = input(1, 1) + 2.2e-6;
            [~, louder] = audit(state, input, output, options, 'case');
            test.verifyTrue(contains(louder, 'PHREEQC elemental conservation failed'));
        end

        function alwaysModeKeepsPerCallWarningsAndMath(test)
            [input, output, options] = fixture();
            [once, ~] = audit(struct(), input, output, options, 'case');
            options.phreeqcElementBalanceWarningMode = 'always';
            [state, first] = audit(struct(), input, output, options, 'case');
            [state, second] = audit(state, input, output, options, 'case');
            test.verifyTrue(contains(first, 'PHREEQC elemental conservation failed'));
            test.verifyTrue(contains(second, 'PHREEQC elemental conservation failed'));
            fields = {'Input', 'Output', 'AbsoluteResidual', 'NormalizedResidual', 'Pass'};
            for k = 1:numel(fields)
                field = ['phreeqcElementBalance', fields{k}];
                test.verifyEqual(state.(field), once.(field));
            end
            test.verifyEqual(state.phreeqcElementBalanceWarningHistory.reportedCalls, 2);
        end

        function explicitlyDisabledWarningCanBeReenabled(test)
            [input, output, options] = fixture();
            warning('off', 'H2Biochem:PhreeqcElementBalance');
            [state, quiet] = audit(struct(), input, output, options, 'case');
            test.verifyFalse(contains(quiet, 'PHREEQC elemental conservation failed'));
            test.verifyFalse(state.phreeqcElementBalancePass(1, 1));
            warning('on', 'H2Biochem:PhreeqcElementBalance');
            [~, text] = audit(state, input, output, options, 'case');
            test.verifyTrue(contains(text, 'PHREEQC elemental conservation failed'));
        end

        function historySurvivesRestartButDoesNotLeak(test)
            [input, output, options] = fixture();
            [state, ~] = audit(struct(), input, output, options, 'case');
            file = [tempname, '.mat'];
            test.addTeardown(@() delete(file));
            save(file, 'state', '-v7'); loaded = load(file, 'state');
            [~, quiet] = audit(loaded.state, input, output, options, 'case');
            [~, fresh] = audit(struct(), input, output, options, 'case');
            [other, backend] = audit(state, input, output, options, 'other');
            test.verifyFalse(contains(quiet, 'PHREEQC elemental conservation failed'));
            test.verifyTrue(contains(fresh, 'PHREEQC elemental conservation failed'));
            test.verifyTrue(contains(backend, 'PHREEQC elemental conservation failed'));
            test.verifyNumElements(other.phreeqcElementBalanceWarningHistory, 2);
        end

        function zeroToleranceDoesNotSpamInfiniteRatio(test)
            [input, output, options] = fixture();
            options.phreeqcElementBalanceAbsoluteTolerance = 0;
            [state, first] = audit(struct(), input, output, options, 'case');
            [~, second] = audit(state, input, output, options, 'case');
            test.verifyTrue(contains(first, 'PHREEQC elemental conservation failed'));
            test.verifyFalse(contains(second, 'PHREEQC elemental conservation failed'));
        end

        function passingAndInvalidInventoriesRemainDistinct(test)
            [input, ~, options] = fixture();
            [state, text] = audit(struct(), input, input, options, 'case');
            test.verifyTrue(all(state.phreeqcElementBalancePass(:)));
            test.verifyFalse(isfield(state, 'phreeqcElementBalanceWarningHistory'));
            test.verifyFalse(contains(text, 'PHREEQC elemental conservation failed'));
            bad = input; bad(1) = nan;
            test.verifyError(@() checkPhreeqcElementBalance(struct(), input, bad, ...
                {'H', 'S'}, options, 'case'), ?MException);
            options.phreeqcElementBalanceWarningMode = 'off';
            test.verifyError(@() checkPhreeqcElementBalance(struct(), input, input, ...
                {'H', 'S'}, options, 'case'), ?MException);
        end
    end
end

function [input, output, options] = fixture()
    input = ones(2, 2); output = input; output(1, 1) = output(1, 1) + 2e-7;
    options = struct('phreeqcElementBalanceAbsoluteTolerance', 1e-7, ...
        'phreeqcElementBalanceRelativeTolerance', 0);
end

function [state, text] = audit(state, input, output, options, backend)
    text = evalc('state = checkPhreeqcElementBalance(state, input, output, {''H'', ''S''}, options, backend);');
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
