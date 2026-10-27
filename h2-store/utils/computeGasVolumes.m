function [totalGasVolume, H2InWater, vH2InGas] = computeGasVolumes(model, states, steps)
%COMPUTEGASVOLUMES Hydrogen component inventories at surface conditions.
%
% SYNOPSIS:
%   [total, dissolved, gas] = computeGasVolumes(model, states, steps)
%
% PARAMETERS:
%   model  - MRST black-oil model with oil and gas phases. The oil
%            phase represents brine and Rs represents dissolved hydrogen.
%   states - Cell array of reservoir states.
%   steps  - Indices to evaluate; order and repeated indices are preserved.
%
% RETURNS:
%   total, dissolved, gas - Column cell arrays, one entry per requested step.
%       Each entry contains one value per cell in surface-volume units [m^3].
%       These are component volumes, not reservoir-phase volumes:
%           dissolved = PV .* sO .* bO .* Rs
%           gas       = PV .* sG .* bG
%       bO and bG are reciprocal formation volume factors. PV is evaluated
%       through the model, including its rock-compressibility multiplier.
%       With disgas disabled the dissolved inventory is zero. Rv affects
%       the gas PVT properties; vaporized brine is not hydrogen inventory.
%
% This corrects the former use of bulk volume and gas saturation in the
% dissolved term. Postprocessed inventories and dissolution fractions from
% older versions therefore need recomputation; simulation states are unchanged.
    names = model.getPhaseNames();
    liquid = find(names == 'O', 1);
    gas = find(names == 'G', 1);
    assert(~isempty(liquid) && ~isempty(gas), ...
        'h2sim:GasInventory:MissingPhases', 'Oil and gas phases are required.');

    H2InWater = cell(numel(steps), 1);
    vH2InGas = cell(numel(steps), 1);
    totalGasVolume = cell(numel(steps), 1);
    % simulateScheduleAD may initialize a model copy rather than the caller's
    % model. Set up missing groups locally to support the original model.
    if ~isempty(steps) && isempty(model.PVTPropertyFunctions)
        model = model.setupStateFunctionGroupings();
    end
    for i = 1:numel(steps)
        state = states{steps(i)};
        [b, pv] = model.getProps(state, 'ShrinkageFactors', 'PoreVolume');
        if model.disgas
            rs = model.getProp(state, 'rs');
            H2InWater{i} = pv .* state.s(:, liquid) .* b{liquid} .* rs;
        else
            H2InWater{i} = zeros(size(state.s, 1), 1);
        end
        vH2InGas{i} = pv .* state.s(:, gas) .* b{gas};
        totalGasVolume{i} = H2InWater{i} + vH2InGas{i};
    end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}
