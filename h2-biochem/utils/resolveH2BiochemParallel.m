function enabled = resolveH2BiochemParallel(requested, availabilityCheck)
    % RESOLVEH2BIOCHEMPARALLEL Keep serial workflows usable without optional PCT.
    % Serial is the default. A requested parallel flash falls back to serial
    % when Parallel Computing Toolbox or its license is unavailable.
    validateattributes(requested, {'logical'}, {'scalar'});
    if ~requested
        enabled = false;
        return
    end
    if nargin < 2
        availabilityCheck = @() license('test', 'Distrib_Computing_Toolbox') && ~isempty(ver('parallel'));
    end
    validateattributes(availabilityCheck, {'function_handle'}, {'scalar'});
    enabled = logical(availabilityCheck());
    if ~enabled
        warning('H2Biochem:ParallelUnavailable', ...
            'Parallel Computing Toolbox is unavailable; using serial pressure flashes.');
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
