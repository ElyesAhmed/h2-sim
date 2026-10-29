function initializeH2simPhreeqc(rootDirectory)
    % INITIALIZEH2SIMPHREEQC Set up pinned PhreeqcMatlab paths and libraries.
    %
    % SYNOPSIS:
    %   startupH2sim
    %   initializeH2simPhreeqc
    %
    % Equivalent to the chemistry portion of startupH2sim('phreeqc', true).
    % This explicit request may fetch the pinned submodule and download missing
    % native libraries. Provide them beforehand for offline initialization.
    % Windows sequential coupling also requires a registered IPhreeqcCOM server.
    % On Linux, launch MATLAB with the required native-library runtime first;
    % the terminal launcher provides this setup through its --phreeqc flag.
    % An optional rootDirectory selects a checkout explicitly.
    if nargin == 0
        rootDirectory = fileparts(fileparts(mfilename('fullpath')));
    end
    ensureH2simSubmodule(rootDirectory, 'PhreeqcMatlab');
    run(fullfile(rootDirectory, 'submodules', 'PhreeqcMatlab', 'startup.m'));
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
