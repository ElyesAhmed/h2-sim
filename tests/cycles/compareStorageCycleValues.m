function compareStorageCycleValues(actual, expected, location)
    % COMPARESTORAGECYCLEVALUES Compare cycle arrays with quantity tolerances.
    % Pressure/BHP: 0.01 Pa absolute plus 1e-9 relative. Other quantities:
    % 1e-10 absolute plus 1e-7 relative. Field presence and sizes must match.
    if nargin < 3
        location = 'cycle';
    end
    if isstruct(actual)
        assert(isstruct(expected) && isequal(fieldnames(actual), fieldnames(expected)), ...
            'h2sim:cycles:Fields', 'Reference fields differ at %s.', location);
        fields = fieldnames(actual);
        for k = 1:numel(fields)
            field = fields{k};
            compareStorageCycleValues(actual.(field), expected.(field), ...
                [location, '.', field]);
        end
    elseif iscell(actual)
        assert(iscell(expected) && numel(actual) == numel(expected), ...
            'h2sim:cycles:Size', 'Reference length differs at %s.', location);
        for k = 1:numel(actual)
            compareStorageCycleValues(actual{k}, expected{k}, ...
                sprintf('%s{%d}', location, k));
        end
    else
        assert(isnumeric(actual) && isnumeric(expected) && isequal(size(actual), size(expected)), ...
            'h2sim:cycles:Size', 'Reference dimensions differ at %s.', location);
        absolute = 1e-10;
        relative = 1e-7;
        if endsWith(location, '.pressure') || endsWith(location, '.bhp')
            absolute = 0.01;
            relative = 1e-9;
        end
        if any(abs(actual - expected) > absolute + relative * abs(expected), 'all')
            fprintf('CYCLE_DIFFERENCE path=%s actual=%s expected=%s maxAbs=%.17g\n', ...
                location, mat2str(actual, 17), mat2str(expected, 17), ...
                max(abs(actual - expected), [], 'all'));
        end
        assert(all(isfinite(actual), 'all') && all(isfinite(expected), 'all') && ...
            all(abs(actual - expected) <= absolute + relative * abs(expected), 'all'), ...
            'h2sim:cycles:Difference', 'Numerical regression at %s.', location);
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
