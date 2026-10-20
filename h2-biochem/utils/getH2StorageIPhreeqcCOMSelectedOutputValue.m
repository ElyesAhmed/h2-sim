function selected = getH2StorageIPhreeqcCOMSelectedOutputValue(headers, values, aliases, context)
% Return the last selected-output value matching one normalized alias.

if nargin < 4 || isempty(context)
    context = 'IPhreeqcCOM selected output';
end
assert(iscell(aliases) && ~isempty(aliases), ...
    'aliases must be a nonempty cell array.');
aliases = cellfun(@(x) lower(regexprep(char(x), '[^a-zA-Z0-9]', '')), ...
    aliases, 'UniformOutput', false);
column = find(ismember(headers, aliases), 1);
assert(~isempty(column), ...
    '%s is missing "%s". Available columns: %s', context, aliases{1}, ...
    strjoin(headers, ', '));
selected = values(end, column);
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
