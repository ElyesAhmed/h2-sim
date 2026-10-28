function rho = calculateRoweChouWaterDensity(T, S)
    % CALCULATEROWECHOUWATERDENSITY Temperature-salinity density estimate.
    %
    % SYNOPSIS:
    %   rho = calculateRoweChouWaterDensity(T, S)
    %
    % PARAMETERS:
    %   T - Temperature [K].
    %   S - Salt mass fraction [kg salt/kg solution], consistent with the
    %       coefficients below.
    %       Convert other salinity measures before calling this function.
    %       Inputs may be scalars or arrays with compatible sizes.
    %
    % RETURNS:
    %   rho - Density [kg/m^3], with MATLAB implicit expansion of T and S.
    %
    % Density is evaluated as a function of temperature and salinity. Pressure
    % is not an input. For the pressure-dependent form of the correlation,
    % see the references below.
    %
    % REFERENCES:
    %   Rowe and Chou (1970), J. Chem. Eng. Data 15(1), 61-66.
    %   https://doi.org/10.1021/je60044a016
    %   Hassanzadeh et al. (2008), Appendix B, Eqs. B6-B14, specifies T in K,
    %   salt mass fraction and a pressure variable in kgf/cm^2.
    %   https://doi.org/10.1016/S1750-5836(07)00010-2
    %   Safari Raad et al. (2023), Int. J. Hydrog. Energy 48(2), 696-708.
    %
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

    % Coefficients
    a1 = 5.916365 - 0.01035794 .* T + 0.9270048e-5 .* T.^2 - 1127.522 ./ T + 100674.1 ./ T.^2;
    a2 = 0.520491e-2 - 0.10482101e-4 .* T + 0.8328532e-8 .* T.^2 - 1.1702939 ./ T + 102.2783 ./ T.^2;
    a3 = 0.118547e-7 - 0.6599143e-10 .* T;
    a4 = -2.5166 + 0.0111766 .* T - 0.170522e-4 .* T.^2;
    a5 = 2.84851 - 0.0154305 .* T + 0.223982e-4 .* T.^2;
    a6 = -0.0014814 + 0.829639e-5 .* T - 0.12469e-7 .* T.^2;
    a7 = 0.0027141 - 0.15391e-4 .* T + 0.22655e-7 * T.^2;
    a8 = 0.62158e-6 - 0.40075e-8 .* T + 0.65972e-11 .* T.^2;

    % Evaluate specific volume using element-wise salinity operations.
    rho_inverse = (a1 - a2 * pi - a3 .* pi^2 + a4 .* S + a5 .* S.^2 - a6 * pi .* S ...
        - a7 * pi .* S.^2 - 0.5 .* a8 * pi^2 .* S) .* 10^-3;

    % Density is the inverse of rho_inverse
    rho = 1 ./ rho_inverse; % Convert to kg/m^3
end
