function figures = plotBlackOilAquifer2D(result, varargin)
    % PLOTBLACKOILAQUIFER2D Plume snapshots and well response from saved results.
    opt = merge_options(struct('outputDirectory', ''), varargin{:});
    G = result.model.G;
    times = cumsum(result.schedule.step.val) / day;
    ends = getCyclesLastSteps(result.schedule);
    indices = [ends.cushion(1), ends.charge(end), ends.discharge(end)];
    labels = {'After build-up', sprintf('Injection · cycle %d', numel(ends.charge)), sprintf('Withdrawal · cycle %d', numel(ends.discharge))};
    f = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 27, 11]);
    tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    maximum = max(cellfun(@(s) max(s.s(:, 2)), result.states));
    for j = 1:3
        ax = nexttile;
        plotCellData(G, result.states{indices(j)}.s(:, 2), 'EdgeColor', 'none');
        hold(ax, 'on');
        x = linspace(0, 50, 150);
        plot(ax, x, 25 + 5 * sin(pi * x / 50), 'k-', 'LineWidth', 1.1);
        wc = result.schedule.control(1).W.cells;
        plot(ax, G.cells.centroids(wc, 1), G.cells.centroids(wc, 2), 'wo', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
        view(ax, 2);
        axis(ax, 'equal');
        axis(ax, [0, 50, 0, 50]);
        xlabel(ax, 'Horizontal distance (m)');
        ylabel(ax, 'Elevation (m)');
        title(ax, sprintf('%s · day %.1f', labels{j}, times(indices(j))));
        caxis(ax, [0, max(maximum, 0.01)]);
        colormap(ax, parula(256));
        cb = colorbar(ax);
        ylabel(cb, 'H_2 gas saturation (-)');
        set(ax, 'FontName', 'Arial', 'FontSize', 10);
        box(ax, 'on');
    end
    exportPlot(f, opt.outputDirectory, 'aquifer_plume');
    g = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 23, 10]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    ax = nexttile;
    rate = cellfun(@(w) w(1).qGs, result.wellSols);
    plot(ax, times, rate * day, 'LineWidth', 1.8, 'Color', [.04, .5, .51]);
    yline(ax, 0, ':');
    xlabel(ax, 'Time (days)');
    ylabel(ax, 'Gas surface rate (m^3/day)');
    title(ax, 'Injection and withdrawal');
    ax2 = nexttile;
    bhp = cellfun(@(w) w(1).bhp, result.wellSols);
    plot(ax2, times, bhp / 1e5, 'LineWidth', 1.8, 'Color', [.85, .5, .2]);
    xlabel(ax2, 'Time (days)');
    ylabel(ax2, 'Bottom-hole pressure (bar)');
    title(ax2, 'Well pressure');
    for j = 1:numel(ends.charge)
        if j == 1
            cycleStart = times(ends.cushion(1)) + result.setup.timeShut / day;
        else
            cycleStart = times(ends.discharge(j - 1));
        end
        for a = [ax, ax2]
            xline(a, cycleStart, ':', 'Color', [.65, .65, .65], 'HandleVisibility', 'off');
        end
        text(ax, cycleStart + result.setup.timeCharge / day / 2, max(rate * day) * 1.08, sprintf('Cycle %d', j), 'HorizontalAlignment', 'center', 'FontSize', 8);
    end
    ylim(ax, [min(rate * day) * 1.15, max(rate * day) * 1.2]);
    for a = [ax, ax2]
        set(a, 'FontName', 'Arial', 'FontSize', 10);
        grid(a, 'on');
        box(a, 'on');
    end
    exportPlot(g, opt.outputDirectory, 'aquifer_well_response');
    % Surface-equivalent inventories use pore volume, liquid saturation and Rs.
    % Dissolution is phase partitioning, not irreversible hydrogen destruction.
    inventoryModel = result.model.setupStateFunctionGroupings();
    dissolved = zeros(numel(times), 1);
    free = dissolved;
    for k = 1:numel(times)
        state = result.states{k};
        pv = value(inventoryModel.getProp(state, 'PoreVolume'));
        b = inventoryModel.getProp(state, 'ShrinkageFactors');
        dissolved(k) = sum(pv .* state.s(:, 1) .* value(b{1}) .* state.rs);
        free(k) = sum(pv .* state.s(:, 2) .* value(b{2}));
    end
    fraction = 100 * dissolved ./ max(dissolved + free, eps);
    h = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 23, 10]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    a = nexttile;
    plot(a, times, dissolved, 'LineWidth', 1.8, 'Color', [.04, .5, .51]);
    xlabel(a, 'Time (days)');
    ylabel(a, 'Dissolved H_2 (surface m^3)');
    title(a, 'Hydrogen retained in brine');
    a2 = nexttile;
    plot(a2, times, fraction, 'LineWidth', 1.8, 'Color', [.85, .5, .2]);
    xlabel(a2, 'Time (days)');
    ylabel(a2, 'Dissolved share of retained H_2 (%)');
    title(a2, 'Dissolved share during cycling');
    cycleStart = times(ends.cushion(1)) + result.setup.timeShut / day;
    xlim(a2, [cycleStart, times(end)]);
    ylim(a2, [0, 1.15 * max(fraction(times >= cycleStart))]);
    for a = [a, a2]
        set(a, 'FontName', 'Arial', 'FontSize', 10);
        grid(a, 'on');
        box(a, 'on');
    end
    exportPlot(h, opt.outputDirectory, 'aquifer_dissolution');
    if ~isempty(opt.outputDirectory)
        writetable(table(times, dissolved, free, fraction, 'VariableNames', ...
            {'Time_days', 'DissolvedH2_surface_m3', 'FreeH2_surface_m3', 'DissolvedShare_percent'}), ...
            fullfile(opt.outputDirectory, 'aquifer_dissolution.csv'));
    end
    figures = [f, g, h];
end

function exportPlot(f, folder, name)
    if isempty(folder)
        return
    end
    if ~isfolder(folder)
        mkdir(folder);
    end
    exportgraphics(f, fullfile(folder, [name, '.png']), 'Resolution', 200);
    exportgraphics(f, fullfile(folder, [name, '.pdf']), 'ContentType', 'vector');
end
