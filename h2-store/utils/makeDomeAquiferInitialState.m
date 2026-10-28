function state = makeDomeAquiferInitialState(model, W, options)
%MAKEDOMEAQUIFERINITIALSTATE Initialize uniform pressure and phase fractions.
%
% SYNOPSIS:
%   state = makeDomeAquiferInitialState(model, W, options)
%
% model is the dome black-oil model and W contains its initial control wells.
% options.initPres [Pa] and options.initSat (oil/gas order) initialize every
% cell. Brine occupies the oil phase. Dissolved-gas ratio rs and vaporized-brine
% ratio rv are zero. Every well solution starts at initPres. No temperature
% field is assigned; the isothermal setup does not apply options.initTemp.
%
% SEE ALSO:
%   modelForDome3DAquifer, initResSol, initWellSolAD

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
    state = initResSol(model.G, options.initPres, options.initSat);
    state.rs = zeros(size(state.pressure));
    state.rv = zeros(size(state.pressure));
    wellSol = initWellSolAD(W, model, state);
    [wellSol.bhp] = deal(options.initPres);
    state.wellSol = wellSol;
end
