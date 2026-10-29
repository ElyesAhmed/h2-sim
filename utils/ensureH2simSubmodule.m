function ensureH2simSubmodule(rootdirname, name)
    % Clone the git submodule ``name`` (under ``submodules/<name>``) if it is not already present,
    % checking out the commit that is pinned for it in the H2sim repository (see ``.gitmodules``).

    submodulepath = fullfile(rootdirname, 'submodules', name);

    if exist(fullfile(submodulepath, 'startup.m'), 'file')
        % Already downloaded
        return
    end

    if ~(isfolder(fullfile(rootdirname, '.git')) || isfile(fullfile(rootdirname, '.git')))
        error('h2sim:missingGitRepo', ['Cannot auto-download the ''%s'' submodule because\n  %s\n' ...
            'is not a git checkout. Please install H2sim using ' ...
            '''git clone --recurse-submodules'' as described in the documentation ' ...
            '(doc/installation.rst), or download ''%s'' manually into ''%s''.'], ...
            name, rootdirname, name, submodulepath);
    end

    fprintf('Submodule ''%s'' was not found, downloading it now (this may take a while)...\n', name);

    relpath = strrep(fullfile('submodules', name), filesep, '/');
    cmd = sprintf('git -C "%s" submodule update --init --recursive -- "%s"', rootdirname, relpath);
    [status, cmdout] = system(cmd);

    if status ~= 0 || ~exist(fullfile(submodulepath, 'startup.m'), 'file')
        error('h2sim:submoduleSetupFailed', ['Failed to download the ''%s'' submodule automatically.\n' ...
            'Command: %s\nOutput:\n%s\n\n' ...
            'You can also do it manually by running from the H2sim root:\n' ...
            '  git submodule update --init --recursive -- %s'], ...
            name, cmd, cmdout, relpath);
    end

    fprintf('Submodule ''%s'' downloaded (pinned commit, matching the tested H2sim version).\n\n', name);

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
