function f = plotAquiferFluidTables(result, varargin)
    % PLOTAQUIFERFLUIDTABLES Inspect the PVT functions used by the aquifer deck.
    opt = merge_options(struct('outputDirectory', ''), varargin{:});
    style = h2simStoragePlotStyle();
    fluid = result.model.fluid;
    p = linspace(30, 50, 150)' * barsa;
    rs = fluid.rsSat(p);
    bg = 1 ./ fluid.bG(p);
    bo = 1 ./ fluid.bO(p, rs, true(size(p)));
    mu = fluid.muG(p) * 1000; % Pa s to mPa s
    f = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 24, 17]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    values = {rs, bg, bo, mu};
    labels = {'Solution ratio R_s (surface m^3/m^3)', 'Gas FVF B_g (reservoir m^3/surface m^3)', ...
        'Liquid FVF B_l (reservoir m^3/surface m^3)', 'Hydrogen viscosity (mPa s)'};
    titles = {'Hydrogen solubility', 'Gas volume factor', 'Saturated liquid volume factor', 'Gas viscosity'};
    for k = 1:4
        a = nexttile;
        plot(a, p / barsa, values{k}, 'LineWidth', 1.8, 'Color', style.figureTeal);
        xlabel(a, 'Pressure (bar)');
        ylabel(a, labels{k});
        title(a, titles{k});
        grid(a, 'on');
        box(a, 'on');
        set(a, 'FontName', 'Arial', 'FontSize', 10);
    end
    if usejava('desktop')
        set(f, 'Visible', 'on');
    end
    if ~isempty(opt.outputDirectory)
        if ~isfolder(opt.outputDirectory)
            mkdir(opt.outputDirectory);
        end
        exportgraphics(f, fullfile(opt.outputDirectory, 'aquifer_fluid_tables.png'), 'Resolution', 200);
        exportgraphics(f, fullfile(opt.outputDirectory, 'aquifer_fluid_tables.pdf'), 'ContentType', 'vector');
        writetable(table(p / barsa, rs, bg, bo, mu, 'VariableNames', ...
            {'Pressure_bar', 'Rs', 'Bg', 'Bl', 'GasViscosity_mPa_s'}), fullfile(opt.outputDirectory, 'aquifer_fluid_tables.csv'));
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
