function root = h2simRoot()
    % Return the absolute root directory of this H2sim checkout
    %
    % SYNOPSIS:
    %   root = h2simRoot();
    %
    % RETURNS:
    %   root - Directory containing startupH2sim.m, independent of the caller's
    %          current folder. Resolve bundled data relative to this directory.

    root = fileparts(fileparts(mfilename('fullpath')));
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
