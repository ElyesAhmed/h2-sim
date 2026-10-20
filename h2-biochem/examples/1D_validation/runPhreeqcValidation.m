function result = runPhreeqcValidation(varargin)
%Compare compositional PHREEQC with an optional external reference
%
% SYNOPSIS:
%   result = runPhreeqcValidation()
%   result = runPhreeqcValidation('referenceRoot', referenceRoot)
%
% DESCRIPTION:
%   Run the storage-cycle comparison in exampleCompositionalPhreeqcValidation.
%   The default case uses only H2sim and the bundled chemistry database.
%   Supply referenceRoot to add an external comparison. Simulations run
%   serially and save setups, states, and diagnostics for plotting. Only
%   the optional external reference requires Windows MATLAB with COM.
%
% PARAMETERS:
%   Pass name/value options to exampleCompositionalPhreeqcValidation.
%
% SEE ALSO:
%   exampleCompositionalPhreeqcValidation, plotCompositionalPhreeqcValidation

    result = exampleCompositionalPhreeqcValidation(varargin{:});
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
