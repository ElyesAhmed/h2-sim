function [wellSols, states, reports] = getH2simPackedPhysicalOutput(problem)
    % GETH2SIMPACKEDPHYSICALOUTPUT Read physical states without derivative caches.
    % Full restart states and caches remain unchanged in packed output on disk.
    % Read one state at a time to avoid retaining large AD/state-function caches.
    [wellSols, handler, reports] = getPackedSimulatorOutput(problem, 'readStatesFromDisk', false);
    count = min(handler.numelData(), numel(problem.SimulatorSetup.schedule.step.val));
    wellSols = wellSols(1:count);
    reports = reports(1:count);
    states = cell(count, 1);
    transient = {'FractionalDerivatives', 'FacilityFluxProps', 'FlowProps', 'PVTProps'};
    for k = 1:count
        state = handler{k};
        state = rmfield(state, intersect(fieldnames(state), transient));
        states{k} = state;
        if mod(k, 100) == 0 || k == count
            fprintf('Read physical output: %d/%d states.\n', k, count);
        end
    end
end
