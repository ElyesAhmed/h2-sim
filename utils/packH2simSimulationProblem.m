function problem = packH2simSimulationProblem(state0, model, schedule, baseName, varargin)
%Pack an H2sim simulation using the complete setup as its cache identity
%
% SYNOPSIS:
%   problem = packH2simSimulationProblem(state0, model, schedule, baseName)
%   problem = packH2simSimulationProblem(..., 'NonLinearSolver', solver)
%
% DESCRIPTION:
%   Validate the initial state and schedule, then hash all serialized input
%   bytes to identify the packed simulation. Changing the setup selects a
%   separate output directory. Save the setup beside the packed states,
%   well solutions, and reports so that the run can be reproduced.
%
% PARAMETERS:
%   state0   - Initial reservoir state.
%   model    - Configured simulation model.
%   schedule - Controls and timesteps for the simulation.
%   baseName - Base name passed to packSimulationProblem.
%   varargin - Additional name/value options for packSimulationProblem.
%
% RETURNS:
%   problem - Packed simulation problem with an input-dependent name.
%
% SEE ALSO:
%   packSimulationProblem, simulatePackedProblem, validateH2simSimulationInputs

    validateH2simSimulationInputs(state0, model, schedule);
    serialized = getByteStreamFromArray({state0, model, schedule, varargin});
    hash = obj2hash(serialized, 'maxSize', inf);
    problem = packSimulationProblem(state0, model, schedule, baseName, ...
        'Name', ['output_', hash], 'useHash', false, varargin{:});

    folder = problem.OutputHandlers.states.getDataPath();
    if ~isfolder(folder)
        mkdir(folder);
    end
    setupFile = fullfile(folder, 'packed_setup.mat');

    % Write locally first: MATLAB saves may fail directly on WSL shares.
    localFile = [tempname, '.mat'];
    cleanup = onCleanup(@() removeTemp(localFile));
    save(localFile, 'problem', '-v7');
    [ok, message] = copyfile(localFile, setupFile, 'f');
    assert(ok, '%s', message);
end

function removeTemp(file)
    if isfile(file)
        delete(file);
    end
end
