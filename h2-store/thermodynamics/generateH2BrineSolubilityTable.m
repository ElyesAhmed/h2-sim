function solubilityTable = generateH2BrineSolubilityTable(varargin)
    % GENERATEH2BRINESOLUBILITYTABLE Tabulate hydrogen and water mole fractions.
    %
    % SYNOPSIS:
    %   tab = generateH2BrineSolubilityTable('min_temp', 25, 'max_temp', 60, ...
    %       'n_temp', 3, 'min_press', 1e5, 'max_press', 1e7, 'n_press', 20)
    %
    % OPTIONAL PARAMETERS:
    %   min_temp, max_temp - Temperature bounds [degrees C], defaults 0 and 100.
    %   n_temp             - Temperature count, default 11. A single temperature
    %                        uses min_temp.
    %   min_press, max_press - Pressure bounds [Pa], defaults 1e5 and 1e7.
    %   n_press            - Pressure count, at least 2, default 10.
    %   ms                 - Salt molality [mol/kg water], default 0.
    %   outputPath         - Output folder, default current directory. An empty
    %                        path selects MRST's UHS_PVT/H2SolubilityTable folder.
    %   outputDisplay      - Display the table, default false.
    %   reCompute          - Regenerate an existing CSV, default true. Otherwise
    %                        load its stored values at CSV precision.
    %
    % RETURNS:
    %   tab - Temperature [degrees C], pressure [Pa], water vapor mole fraction
    %         y_H2O and dissolved hydrogen mole fraction x_H2. Rows are grouped
    %         by temperature, with pressure varying fastest. All grid points are
    %         evaluated together without querying an external data service.
    %
    % The generated filename retains its historical convention (including the
    % 'bar' label although the pressure numbers are in Pa). File names omit grid
    % counts, so use reCompute=true when changing resolution. Use separate
    % folders for water and brine model tables with otherwise identical inputs.
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
    % Input parameters
    opts = struct( ...
        'min_temp', 0, ...          % Default: 0°C
        'max_temp', 100, ...        % Default: 100°C
        'n_temp', 11, ...           % Default: 11 points
        'min_press', 1e5, ...       % Default: 1 bar (1e5 Pa)
        'max_press', 1e7, ...       % Default: 100 bar (1e7 Pa)
        'ms', 0, ...                % Default: 0 (water)
        'n_press', 10, ...          % Default: 10 points
        'outputDisplay', false, ... % Default: false (auto-generated)
        'reCompute', true, ...      % Default: true
        'outputPath', '.' ...       % Default: mrst output dir
        );
    opts = merge_options(opts, varargin{:});
    % Generate temperature and pressure ranges
    min_temp = opts.min_temp;
    max_temp = opts.max_temp;
    nTemp = opts.n_temp;
    min_pressure_barsa = opts.min_press;
    max_pressure_barsa = opts.max_press;
    nPress = opts.n_press;
    if nPress < 2
        error('h2sim:SolubilityTable:PressureCount', 'n_press needs to be at least 2');
    end
    if nTemp == 1
        temperatures = min_temp;
    else
        temperatures = linspace(min_temp, max_temp, nTemp);
    end
    pressures = linspace(min_pressure_barsa, max_pressure_barsa, nPress);
    % salt molality
    ms = opts.ms;
    % Construct the subdirectory path
    if isempty(opts.outputPath)
        opts.outputPath = fullfile(mrstOutputDirectory(), 'UHS_PVT', 'H2SolubilityTable');
    end
    % Construct the filename based on the defined parameters
    fileName = sprintf('SolubilityValues_%.1f_to_%.1f_bar_%.1f_to_%.1f_C_%.1f.csv', ...
        min_pressure_barsa, max_pressure_barsa, ...
        min_temp, max_temp, ms);

    % Full file path
    filePath = fullfile(opts.outputPath, fileName);

    recompute = opts.reCompute;
    % Check if the file already exists
    if exist(filePath, 'file') && ~recompute
        fprintf('File %s already exists. Loading data...\n', fileName);
        try
            solubilityTable = readtable(filePath, 'VariableNamingRule', 'preserve', 'ReadVariableNames', true);
            solubilityTable.Properties.VariableNames = {'# temperature [°C]', 'pressure [Pa]', 'y_H2O', 'x_H2'};

            if opts.outputDisplay
                disp('Solubility Table read successfully:');
                display(solubilityTable);
            end
            return  % Exit the function as the table already exists
        catch ME
            warning('Failed to read existing file: %s. Proceeding with table generation.', ME.message);
        end
    end

    if ~exist(opts.outputPath, 'dir')
        mkdir(opts.outputPath);
    end

    %% Get H2 densities for the requested temperature and pressure ranges
    mH2 = 2.016e-3;  % Molar mass of H2 (kg/mol)
    Joule = 8.314472;  % Ideal gas constant (J/(mol*K))
    T_K = temperatures' + 273.15;
    ZH2 = calculateBrillBreggsZfactorHydrogen(T_K, pressures);
    rhoH2_corr = pressures .* mH2 ./ (ZH2 .* Joule .* T_K);

    % Open output file
    fid = fopen(filePath, 'w');
    assert(fid >= 0, 'h2sim:SolubilityTable:OpenFailed', ...
        'Could not open solubility table: %s', filePath);
    fileCleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '# This autogenerated file contains solubilities of H2 and H2O in a respective fluid system.\n');
    fprintf(fid, '# The values have been calculated by means (11)-(14) in https://doi.org/10.1016/S0016-7037(03)00273-4.\n');
    fprintf(fid, '#\n');
    fprintf(fid, '# Concerning temperature and pressure ranges, the following parameters have been used:\n');
    fprintf(fid, '# min temperature = %.2f, max temperature = %.2f, #temperature sampling points = %d\n', min_temp, max_temp, nTemp);
    fprintf(fid, '# min phase pressure = %.2e, max phase pressure = %.2e, #pressure sampling points = %d\n#\n', min_pressure_barsa, max_pressure_barsa, nPress);
    fprintf(fid, '# temperature [°C], phase pressure [Pa],         y_H2O [-],         x_H2 [-]\n');

    % Evaluate the full grid. Transpose before flattening to retain the legacy
    % temperature-major row order (pressure varies fastest in the CSV).
    [temperatureGrid, pressureGrid] = ndgrid(temperatures, pressures);
    temperatureK = temperatureGrid + 273.15;
    A = computeA(temperatureK, pressureGrid, rhoH2_corr);
    B = computeBsalt(temperatureK, pressureGrid, rhoH2_corr, ms);
    nu = 2;
    y_H2O = ((1 - B) .* 55.508) ./ ((1 ./ A - B) .* (nu .* ms + 55.508) + nu * ms .* B);
    x_H2 = B .* (1 - y_H2O);
    outputTable = [reshape(temperatureGrid.', [], 1), ...
        reshape(pressureGrid.', [], 1), ...
        reshape(y_H2O.', [], 1), reshape(x_H2.', [], 1)];
    fprintf(fid, '%.5e, %.5e, %.4e, %.4e\n', outputTable.');

    clear fileCleanup;
    % Create a table and display it in the console
    try
        solubilityTable = array2table(outputTable, 'VariableNames', {'# temperature [°C]', 'pressure [Pa]', 'y_H2O', 'x_H2'});
        disp('Solubility Table read successfully:');
        if opts.outputDisplay
            display(solubilityTable);
        end
    catch ME
        disp('Error occurred while reading the table:');
        disp(ME.message);
        solubilityTable = []; % Return empty if reading fails
    end
end

% Helper functions
function k = equilibriumConstantH2(T)
    TinC = T - 273.15; % temperature in °C
    c = [2.9947, 4.81373e-3, -5.1773e-5, 1.19052e-7];
    logk0_H2 = c(1) + c(2) .* TinC + c(3) .* TinC.^2 + c(4) .* TinC.^3;
    k = 10.^logk0_H2;
end

function k = equilibriumConstantH2O(T)
    TinC = T - 273.15; % temperature in °C
    c = [-2.1817, 2.98e-2, -1.098e-4, 2.048e-7];
    logk0_H2O = c(1) + c(2) .* TinC + c(3) .* TinC.^2 + c(4) .* TinC.^3;
    k = 10.^logk0_H2O;
end

function phi = fugacityCoefficientH2(T, p, rhoH2)
    molarMassH2 = 2.016e-3; % [kg/mol]
    V = 1 ./ (rhoH2 / molarMassH2) * 1e6; % molar volume [cm3/mol]
    p_bar = p ./ 1e5; % phase pressure in bar
    a_H2 = 1441753.379; % mixture parameter of Redlich-Kwong equation
    b_H2 = 18.417; % mixture parameter of Redlich-Kwong equation
    R = 83.1446261815324; % universal gas constant [bar.cm3/mol.K]
    lnPhiH2 = log(V ./ (V - b_H2)) + b_H2 ./ (V - b_H2) ...
        - 2 .* a_H2 ./ (R * T.^(1.5) .* b_H2) .* log((V + b_H2) ./ V) ...
        + a_H2 .* b_H2 ./ (R .* T.^(1.5) .* b_H2.^2) .* (log((V + b_H2) ./ V) - b_H2 ./ (V + b_H2)) ...
        - log(p_bar .* V ./ (R * T));
    phi = exp(lnPhiH2);
end

function phi = fugacityCoefficientH2O(T, p, rhoH2)
    molarMassH2 = 2.016e-3; % [kg/mol]
    V = 1 ./ (rhoH2 / molarMassH2) * 1e6; % molar volume [cm3/mol]
    p_bar = p ./ 1e5; % phase pressure in bar
    a_H2 = 1441753.379; % mixture parameter of Redlich-Kwong equation
    a_H2O = 142666655.8; % mixture parameter of Redlich-Kwong equation
    a_H2_H2O = sqrt(a_H2 .* a_H2O); % mixture parameter of Redlich-Kwong equation
    b_H2 = 18.417; % mixture parameter of Redlich-Kwong equation
    b_H2O = 21.127; % mixture parameter of Redlich-Kwong equation
    R = 83.1446261815324; % universal gas constant [bar.cm3/mol.K]
    lnPhiH2O = log(V ./ (V - b_H2)) + b_H2O ./ (V - b_H2) ...
        - 2 .* a_H2_H2O ./ (R * T.^(1.5) .* b_H2) .* log((V + b_H2) ./ V) ...
        + a_H2 .* b_H2O ./ (R * T.^(1.5) .* b_H2.^2) .* (log((V + b_H2) ./ V) - b_H2 ./ (V + b_H2)) ...
        - log(p_bar .* V ./ (R * T));
    phi = exp(lnPhiH2O);
end

function A = computeA(T, p, rhoH2)
    deltaP = p ./ 1e5 - 1; % pressure range [bar] from p0 = 1 bar to p
    v_av_H2O = 18.1; % average partial molar volume of H2O [cm3/mol]
    R = 83.1446261815324; % universal gas constant [bar.cm3/mol.K]
    k0_H2O = equilibriumConstantH2O(T); % equilibrium constant for H2O at 1 bar
    phi_H2O = fugacityCoefficientH2O(T, p, rhoH2); % fugacity coefficient of H2O for the water-H2 system
    p_bar = p ./ 1e5;
    A = k0_H2O ./ (phi_H2O .* p_bar) .* exp(deltaP .* v_av_H2O ./ (R .* T));
end

function gamma = activitySalt(saltMolality, temperature, pressure)
    % Computes the activity coefficient of salt in a saline solution using
    % an empirical correlation based on temperature, pressure, and salt molality.
    % See (Ahmed, E., et al., 2024) for more details.
    % Normalize pressure and temperature to critical values of water
    normalizedPressure = pressure / 220.064;  % Critical pressure of water [bar]
    normalizedTemp = temperature / 647.096;   % Critical temperature of water [K
    % Empirical coefficients
    a1 = 6.5934;
    a2 = 0.0571;
    a3 = 0.3375;
    a4 = 1.2229;
    a5 = 0.3448;
    a6 = -2.9756;
    a7 = -0.0725;
    a8 = -4.2276;
    a9 = -0.8155;
    a10 = 0.6073;
    a11 = 0.2889;
    a12 = 0.0215;
    % Compute natural log of activity coefficient (lnGamma)
    lnGamma = ((a1 + a2 * (normalizedPressure ./ normalizedTemp) + a3 ./ normalizedTemp + a4 * log(normalizedTemp)) ...
        * (saltMolality^a5) ...
        + (a6 + a7 * (normalizedPressure ./ normalizedTemp) + a8 * normalizedTemp + a9 ./ normalizedTemp) ...
        * (saltMolality^a11) ...
        + 2 * a10 * (heaviside(saltMolality) - 0.5) ...
        + a12);

    % Return the activity coefficient by exponentiating lnGamma
    gamma = exp(lnGamma);
end

function H = heaviside(x)
    H = 0.5 * (sign(x) + 1);
end

function B = computeBsalt(T, p, rhoH2, ms)
    deltaP = p ./ 1e5 - 1; % pressure range [bar] from p0 = 1 bar to p
    v_av_H2 = 26.7; % average partial molar volume of H2 [cm3/mol]
    R = 83.1446261815324; % universal gas constant [bar.cm3/mol.K]
    k0_H2 = equilibriumConstantH2(T); % equilibrium constant for H2 at 1 bar
    gammSalt = activitySalt(ms, T, p / 1e5);
    phi_H2 = fugacityCoefficientH2(T, p, rhoH2); % fugacity coefficient of H2 for the water-H2 system
    p_bar = p ./ 1e5;
    B = (phi_H2 .* p_bar) ./ (55.508 .* k0_H2 .* gammSalt) .* exp(-(deltaP .* v_av_H2) ./ (R .* T));
end
