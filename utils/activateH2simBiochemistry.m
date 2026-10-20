function activateH2simBiochemistry(rootDirectory)
%Activate H2sim biochemistry without MRST's separate h2-biochem module
%
% SYNOPSIS:
%   activateH2simBiochemistry(rootDirectory)
%
% DESCRIPTION:
%   Called by startupH2sim after MRST initialization. Remove previously
%   added MRST h2-biochem paths and its module mapping for this session,
%   then register and load this checkout as h2sim-biochem. Users initialize
%   the complete toolbox with startupH2sim.

    if nargin == 0
        rootDirectory = fileparts(fileparts(mfilename('fullpath')));
    end
    localRoot = fullfile(rootDirectory, 'h2-biochem');
    assert(isfolder(localRoot), 'H2sim:MissingBiochemistry', ...
        'H2sim biochemistry directory was not found at %s.', localRoot);

    entries = strsplit(path, pathsep);
    normalized = strrep(entries, '\', '/');
    fromMRST = ~cellfun(@isempty, ...
        regexpi(normalized, '/modules/h2-biochem(/|$)', 'once'));
    upstreamRoot = mrstPath('search', 'h2-biochem');
    if ~isempty(upstreamRoot)
        upstreamRoot = strrep(upstreamRoot, '\', '/');
        comparisonPaths = normalized;
        if ispc
            upstreamRoot = lower(upstreamRoot);
            comparisonPaths = cellfun(@lower, comparisonPaths, 'UniformOutput', false);
        end
        fromMRST = fromMRST | strcmp(comparisonPaths, upstreamRoot) | ...
            startsWith(comparisonPaths, [upstreamRoot, '/']);
    end
    if any(fromMRST)
        rmpath(entries{fromMRST});
    end
    mrstPath('remove', 'h2-biochem');
    mrstPath('reregister', 'h2sim-biochem', localRoot);
    mrstModule add h2sim-biochem

    expected = fullfile(localRoot, 'models', 'BiochemistryModel.m');
    actual = which('BiochemistryModel');
    if ispc
        localModel = strcmpi(actual, expected);
    else
        localModel = strcmp(actual, expected);
    end
    assert(localModel, 'H2sim:BiochemistryPathConflict', ...
        ['BiochemistryModel resolves to %s instead of %s. ', ...
         'Restart MATLAB and run startupH2sim before loading any biochemistry model.'], ...
        actual, expected);
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
