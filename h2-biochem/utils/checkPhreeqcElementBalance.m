function state = checkPhreeqcElementBalance(state, inputInventory, outputInventory, ...
    elements, options, backend)
% Validate and store per-cell PHREEQC elemental conservation diagnostics.

assert(isequal(size(inputInventory), size(outputInventory)) && ...
    size(inputInventory, 2) == numel(elements), ...
    'PHREEQC input/output element inventories must be nc-by-nelement arrays.');
assert(all(isfinite(inputInventory(:))) && all(isfinite(outputInventory(:))), ...
    'PHREEQC element inventories must be finite.');

ne = numel(elements);
absTol = tolerance(options, 'phreeqcElementBalanceAbsoluteTolerance', 1e-7, ne);
relTol = tolerance(options, 'phreeqcElementBalanceRelativeTolerance', 1e-8, ne);
absoluteResidual = abs(outputInventory - inputInventory);
scale = max(abs(inputInventory), abs(outputInventory));
normalizedResidual = zeros(size(scale));
nonzero = scale > 0;
normalizedResidual(nonzero) = absoluteResidual(nonzero)./scale(nonzero);
normalizedResidual(~nonzero & absoluteResidual > 0) = inf;
limit = bsxfun(@plus, absTol, bsxfun(@times, scale, relTol));
pass = absoluteResidual <= limit;

state.phreeqcElementBalanceElements = elements;
state.phreeqcElementBalanceInput = inputInventory;
state.phreeqcElementBalanceOutput = outputInventory;
state.phreeqcElementBalanceAbsoluteResidual = absoluteResidual;
state.phreeqcElementBalanceNormalizedResidual = normalizedResidual;
state.phreeqcElementBalancePass = pass;

if ~all(pass(:))
    [cellNo, elementNo] = find(~pass, 1);
    warning('H2Biochem:PhreeqcElementBalance', ...
        ['PHREEQC elemental conservation failed for backend "%s", cell %d, ', ...
         'element %s: input=%.16g mol, output=%.16g mol, absolute ', ...
         'residual=%.16g mol, normalized residual=%.16g (limit %.16g mol).'], ...
        backend, cellNo, elements{elementNo}, inputInventory(cellNo, elementNo), ...
        outputInventory(cellNo, elementNo), absoluteResidual(cellNo, elementNo), ...
        normalizedResidual(cellNo, elementNo), limit(cellNo, elementNo));
end
end

function values = tolerance(options, field, default, ne)
if isfield(options, field)
    values = options.(field);
else
    values = default;
end
validateattributes(values, {'numeric'}, {'vector', 'real', 'finite', 'nonnegative'}, ...
    mfilename, field);
if isscalar(values)
    values = repmat(values, 1, ne);
else
    values = reshape(values, 1, []);
    assert(numel(values) == ne, ...
        '%s must be scalar or contain one value per audited element.', field);
end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).

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
