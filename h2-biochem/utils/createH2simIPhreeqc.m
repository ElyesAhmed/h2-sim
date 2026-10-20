function iph = createH2simIPhreeqc(progId)
% Use COM on Windows and PhreeqcMatlab's native C interface on Linux.
if ispc
    iph = actxserver(char(progId));
else
    assert(isunix && ~ismac, 'H2sim:PhreeqcPlatform', ...
        'Sequential PHREEQC coupling supports Windows and Linux MATLAB.');
    iph = H2simNativeIPhreeqc();
end
end
