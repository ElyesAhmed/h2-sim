classdef H2StoreWaterDensityTest < matlab.unittest.TestCase
    %H2STOREWATERDENSITYTEST Temperature-salinity density and array inputs.
    methods (Test)
        function scalarReferences(test)
            ref = reference();
            for i = 1:numel(ref.temperature)
                for j = 1:numel(ref.salinity)
                    test.verifyEqual(calculateRoweChouWaterDensity( ...
                        ref.temperature(i), ref.salinity(j)), ref.density(i,j), ...
                        'AbsTol', 1e-10, 'RelTol', 1e-13);
                end
            end
        end
        function pairedVectors(test)
            T = [288.15; 313.15; 373.15]; S = [0; 0.035; 0.1];
            expected = arrayfun(@calculateRoweChouWaterDensity, T, S);
            test.verifyEqual(calculateRoweChouWaterDensity(T, S), expected, 'AbsTol', 1e-10);
            test.verifyEqual(calculateRoweChouWaterDensity(T', S'), expected', 'AbsTol', 1e-10);
        end
        function temperatureSalinityGrid(test)
            ref = reference();
            actual = calculateRoweChouWaterDensity(ref.temperature(:), ref.salinity(:)');
            test.verifySize(actual, size(ref.density));
            test.verifyEqual(actual, ref.density, 'AbsTol', 1e-10, 'RelTol', 1e-13);
        end
        function scalarExpansion(test)
            T = [288.15; 313.15; 373.15];
            expected = arrayfun(@(t) calculateRoweChouWaterDensity(t, 0.035), T);
            test.verifyEqual(calculateRoweChouWaterDensity(T, 0.035), expected, 'AbsTol', 1e-10);
            S = [0, 0.035, 0.1];
            expected = arrayfun(@(s) calculateRoweChouWaterDensity(313.15, s), S);
            test.verifyEqual(calculateRoweChouWaterDensity(313.15, S), expected, 'AbsTol', 1e-10);
        end
        function basicDensitySanity(test)
            rho = calculateRoweChouWaterDensity(298.15, [0, 0.035, 0.1, 0.25]);
            test.verifyTrue(all(isfinite(rho)));
            test.verifyGreaterThan(diff(rho), 0);
            test.verifyEqual(rho(1), 997, 'AbsTol', 1);
        end
    end
end

function ref = reference()
    ref = jsondecode(fileread(fullfile(fileparts(mfilename('fullpath')), ...
        'water-density-reference.json')));
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
