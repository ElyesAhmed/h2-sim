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
                        row-1, col-1, vtype, value, blanks(4096), 4096);
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
