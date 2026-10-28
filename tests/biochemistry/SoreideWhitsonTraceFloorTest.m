classdef SoreideWhitsonTraceFloorTest < matlab.unittest.TestCase
    % Trace-component phase partitioning must survive normalization roundoff.
    methods (Test)

        function floorNeighborsHaveIdenticalPhaseUpdates(test)
            eos = makeEOS();
            minimum = eos.minimumComposition;
            reference = update(eos, minimum);
            offsets = [-4, -1, 1, 4] * eps(minimum);
            for k = 1:numel(offsets)
                actual = update(eos, minimum + offsets(k));
                test.verifyEqual(actual, reference);
            end
        end

        function resolvedTraceComponentStillUpdatesEquilibriumConstant(test)
            eos = makeEOS();
            minimum = eos.minimumComposition;
            atFloor = update(eos, minimum);
            aboveFloor = update(eos, 1.01 * minimum);
            test.verifyEqual(atFloor{3}(3), 10);
            test.verifyEqual(atFloor{7}(3), 0);
            test.verifyNotEqual(aboveFloor{3}(3), 10);
            test.verifyGreaterThan(aboveFloor{7}(3), 0);
        end

    end
end

function eos = makeEOS()
    fluid = TableCompositionalMixture({'Water', 'Hydrogen', 'HydrogenSulfide'});
    eos = SoreideWhitsonEos([], fluid, 'msalt', 2.865);
end

function result = update(eos, traceFraction)
    z = [0.9, 0.1 - traceFraction, traceFraction];
    result = cell(1, 7);
    [result{:}] = eos.substitutionCompositionUpdate( ...
        150 * barsa, 333.15, z, [0.005, 1000, 10], 0.9);
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
