function startupH2sim(varargin)
    % STARTUPH2SIM Initialize core H2sim modules and optional PHREEQC tools.
    %
    % SYNOPSIS:
    %   startupH2sim
    %   startupH2sim('phreeqc', true)
    %
    % Core startup initializes the pinned MRST dependency and H2sim modules.
    % It does not initialize, fetch or check PhreeqcMatlab. Opt in for chemistry
    % library setup, or call initializeH2simPhreeqc after core startup.
    % Existing chemistry paths or loaded libraries are not removed.

    % A recursively added MRST tree can leave Octave compatibility shims on
    % MATLAB's saved path. In particular, properties.m breaks parpool settings
    % discovery. Remove these paths from every MRST installation before startup.
    if exist('OCTAVE_VERSION', 'builtin') == 0
        savedPaths = strsplit(path, pathsep);
        normalizedPaths = strrep(savedPaths, '\', '/');
        octavePaths = ~cellfun(@isempty, ...
            regexp(normalizedPaths, '/octave_only(/|$)', 'once'));
        if any(octavePaths)
            rmpath(savedPaths{octavePaths});
            clear properties maxNumCompThreads;
            rehash path;
        end
    end

    parser = inputParser();
    parser.FunctionName = mfilename;
    parser.PartialMatching = false;
    addParameter(parser, 'phreeqc', false, @(x) islogical(x) && isscalar(x));
    parse(parser, varargin{:});

    fprintf('\n  /-\\\n | + | H2Sim\n  \\-/\n\n');
    fprintf('Welcome to the H2 Storage Modeling Toolbox (H2sim)!\n');
    fprintf('H2sim is based on MRST, which will now be initialized.\n\n');

    rootdirname = fileparts(mfilename('fullpath'));

    %% Initialize the core simulation dependency
    addpath(rootdirname);
    addpath(fullfile(rootdirname, 'utils'));
    ensureH2simSubmodule(rootdirname, 'mrst');

    run(fullfile(rootdirname, 'submodules', 'mrst', 'startup'));

    dirnames = {'h2-biochem', ...
        'h2-store', ...
        'utils'};

    for ind = 1:numel(dirnames)
        dirname = fullfile(rootdirname, dirnames{ind});
        addpath(genpath(dirname));
    end

    %% Select H2sim's implementation of biochemistry
    % The MRST dependency also contains a separate h2-biochem implementation.
    % Keep that module out of this session and use the explicit H2sim namespace.
    activateH2simBiochemistry(rootdirname);

    %% Initialize chemistry only when requested
    if parser.Results.phreeqc
        initializeH2simPhreeqc(rootdirname);
    end

    %% Octave requires some extra functionality
    if mrstPlatform('octave')

        % Octave MRST settings
        run(fullfile(rootdirname, 'submodules', 'mrst', 'core', 'utils', 'octave_only', 'startup_octave.m'));

        % Disable warnings
        warning('off', 'Octave:possible-matlab-short-circuit-operator');
        warning('off', 'Octave:data-file-in-path');

        % Install package for json files for older octave
        if compare_versions(version, "6.4", "<=")
            try
                pkg load jsonstuff;
            catch
                fprintf('Trying to install jsonstuff...\n');
                pkg install "https://github.com/apjanke/octave-jsonstuff/releases/download/v0.3.3/jsonstuff-0.3.3.tar.gz";
                pkg load jsonstuff;
            end
        end

        % For running Julia from Octave, a tcp client such as
        % https://gnu-octave.github.io/packages/instrument-control/ is
        % needed
        try
            pkg load instrument-control;
        catch
            fprintf('Trying to install instrument-control...\n');
            pkg install "https://downloads.sourceforge.net/project/octave/Octave; % 20Forge%20Packages/Individual%20Package%20Releases/instrument-control-0.9.1.tar.gz"
            pkg load instrument-control;
        end

    end

    mrstModule add compositional ad-blackoil ad-core ad-props deckformat;

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
