function saved = loadH2simResults(file, varargin)
    % LOADH2SIMRESULTS Load saved results, staging Windows UNC files locally.
    % HDF5 MAT files can fail to lock when read through a WSL/network share.
    % The temporary copy is removed after loading; the source stays unchanged.
    file = char(file);
    if ispc && startsWith(file, '\\')
        local = [tempname, '.mat'];
        cleanup = onCleanup(@() removeLocal(local));
        [ok, message] = copyfile(file, local);
        assert(ok, '%s', message);
        saved = load(local, varargin{:});
    else
        saved = load(file, varargin{:});
    end
end

function removeLocal(file)
    if isfile(file)
        delete(file);
    end
end
