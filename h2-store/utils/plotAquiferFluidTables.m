function f = plotAquiferFluidTables(result, varargin)
    % PLOTAQUIFERFLUIDTABLES Inspect the PVT functions used by the aquifer deck.
    opt = merge_options(struct('outputDirectory', ''), varargin{:});
    fluid = result.model.fluid;
    p = linspace(30, 50, 150)' * barsa;
    rs = fluid.rsSat(p);
    bg = 1 ./ fluid.bG(p);
    bo = 1 ./ fluid.bO(p, rs, true(size(p)));
    mu = fluid.muG(p) * 1000; % Pa s to mPa s
    f = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 24, 17]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    values = {rs, bg, bo, mu};
    labels = {'Solution ratio R_s (surface m^3/m^3)', 'Gas FVF B_g (reservoir m^3/surface m^3)', ...
        'Liquid FVF B_l (reservoir m^3/surface m^3)', 'Hydrogen viscosity (mPa s)'};
    titles = {'Hydrogen solubility', 'Gas volume factor', 'Saturated liquid volume factor', 'Gas viscosity'};
    for k = 1:4
        a = nexttile;
        plot(a, p / barsa, values{k}, 'LineWidth', 1.8, 'Color', [.04, .5, .51]);
        xlabel(a, 'Pressure (bar)');
        ylabel(a, labels{k});
        title(a, titles{k});
        grid(a, 'on');
        box(a, 'on');
        set(a, 'FontName', 'Arial', 'FontSize', 10);
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
