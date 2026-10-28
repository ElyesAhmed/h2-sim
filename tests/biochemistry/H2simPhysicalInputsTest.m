classdef H2simPhysicalInputsTest < matlab.unittest.TestCase
    methods (Test)

        function rejectsOriginalWellErrorsEvenWhenClosed(test)
            [s, m, q] = fixture();
            for h2 = [0.958, 0.998]
                q.control.W.components = [0.001, h2, 0.001, 0.05];
                test.verifyError(@() validateH2simSimulationInputs(s, m, q), 'H2sim:InvalidFractions');
            end
        end

        function acceptsCorrectedClosedWell(test)
            [s, m, q] = fixture();
            validateH2simSimulationInputs(s, m, q);
            test.verifyEqual(sum(q.control.W.components), 1, 'AbsTol', 1e-12);
        end

        function rejectsInvalidInitialStates(test)
            [s, m, q] = fixture();
            bad = s;
            bad.components = [0.9, 0.1, 0.1, 0];
            test.verifyError(@() validateH2simSimulationInputs(bad, m, q), 'H2sim:InvalidFractions');
            bad = s;
            bad.s = [1.1, -0.1];
            test.verifyError(@() validateH2simSimulationInputs(bad, m, q), 'H2sim:InvalidFractions');
            bad = s;
            bad.pressure = NaN;
            test.verifyError(@() validateH2simSimulationInputs(bad, m, q), 'H2sim:InvalidPressure');
            bad = s;
            bad.T = -10;
            test.verifyError(@() validateH2simSimulationInputs(bad, m, q), 'H2sim:InvalidTemperature');
            bad = s;
            bad.nbact = -1;
            test.verifyError(@() validateH2simSimulationInputs(bad, m, q), 'H2sim:InvalidBiomass');
        end

        function rejectsBadControlAndPhaseFractions(test)
            [s, m, q] = fixture();
            bad = q;
            bad.step.control = 2;
            test.verifyError(@() validateH2simSimulationInputs(s, m, bad), 'H2sim:InvalidSchedule');
            bad = q;
            bad.control.W.compi = [0, 1.05];
            test.verifyError(@() validateH2simSimulationInputs(s, m, bad), 'H2sim:InvalidFractions');
        end

    end
end

function [s, m, q] = fixture()
    mrstModule add compositional ad-core ad-props;
    G = computeGeometry(cartGrid([1, 1, 1]));
    rock = makeRock(G, 1e-12, 0.2);
    f = initSimpleADIFluid('phases', 'OG', 'rho', [1000, 1]);
    c = h2BiochemCompositionalMixture({'Water', 'Hydrogen', 'Methane', 'CarbonDioxide'}, {'H2O', 'H2', 'C1', 'CO2'});
    m = BiochemistryModel(G, rock, f, c, TableBioChemMixture({'MethanogenicArchae'}), true, DiagonalAutoDiffBackend(), 'water', false);
    s = struct('pressure', 1e7, 'T', 313.15, 's', [0.8, 0.2], 'components', [0.9, 0.045, 0.005, 0.05], 'nbact', 1);
    q = simpleSchedule(day);
    q.control.W = struct('components', [0.001, 0.948, 0.001, 0.05], 'compi', [0, 1], 'status', false);
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
