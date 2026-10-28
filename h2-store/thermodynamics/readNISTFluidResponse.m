function data = readNISTFluidResponse(response)
%READNISTFLUIDRESPONSE Read a tab-separated NIST fluid response.
%   Accepts character, string and byte responses. The temporary file is
%   unique to this call and is removed on both success and failure.
    file = [tempname, '.txt'];
    fileCleanup = onCleanup(@() deleteResponseFile(file));
    [fid, message] = fopen(file, 'w');
    assert(fid >= 0, 'h2sim:NIST:OpenFailed', ...
        'Cannot write NIST response: %s', message);
    streamCleanup = onCleanup(@() fclose(fid));
    if isstring(response)
        response = char(response);
    end
    fwrite(fid, response(:), 'char');
    clear streamCleanup;
    data = readtable(file, 'Delimiter', '\t', 'ReadVariableNames', true, ...
        'VariableNamingRule', 'preserve');
end

function deleteResponseFile(file)
    if isfile(file)
        delete(file);
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
