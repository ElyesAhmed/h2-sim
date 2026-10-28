function diagnostics = summarizeH2StorageStates(model, states, wellSols)
%SUMMARIZEH2STORAGESTATES Summarize stored hydrogen and single-well histories.
%
% SYNOPSIS:
%   diagnostics = summarizeH2StorageStates(model, states, wellSols)
%
% states and wellSols are equally sized cell arrays, with one well solution
% per state. The oil phase represents brine. Inventory uses computeGasVolumes
% and is reported in surface m^3. Mean pressure [Pa] and mean gas saturation
% are arithmetic cell averages, without pore-volume weighting. bhp is in Pa;
% gasRate and brineRate are signed surface rates [m^3/s] from qGs and qOs.
%
% RETURNS:
%   diagnostics - Structure with row-vector fields in state order:
%       totalHydrogenVolume, dissolvedHydrogenVolume, gasHydrogenVolume [m^3];
%       meanPressure and bhp [Pa]; meanGasSaturation (dimensionless);
%       dissolvedFractionPercent [%]; gasRate and brineRate [m^3/s].
%
% dissolvedFractionPercent is dissolved hydrogen divided by total hydrogen
% currently stored, times 100;
% it is zero for nonpositive total inventory. It is not a cumulative loss or
% recovery efficiency. Empty histories return empty row vectors.
%
% SEE ALSO:
%   computeGasVolumes, getPackedSimulatorOutput

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
    assert(numel(states) == numel(wellSols), ...
        'h2sim:StorageSummary:HistoryLength', ...
        'Reservoir and well histories must have equal lengths.');
    count = numel(states);
    fields = {'totalHydrogenVolume', 'dissolvedHydrogenVolume', ...
        'gasHydrogenVolume', 'meanPressure', 'meanGasSaturation', ...
        'dissolvedFractionPercent', 'bhp', 'gasRate', 'brineRate'};
    for k = 1:numel(fields)
        diagnostics.(fields{k}) = zeros(1, count);
    end
    [total, dissolved, gas] = computeGasVolumes(model, states, 1:count);
    gasPhase = find(model.getPhaseNames() == 'G', 1);
    for k = 1:count
        well = wellSols{k};
        assert(isscalar(well), 'h2sim:StorageSummary:WellCount', ...
            'Each step must contain exactly one well solution.');
        diagnostics.totalHydrogenVolume(k) = sum(total{k});
        diagnostics.dissolvedHydrogenVolume(k) = sum(dissolved{k});
        diagnostics.gasHydrogenVolume(k) = sum(gas{k});
        diagnostics.meanPressure(k) = mean(states{k}.pressure);
        diagnostics.meanGasSaturation(k) = mean(states{k}.s(:, gasPhase));
        if diagnostics.totalHydrogenVolume(k) > 0
            diagnostics.dissolvedFractionPercent(k) = ...
                (diagnostics.dissolvedHydrogenVolume(k)/ ...
                 diagnostics.totalHydrogenVolume(k))*100;
        end
        diagnostics.bhp(k) = well.bhp;
        diagnostics.gasRate(k) = well.qGs;
        diagnostics.brineRate(k) = well.qOs;
    end
end
