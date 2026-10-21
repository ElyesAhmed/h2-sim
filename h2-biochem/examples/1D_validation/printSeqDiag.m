% Print diagnostics for an existing multirate summary (legacy script).
%
% SYNOPSIS:
%   summary = exampleSequentialBiochemistryPhreeqc1D(...);
%   printSeqDiag
%
% The script reads summary from the caller workspace and prints diagnostics.
% New code should use diagnostics = reportMultirateDiagnostics(summary).
% The old incidental loop/helper variables are no longer created. No saved
% states, model, summary or solver settings are modified.

reportMultirateDiagnostics(summary);

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
