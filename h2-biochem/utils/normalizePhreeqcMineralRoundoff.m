function [reservoirs, correction, mineralMoles, minerals] = normalizePhreeqcMineralRoundoff(reservoirs, waterMass, absoluteTolerance)
% Handle signed phase-boundary residuals in PHREEQC's kg-water normalization.
% The wrapper uses an explicit 1e-10 mol/kg-water phase-roundoff bound.
% This is distinct from PHREEQC's relative equation-convergence criterion.
% A correction must also be below 0.1 percent of every affected elemental
% absolute tolerance.
% Conservation is then checked against the non-negative physical inventory.
minerals = {'calcite','dolomite','anhydrite','gypsum','goethite', ...
    'pyrite','brucite','portlandite'};
waterMass = waterMass(:);
validateattributes(waterMass, {'numeric'}, {'real','finite','positive'});
nc = numel(waterMass);
mineralMoles = zeros(nc, numel(minerals));
fields = fieldnames(reservoirs);
roundoff = reservoirs;
for k = 1:numel(fields), roundoff.(fields{k}) = zeros(nc, 1); end
for k = 1:numel(minerals)
    name = minerals{k}; v = reservoirs.(name)(:);
    assert(numel(v)==nc && all(isfinite(v)), ...
        'H2Biochem:InvalidPhreeqcMineral', 'Invalid PHREEQC mineral %s.', name);
    negative = v < 0;
    assert(all(v(negative) >= -1e-10.*waterMass(negative)), ...
        'H2Biochem:InvalidPhreeqcMineral', ...
        'PHREEQC mineral %s exceeds the normalized phase-roundoff bound.', name);
    mineralMoles(negative,k) = -v(negative);
    roundoff.(name) = mineralMoles(:,k);
    v(negative) = 0; reservoirs.(name) = v;
end
correction = computePhreeqcElementInventory(roundoff);
validateattributes(absoluteTolerance, {'numeric'}, {'real','finite','nonnegative','vector'});
if isscalar(absoluteTolerance), absoluteTolerance = repmat(absoluteTolerance,1,6); end
assert(numel(absoluteTolerance)==6, 'Expected six elemental absolute tolerances.');
limit = 1e-3.*reshape(absoluteTolerance,1,6);
assert(all(correction <= limit, 'all'), ...
    'H2Biochem:InvalidPhreeqcMineral', ...
    'PHREEQC mineral roundoff correction exceeds 0.1 percent of the elemental absolute tolerance.');
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
