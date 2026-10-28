function validateH2simSimulationInputs(state, model, schedule)
    % Check initial physical values, schedule controls, and well compositions
    %
    % SYNOPSIS:
    %   validateH2simSimulationInputs(state, model, schedule)
    %
    % DESCRIPTION:
    %   Reject non-finite or non-positive absolute pressures, temperatures, and
    %   timesteps; negative biomass; and invalid phase or component fractions.
    %   Fractions must sum to one within 1e-8 and are never clipped or normalized.
    %   Check closed wells as well, so reopening one retains a valid composition.
    %
    % PARAMETERS:
    %   state    - Initial reservoir state.
    %   model    - Model supplying phase and component counts.
    %   schedule - Simulation timesteps and well controls.
    %
    % SEE ALSO:
    %   packH2simSimulationProblem

    ncomp = validateInitialState(state, model);
    validateSchedule(schedule);
    validateWells(schedule.control, model, ncomp);
end

function ncomp = validateInitialState(state, model)
    if isfield(state, 'pressure')
        assert(all(isfinite(state.pressure(:)) & state.pressure(:) > 0), ...
            'H2sim:InvalidPressure', ...
            'Initial absolute pressures must be finite and positive.');
    end
    if isfield(state, 'T')
        assert(all(isfinite(state.T(:)) & state.T(:) > 0), ...
            'H2sim:InvalidTemperature', ...
            'Initial absolute temperatures must be finite and positive.');
    end
    if isfield(state, 's')
        validateFractions(state.s, model.getNumberOfPhases(), ...
            'initial phase saturations');
    end
    ncomp = [];
    if isprop(model, 'EOSModel') && ~isempty(model.EOSModel)
        ncomp = model.EOSModel.getNumberOfComponents();
    end
    if isfield(state, 'components') && ~isempty(ncomp)
        validateFractions(state.components, ncomp, ...
            'initial component mole fractions');
    end
    if isfield(state, 'nbact')
        assert(all(isfinite(state.nbact(:)) & state.nbact(:) >= 0), ...
            'H2sim:InvalidBiomass', ...
            'Initial bacterial concentrations must be finite and nonnegative.');
    end
end

function validateSchedule(schedule)
    assert(all(isfinite(schedule.step.val(:)) & schedule.step.val(:) > 0), ...
        'H2sim:InvalidSchedule', ...
        'Schedule timestep lengths must be finite and positive.');
    controls = schedule.step.control(:);
    assert(numel(controls) == numel(schedule.step.val) && ...
        all(isfinite(controls) & controls == fix(controls) & ...
        controls >= 1 & controls <= numel(schedule.control)), ...
        'H2sim:InvalidSchedule', 'Each timestep must reference an existing control.');
end

function validateWells(controls, model, ncomp)
    for k = 1:numel(controls)
        control = controls(k);
        if ~isfield(control, 'W')
            continue
        end
        for j = 1:numel(control.W)
            well = control.W(j);
            if isfield(well, 'components') && ~isempty(ncomp)
                label = sprintf('control %d well %d component mole fractions', k, j);
                validateFractions(well.components, ncomp, label);
            end
            if isfield(well, 'compi')
                label = sprintf('control %d well %d phase fractions', k, j);
                validateFractions(well.compi, model.getNumberOfPhases(), label);
            end
        end
    end
end

function validateFractions(x, n, label)
    assert(isnumeric(x) && ismatrix(x) && ~isempty(x) && size(x, 2) == n && ...
        all(isfinite(x(:))) && all(x(:) >= 0 & x(:) <= 1) && ...
        all(abs(sum(x, 2) - 1) <= 1e-8), 'H2sim:InvalidFractions', ...
        '%s must have %d finite nonnegative entries per row and sum to one.', label, n);
end
