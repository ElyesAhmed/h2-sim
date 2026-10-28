classdef H2simNativeIPhreeqc < handle
    % COM-compatible subset backed by PhreeqcMatlab's native IPhreeqc.
    properties (Access = private)
        native = []
    end
    methods

        function obj = H2simNativeIPhreeqc()
            obj.native = IPhreeqc();
            obj.native = obj.native.CreateIPhreeqc();
            assert(obj.native.id >= 0, 'H2sim:PhreeqcCreate', ...
                'Could not create native IPhreeqc instance.');
            toggles = {'SetOutputFileOn', 'SetErrorFileOn', ...
                'SetLogFileOn', 'SetSelectedOutputFileOn', 'SetDumpFileOn'};
            for k = 1:numel(toggles)
                obj.native.(toggles{k})(false);
            end
        end

        function status = LoadDatabase(obj, file)
            status = obj.native.LoadDatabase(file);
        end

        function status = RunString(obj, input)
            status = obj.native.RunString(input);
        end

        function message = GetErrorString(obj)
            message = obj.native.GetErrorString();
        end

        function raw = GetSelectedOutputArray(obj)
            % Use the typed API: no text rounding or wrapper table indexing.
            nr = obj.native.GetSelectedOutputRowCount();
            nc = obj.native.GetSelectedOutputColumnCount();
            raw = cell(nr, nc);
            vtype = libpointer('int32Ptr', int32(0));
            value = libpointer('doublePtr', 0);
            for row = 1:nr
                for col = 1:nc
                    [status, ~, number, text] = obj.native.GetSelectedOutputValue2( ...
                        row - 1, col - 1, vtype, value, blanks(4096), 4096);
                    ok = (isnumeric(status) && isscalar(status) && status == 0) || ...
                        strcmp(string(status), 'IPQ_OK');
                    assert(ok, ...
                        'H2sim:PhreeqcOutput', ...
                        'Cannot read selected output at row %d, column %d.', row, col);
                    if row == 1
                        raw{row, col} = char(text);
                    else
                        raw{row, col} = number;
                    end
                end
            end
        end

        function delete(obj)
            if ~isempty(obj.native) && ~isempty(obj.native.id) && obj.native.id >= 0
                obj.native.DestroyIPhreeqc();
                obj.native = [];
            end
        end

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
