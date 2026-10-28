function state = makeAquifer2DInitialState(model, W, options)
    % MAKEAQUIFER2DINITIALSTATE Uniform pressure, saturation and zero dissolved H2.
    %
    % SYNOPSIS:
    %   state = makeAquifer2DInitialState(model, W, options)
    %
    % PARAMETERS:
    %   model   - Aquifer black-oil model; brine occupies the oil phase.
    %   W       - Single storage well from the first schedule control.
    %   options - Structure with initPres [Pa] and initSat in oil/gas order.
    %
    % RETURNS:
    %   state - MRST reservoir state with uniform pressure and saturation, zero
    %           solution gas ratio rs, and an initialized well solution whose bhp
    %           equals initPres. No temperature field is assigned: this setup is
    %           isothermal and does not apply the initTemp option.
    %
    % SEE ALSO:
    %   modelForSimple2DAquifer, initResSol, initWellSolAD

    %{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

MRST is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with MRST. If not,
see <http://www.gnu.org/licenses/>.
%}
    state = initResSol(model.G, options.initPres, options.initSat);
    state.rs = 0 .* state.pressure;
    wellSol = initWellSolAD(W, model, state);
    wellSol.bhp = options.initPres;
    state.wellSol = wellSol;
end
