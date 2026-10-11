function validateH2simSimulationInputs(state, model, schedule)
%VALIDATEH2SIMSIMULATIONINPUTS Reject unphysical initial and well inputs.
% Fractions are checked, never silently clipped or normalized. Closed wells
% are checked too, so re-opening one cannot expose an invalid composition.
if isfield(state, 'pressure')
    assert(all(isfinite(state.pressure(:)) & state.pressure(:)>0), ...
        'H2sim:InvalidPressure', 'Initial absolute pressures must be finite and positive.');
end
if isfield(state, 'T')
    assert(all(isfinite(state.T(:)) & state.T(:)>0), ...
        'H2sim:InvalidTemperature', 'Initial absolute temperatures must be finite and positive.');
end
if isfield(state, 's')
    fractions(state.s, model.getNumberOfPhases(), 'initial phase saturations');
end
ncomp=[];
if isprop(model, 'EOSModel') && ~isempty(model.EOSModel)
    ncomp=model.EOSModel.getNumberOfComponents();
end
if isfield(state, 'components') && ~isempty(ncomp)
    fractions(state.components,ncomp,'initial component mole fractions');
end
if isfield(state, 'nbact')
    assert(all(isfinite(state.nbact(:)) & state.nbact(:)>=0), ...
        'H2sim:InvalidBiomass', 'Initial bacterial concentrations must be finite and nonnegative.');
end
assert(all(isfinite(schedule.step.val(:)) & schedule.step.val(:)>0), ...
    'H2sim:InvalidSchedule', 'Schedule timestep lengths must be finite and positive.');
controls=schedule.step.control(:);
assert(numel(controls)==numel(schedule.step.val) && ...
    all(isfinite(controls) & controls==fix(controls) & controls>=1 & controls<=numel(schedule.control)), ...
    'H2sim:InvalidSchedule', 'Each timestep must reference an existing control.');
for k=1:numel(schedule.control)
    control=schedule.control(k);
    if ~isfield(control,'W'),continue;end
    for j=1:numel(control.W)
        w=control.W(j);
        if isfield(w,'components') && ~isempty(ncomp)
            fractions(w.components,ncomp,sprintf('control %d well %d component mole fractions',k,j));
        end
        if isfield(w,'compi')
            fractions(w.compi,model.getNumberOfPhases(),sprintf('control %d well %d phase fractions',k,j));
        end
    end
end
end
function fractions(x,n,label)
assert(isnumeric(x) && ismatrix(x) && ~isempty(x) && size(x,2)==n && ...
    all(isfinite(x(:))) && all(x(:)>=0 & x(:)<=1) && ...
    all(abs(sum(x,2)-1)<=1e-8), 'H2sim:InvalidFractions', ...
    '%s must have %d finite nonnegative entries per row and sum to one.',label,n);
end
