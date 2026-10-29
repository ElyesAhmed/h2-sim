function [model, state0, schedule, cleanup] = setupPhreeqcCycle()
    % SETUPPHREEQCCYCLE Four-cell reactive injection, shut-in and production.
    [~, base, schedule, state0] = setupH2StorageExampleWithSRB_benchmark( ...
        'scheduleMode', 'complete', 'gridCells', 4, 'domainLength', 5, ...
        'injectionCO2', 0, 'initialOverallCO2', 0, ...
        'equilibrateInitialCO2', false, 'carbonateBuffer', true, ...
        'carbonateBufferPH', 6.24, 'initialHCO3', 1.370e-3, ...
        'bactDiffusion', false, 'chemotaxisEffect', false, ...
        'molecularDiffusion', false, 'molecularDispersion', false, ...
        'bioClogging', false, 'paperBiomassKinetics', true, 'nbact0', 1, ...
        'phreeqcTimestepCoupling', true, ...
        'phreeqcBackend', 'sequential-h2biochem-phreeqc', ...
        'phreeqcDatabaseFile', which('h2_biogeochemistry.dat'));
    model = convertToSequentialBiochemistryPhreeqcModel(base, ...
        'reactionSubstepMaxDt', 0.2 * day);
    schedule.step.val = repmat(0.4 * day, 6, 1);
    schedule.step.control = repelem((1:3)', 2);
    schedule.control(2).W.status = false;
    % Withdraw at a fraction of the injection rate to exercise production
    % even when reaction shrinkage lowers pressure during shut-in.
    schedule.control(3).W.type = 'rate';
    schedule.control(3).W.val = -0.2 * schedule.control(1).W.val;
    schedule.control(3).W.lims = [];
    cleanup = onCleanup(@() []);
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
