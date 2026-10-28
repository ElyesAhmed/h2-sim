function data = getH2CycleEndpointData(model, states, schedule)
    % GETH2CYCLEENDPOINTDATA Select stored states and times at storage-stage endpoints.
    %
    % SYNOPSIS:
    %   data = getH2CycleEndpointData(model, states, schedule)
    %
    % Select the final timestep of each cushion, charge, discharge and shut stage
    % using getCyclesLastSteps. states contains one reservoir state per schedule
    % timestep, each with dissolved-gas ratio rs. The oil phase represents brine;
    % model.fluid.rhoOS and rhoGS are surface densities [kg/m^3].
    %
    % RETURNS:
    %   data.steps        - Selected schedule-step indices, in chronological order.
    %   data.time         - Elapsed time [s] at those same indices.
    %   data.massFraction - Row cell array of cellwise dissolved-H2 mass fractions,
    %                       rhoGS*Rs/(rhoOS+rhoGS*Rs), at each selected state.
    % Empty schedules return no selected steps or frames. Stage metadata on the
    % first well takes precedence over well names, as in getCyclesLastSteps.
    %
    % SEE ALSO:
    %   getCyclesLastSteps, simulate2DExampleAquifer

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

    last = getCyclesLastSteps(schedule);
    data.steps = sort([last.cushion, last.charge, last.discharge, last.shut]);
    elapsed = cumsum(schedule.step.val);
    data.time = reshape(elapsed(data.steps), 1, []);
    data.massFraction = cell(1, numel(data.steps));
    rhoOS = model.fluid.rhoOS;
    rhoGS = model.fluid.rhoGS;
    for k = 1:numel(data.steps)
        state = states{data.steps(k)};
        data.massFraction{k} = ...
            rhoGS .* state.rs ./ (rhoOS + rhoGS .* state.rs);
    end
end
