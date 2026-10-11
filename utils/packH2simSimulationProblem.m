function problem = packH2simSimulationProblem(state0,model,schedule,baseName,varargin)
%PACKH2SIMSIMULATIONPROBLEM Persist an exact example setup and accepted outputs.
% Hash all serialized input bytes, avoiding MRST's size-limited object hash
% for cache identity. The resulting name is independent of global useHash.
% Models, state0, schedule, and solver are saved beside packed state/well/
% report files. Changing inputs selects a distinct result directory.
validateH2simSimulationInputs(state0,model,schedule);
serialized=getByteStreamFromArray({state0,model,schedule,varargin});
hash=obj2hash(serialized,'maxSize',inf);
problem=packSimulationProblem(state0,model,schedule,baseName, ...
 'Name',['output_',hash],'useHash',false,varargin{:});
folder=problem.OutputHandlers.states.getDataPath();
if ~isfolder(folder),mkdir(folder);end
setupFile=fullfile(folder,'packed_setup.mat');
% Store on the local filesystem first when the checkout lives on a share.
tmp=[tempname,'.mat']; cleanup=onCleanup(@() removeTemp(tmp)); %#ok<NASGU>
save(tmp,'problem','-v7');
[ok,message]=copyfile(tmp,setupFile,'f');assert(ok,'%s',message);
end
function removeTemp(file)
if isfile(file),delete(file);end
end
