classdef Storage2DExampleOptionsTest < matlab.unittest.TestCase
    % Reject ambiguous step limits and bad cases before expensive grid setup.
    methods (Test)
        function rejectsFractionalStepLimits(test)
            test.verifyError(@() exampleCompositionalBacterial2DThreeReactions( ...
                'maximumFlowSteps', 1.5, 'plotResults', false), ...
                'H2sim:StorageStepLimit');
        end

        function rejectsUnknownScenarioBeforeReadingDeck(test)
            test.verifyError(@() exampleCompositionalBacterial2DThreeReactions( ...
                'scenarios', {'unknown'}, 'deckFile', [tempname, '.DATA'], ...
                'plotResults', false), ...
                'MATLAB:exampleCompositionalBacterial2DThreeReactions:unrecognizedStringChoice');
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
