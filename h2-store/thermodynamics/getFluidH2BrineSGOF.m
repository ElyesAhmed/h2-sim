function getFluidH2BrineSGOF(varargin)
    % GETFLUIDH2BRINESGOF Write hydrogen-brine relative permeability tables.
    %
    % SYNOPSIS:
    %   getFluidH2BrineSGOF('plot', false, 'outputPath', folder)
    %
    % The oil phase represents brine. Each region contains gas saturation, gas
    % relative permeability, brine relative permeability and gas-oil capillary
    % pressure. The output is an Eclipse SGOF keyword with slash-delimited regions.
    %
    % OPTIONAL PARAMETERS:
    %   n           - Saturation points per region, default 100.
    %   nreg        - Number of regions, default 1.
    %   sw_imm      - Immobile brine saturation per region, default 0.1.
    %   sg_imm      - Immobile gas saturation per region, default 0.1.
    %   c_a1, c_a2  - Brine/gas relative permeability exponents, defaults 2.
    %   c_a3        - Capillary pressure exponent, default 1.5.
    %   Pe          - Entry-pressure coefficient [Pa] per region, default 0.4.
    %   P_c_max     - Capillary pressure bound [Pa] per region, default 9.5e4.
    %   units       - Output unit system, default 'metric'.
    %   plot        - Display property curves, default true.
    %   outputPath  - Output folder; empty selects MRST's UHS_PVT/PVT_H2STORAGE.
    %   fileName    - Output filename, default 'SGOF_UHS.txt'.
    %   reCompute   - Overwrite an existing file, default true. If false, an
    %                 existing file is kept without reading or regenerating it.
    %
    % Supply one value per region for sw_imm, sg_imm, Pe and P_c_max. Pressure
    % inputs are in SI units and converted to the requested output unit system.
    %
    % SEE ALSO:
    %   readSGOFTables, getFluidH2BrineProps.

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

    % Parse input arguments and set defaults
    opts = struct('n', 100, ...
        'plot', true, ...
        'outputPath', '', ...
        'reCompute', true, ...
        'fileName', 'SGOF_UHS.txt', ...
        'units', 'metric', ...
        'nreg', 1, ...
        'sw_imm', 0.1, ...
        'sg_imm', 0.1, ...
        'c_a1', 2, ...
        'c_a2', 2, ...
        'c_a3', 1.5, ...
        'Pe', 0.4, ...
        'P_c_max', 9.5e4);

    opts = merge_options(opts, varargin{:});
    u = unitConversionFactors('si', opts.units);

    % Ensure the output directory exists
    if isempty(opts.outputPath)
        opts.outputPath = fullfile(mrstOutputDirectory(), 'UHS_PVT', 'PVT_H2STORAGE');
    end

    filePath = fullfile(opts.outputPath, opts.fileName);
    if exist(filePath, 'file') && (~opts.reCompute)
        fprintf('File %s already exists. Keeping existing file...\n', opts.fileName);
        return  % Exit the function as the table already exists
    end
    if ~exist(opts.outputPath, 'dir')
        mkdir(opts.outputPath);
    end

    % Open file for writing
    fn = fopen(filePath, 'w');
    assert(fn >= 0, 'h2sim:SGOF:OpenFailed', 'Could not open SGOF file: %s', filePath);
    fileCleanup = onCleanup(@() fclose(fn));
    fprintf(fn, '-- SG    KRG    KROG   PCOG\n');
    fprintf(fn, 'SGOF\n');

    % Compute properties for each region
    for reg = 1:opts.nreg
        s0 = opts.sg_imm(reg);  % Single value for immiscible gas saturation
        sat = [0, linspace(s0, 1, opts.n - 1)]; % Saturation points
        sg = scale_saturation(sat, s0); % Scaled gas saturation
        so = scale_saturation(1 - sat, opts.sw_imm(reg)); % Scaled oil saturation
        krg = sg.^opts.c_a2; % Gas relative permeability
        kro = so.^opts.c_a1; % Oil relative permeability
        pcUnbounded = opts.Pe(reg) * so.^(1 - opts.c_a3); % Pressure at gas-oil contact

        pcmax = opts.P_c_max(reg);
        pc_og = pcmax * erf((pcUnbounded / pcmax) * (sqrt(pi) / 2)); % Adjusted pressure

        % Plotting results if enabled
        if opts.plot
            % Plot Relative Permeabilities
            figure;

            % Plot krO (Oil Relative Permeability)
            subplot(1, 2, 1);
            hold on;
            plot(1 - sat, kro, 'LineWidth', 2);
            title('Oil Relative Permeability (krO)');
            xlabel('Saturation');
            ylabel('krO');
            grid on;
            legend('krO');

            % Plot krG (Gas Relative Permeability)
            subplot(1, 2, 2);
            hold on;
            plot(sat, krg, 'LineWidth', 2);
            title('Gas Relative Permeability (krG)');
            xlabel('Saturation');
            ylabel('krG');
            grid on;
            legend('krG');

            % Plot Capillary Pressure (pcOG) for multiple regions
            figure(2);
            subplot(1, opts.nreg, reg);
            hold on;
            title(['Capillary Pressure (pcOG) - Region ', num2str(reg)]);
            plot(sat, pcUnbounded, 'o', 'MarkerSize', 6, 'DisplayName', 'Unbounded pcOG (Pa)');
            plot(sat, pc_og, 'LineWidth', 2, 'DisplayName', 'pcOG');
            xlabel('Saturation');
            ylabel('pcOG (Pa)');
            grid on;
            legend;
        end

        % Write computed properties to file
        records = [sat; krg; kro; pc_og * u.press];
        fprintf(fn, '%1.8f %1.8f %1.8f %1.8f\n', records);
        fprintf(fn, '/\n');
    end

    % Display completion message
    disp([opts.fileName ' written!']);
    clear fileCleanup;
end

function s_scaled = scale_saturation(s, s_imm)
    % SCALE_SATURATION Normalize saturation above the immobile threshold.
    s_scaled = max((s - s_imm) / (1 - s_imm), 0);
end
