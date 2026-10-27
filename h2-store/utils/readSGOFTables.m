function SGOF = readSGOFTables(fid, kw, ntab, ncol)
%READSGOFTABLES Read tables written by getFluidH2BrineSGOF.
%
% SYNOPSIS:
%   tables = readSGOFTables(fid, 'SGOF', nreg, 4)
%
% PARAMETERS:
%   fid  - Open file positioned at the column-header line. This function
%          takes ownership of the handle and closes it, including on error.
%   kw   - Relative permeability keyword following the header, usually SGOF.
%   ntab - Number of region tables to read.
%   ncol - Number of columns in each table, normally 4 for SGOF.
%
% RETURNS:
%   SGOF - Column cell array of numeric region tables. Columns follow the
%          input header: gas saturation, gas and brine relative permeability,
%          and capillary pressure in the file's units. No unit conversion is
%          performed. Requires MRST's deckformat module.
    fileCleanup = onCleanup(@() fclose(fid));
    headerLine = fgetl(fid);
    headers = strsplit(strtrim(strrep(headerLine, '--', '')));
    while ~feof(fid)
        if strcmpi(strtrim(fgetl(fid)), kw)
            break;
        end
    end
    data = readRelPermTable(fid, kw, ntab, ncol);
    SGOF = cell(ntab, 1);
    for j = 1:ntab
        SGOF{j} = data{j}(:, 1:numel(headers));
    end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}
