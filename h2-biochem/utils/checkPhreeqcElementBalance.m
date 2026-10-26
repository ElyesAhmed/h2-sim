function state = checkPhreeqcElementBalance(state, inputInventory, outputInventory, ...
    elements, options, backend)
%Validate and store per-cell PHREEQC elemental conservation diagnostics
%
% The existing absolute/relative thresholds determine pass/fail on every call.
% phreeqcElementBalanceWarningMode controls printing only: 'once' (default)
% reports newly failing elements and tenfold worsening of residual/limit;
% 'always' retains one warning per failing call. Warning history/counters are
% state-local, survive saved-state restarts and never hide audit arrays.

    assert(isequal(size(inputInventory), size(outputInventory)) && ...
        size(inputInventory, 2) == numel(elements), ...
        'PHREEQC input/output element inventories must be nc-by-nelement arrays.');
    assert(all(isfinite(inputInventory(:))) && all(isfinite(outputInventory(:))), ...
        'PHREEQC element inventories must be finite.');

    ne = numel(elements);
    absTol = tolerance(options, 'phreeqcElementBalanceAbsoluteTolerance', 1e-7, ne);
    relTol = tolerance(options, 'phreeqcElementBalanceRelativeTolerance', 1e-8, ne);
    absoluteResidual = abs(outputInventory - inputInventory);
    scale = max(abs(inputInventory), abs(outputInventory));
    normalizedResidual = zeros(size(scale));
    nonzero = scale > 0;
    normalizedResidual(nonzero) = absoluteResidual(nonzero)./scale(nonzero);
    normalizedResidual(~nonzero & absoluteResidual > 0) = inf;
    limit = bsxfun(@plus, absTol, bsxfun(@times, scale, relTol));
    pass = absoluteResidual <= limit;

    state.phreeqcElementBalanceElements = elements;
    state.phreeqcElementBalanceInput = inputInventory;
    state.phreeqcElementBalanceOutput = outputInventory;
    state.phreeqcElementBalanceAbsoluteResidual = absoluteResidual;
    state.phreeqcElementBalanceNormalizedResidual = normalizedResidual;
    state.phreeqcElementBalancePass = pass;

    mode = 'once';
    if isfield(options, 'phreeqcElementBalanceWarningMode')
        mode = options.phreeqcElementBalanceWarningMode;
    end
    mode = validatestring(mode, {'once', 'always'}, mfilename, ...
        'phreeqcElementBalanceWarningMode');
    if all(pass(:))
        return
    end

    [state, emit, cellNo, elementNo, reportedElements] = selectWarning( ...
        state, absoluteResidual, limit, pass, elements, backend, mode);
    if emit
        message = sprintf(['PHREEQC elemental conservation failed for backend "%s", cell %d, ', ...
             'element %s: input=%.16g mol, output=%.16g mol, absolute ', ...
             'residual=%.16g mol, normalized residual=%.16g (limit %.16g mol).'], ...
            backend, cellNo, elements{elementNo}, inputInventory(cellNo, elementNo), ...
            outputInventory(cellNo, elementNo), absoluteResidual(cellNo, elementNo), ...
            normalizedResidual(cellNo, elementNo), limit(cellNo, elementNo));
        if strcmp(mode, 'once') && ~isempty(reportedElements)
            message = sprintf(['%s\nReported elements: %s. Further messages repeat only ', ...
                'for new elements or tenfold worsening; full audit results remain in state.'], ...
                message, strjoin(reportedElements, ', '));
        end
        warning('H2Biochem:PhreeqcElementBalance', '%s', message);
    end
end

function [state, emit, cellNo, elementNo, reportedElements] = selectWarning( ...
        state, residual, limit, pass, elements, backend, mode)
    % Keep reporting history in the state, not in a process-global warning cache.
    history = struct('backend', {}, 'elements', {}, 'reportedRatio', {}, ...
        'failedCalls', {}, 'reportedCalls', {}, 'suppressedCalls', {});
    field = 'phreeqcElementBalanceWarningHistory';
    if isfield(state, field) && isstruct(state.(field)) && ...
            all(isfield(state.(field), fieldnames(history)))
        history = state.(field);
    end
    index = find(strcmp({history.backend}, backend), 1);
    if isempty(index)
        index = numel(history) + 1;
        history(index) = struct('backend', backend, 'elements', {elements}, ...
            'reportedRatio', zeros(1, numel(elements)), 'failedCalls', 0, ...
            'reportedCalls', 0, 'suppressedCalls', 0);
    elseif ~isequal(history(index).elements, elements)
        history(index).elements = elements;
        history(index).reportedRatio = zeros(1, numel(elements));
    end
    entry = history(index);
    entry.failedCalls = entry.failedCalls + 1;
    ratio = zeros(size(residual));
    positiveLimit = limit > 0;
    ratio(positiveLimit) = residual(positiveLimit)./limit(positiveLimit);
    ratio(~positiveLimit & ~pass) = inf;
    worstRatio = max(ratio, [], 1);
    failedElements = any(~pass, 1);
    newElement = failedElements & entry.reportedRatio == 0;
    worsened = failedElements & isfinite(entry.reportedRatio) & ...
        worstRatio >= 10*entry.reportedRatio;
    trigger = newElement | worsened;
    setting = warning('query', 'H2Biochem:PhreeqcElementBalance');
    forceError = strcmp(setting.state, 'error');
    emit = (strcmp(mode, 'always') || forceError || any(trigger)) && ...
        ~strcmp(setting.state, 'off');
    [cellNo, elementNo] = find(~pass, 1);
    reportedElements = {};
    if emit
        if strcmp(mode, 'once') && ~forceError
            elementNo = find(trigger, 1);
            [~, cellNo] = max(ratio(:, elementNo));
            reportedElements = elements(trigger);
            entry.reportedRatio(trigger) = worstRatio(trigger);
        else
            entry.reportedRatio(elementNo) = worstRatio(elementNo);
        end
        entry.reportedCalls = entry.reportedCalls + 1;
    else
        entry.suppressedCalls = entry.suppressedCalls + 1;
    end
    history(index) = entry;
    state.(field) = history;
end

function values = tolerance(options, field, default, ne)
    if isfield(options, field)
        values = options.(field);
    else
        values = default;
    end
    validateattributes(values, {'numeric'}, {'vector', 'real', 'finite', 'nonnegative'}, ...
        mfilename, field);
    if isscalar(values)
        values = repmat(values, 1, ne);
    else
        values = reshape(values, 1, []);
        assert(numel(values) == ne, ...
            '%s must be scalar or contain one value per audited element.', field);
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
