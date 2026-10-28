function available = activateH2simAMGCL
    % ACTIVATEH2SIMAMGCL Enable a user-configured compiled MRST AMGCL gateway.
    % The optional installation uses MATLAB preferences; no toolbox is required.
    % Standard MRST installations continue to use their existing solver paths.
    available = false;
    gateway = getpref('H2sim', 'AMGCLGatewayPath', '');
    if isempty(gateway) || ~isfile(fullfile(gateway, 'utils', ['amgcl_matlab.', mexext]))
        return
    end
    mrstModule add linearsolvers;
    addpath(gateway);
    addpath(fullfile(gateway, 'utils'));
    global AMGCLPATH BOOSTPATH
    AMGCLPATH = getpref('H2sim', 'AMGCLSourcePath', '');
    BOOSTPATH = getpref('H2sim', 'BoostHeaderPath', '');
    available = true;
end
