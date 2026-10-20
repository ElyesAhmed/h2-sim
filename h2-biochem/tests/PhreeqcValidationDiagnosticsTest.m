classdef PhreeqcValidationDiagnosticsTest < matlab.unittest.TestCase
    methods (Test)
        function countsOnlyActivePrescribedInjection(test)
            result = fixture();
            diagnostics = collectPhreeqcValidationDiagnostics(result);
            test.verifyEqual(diagnostics.h2sim.injectedMoles, 2, 'AbsTol', 1e-12);
            test.verifyEqual(diagnostics.h2sim.lossPercent, [10.5; 21], 'AbsTol', 1e-12);
            test.verifyEqual(diagnostics.h2sim.timeDays, [2; 4]);
            test.verifyEqual(diagnostics.h2sim.consumption, ...
                diagnostics.reference.consumption, 'AbsTol', 1e-14);
            test.verifyEqual(diagnostics.h2sim.lossPercent, ...
                diagnostics.reference.lossPercent, 'AbsTol', 1e-12);
        end

        function supportsStandaloneChemistry(test)
            result = fixture();
            result = rmfield(result, 'reference');
            diagnostics = collectPhreeqcValidationDiagnostics(result);
            test.verifyEqual(fieldnames(diagnostics), {'h2sim'});
            test.verifyEqual(diagnostics.h2sim.lossPercent, [10.5; 21], 'AbsTol', 1e-12);
        end

        function readsPreviouslySavedReferenceData(test)
            result = fixture();
            expected = collectPhreeqcValidationDiagnostics(result);
            result.ugfact = result.reference;
            result = rmfield(result, 'reference');
            test.verifyEqual(collectPhreeqcValidationDiagnostics(result), expected);
        end

        function rejectsMissingStepsAndZeroInjection(test)
            result = fixture();
            result.h2sim.states = result.h2sim.states(1);
            test.verifyError(@() collectPhreeqcValidationDiagnostics(result), ...
                'H2sim:ValidationStateCount');
            result = fixture();
            result.h2sim.schedule.control(1).W.status = false;
            test.verifyError(@() collectPhreeqcValidationDiagnostics(result), ...
                'H2sim:ValidationInjection');
        end

        function checksExplicitReferenceBeforeSimulation(test)
            test.verifyError(@() runPhreeqcValidation('referenceRoot', tempname), ...
                'H2sim:ReferenceDriverNotFound');
        end

        function plotsWithAndWithoutReferenceData(test)
            visible = get(groot, 'DefaultFigureVisible');
            set(groot, 'DefaultFigureVisible', 'off');
            test.addTeardown(@() set(groot, 'DefaultFigureVisible', visible));
            test.addTeardown(@() close(findall(groot, 'Type', 'figure')));
            result = fixture();
            figures = plotCompositionalPhreeqcValidation(result);
            test.verifyEqual(numel(figures), 3);
            test.verifyEqual(numel(findall(figures(1), 'Type', 'axes')), 3);
            close(figures);
            result = rmfield(result, 'reference');
            figures = plotCompositionalPhreeqcValidation(result);
            test.verifyEqual(numel(findall(figures(1), 'Type', 'axes')), 2);
            test.verifyEqual(numel(findall(figures(2), 'Type', 'axes')), 2);
            lines = findall(figures(1), 'Type', 'line');
            test.verifyEqual(numel(lines), 1);
            test.verifyEqual(lines.YData, [10.5, 21], 'AbsTol', 1e-12);
        end
    end
end

function result = fixture()
    pressure = 101325;
    temperature = 288.15;
    model = struct('G', struct('cells', ...
        struct('num', 2, 'centroids', [0.5, 0; 1.5, 0])), ...
        'biochemFluid', struct('nbioreact', 3), 'getVaporIndex', @() 2, ...
        'FacilityModel', struct('pressure', pressure, 'T', temperature));
    well = struct('sign', 1, 'status', true, 'type', 'rate', ...
        'val', 8.314462618*temperature/pressure/day, ...
        'compi', [0, 1], 'components', [0, 1, 0]);
    closed = well;
    closed.status = false;
    closed.val = 100*well.val;
    schedule = struct('control', struct('W', {well, closed}), ...
        'step', struct('val', [2; 2]*day, 'control', [1; 2]));
    increment = [1, 2, 3; 4, 5, 6]/100;
    states = cell(2, 1);
    reference = states;
    for k = 1:2
        states{k} = struct('x', [0.9, 0.1; 0.8, 0.2], 'phreeqcPH', [6; 7], ...
            'phreeqcTotalCarbon', [0.001; 0.002], ...
            'cumulativeH2ConsumptionMoles', k*increment);
        solution = struct('pH', [6; 7], 'TotalDIC', [0.001; 0.002], ...
            'Water', [1000; 1000], 'MET_Rate', increment(:, 1)/2, ...
            'ACE_Rate', increment(:, 2)/2, 'SRB_Rate', increment(:, 3)/2);
        reference{k} = struct('x', states{k}.x, 'Solution', solution);
    end
    result = struct('h2sim', struct('model', model, 'schedule', schedule, ...
        'states', {states}), 'reference', struct('model', model, ...
        'schedule', schedule, 'states', {reference}));
end

%{
Copyright 2026 H2sim contributors.

This file is part of H2sim.

H2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

H2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with H2sim. If not, see <https://www.gnu.org/licenses/>.
%}
