function figures = plotBlackOilAquifer2D(result, varargin)
    % PLOTBLACKOILAQUIFER2D Redraw saline-aquifer storage figures.
    %
    % SYNOPSIS:
    %   figures = plotBlackOilAquifer2D(result)
    %   figures = plotBlackOilAquifer2D(result, 'outputDirectory', folder)
    %
    % Returns plume, well response, dissolution and geology figure handles,
    % in that order. Figures are hidden in batch mode.
    % Uses accepted states without rerunning flow. Writes PNG and vector PDF
    % files when outputDirectory is set. Outputs are overwritten. Saturation
    % limits are shared with animateBlackOilAquifer2D for the same result.
    opt = merge_options(struct('outputDirectory', ''), varargin{:});
    data = aquiferPresentationData(result);
    style = h2simStoragePlotStyle();
    G = result.model.G;
    times = cumsum(result.schedule.step.val) / day;
    ends = getCyclesLastSteps(result.schedule);
    indices = [ends.cushion(1), ends.charge(end), ends.discharge(end)];
    labels = {'After build-up', ...
        sprintf('Injection · cycle %d', numel(ends.charge)), ...
        sprintf('Withdrawal · cycle %d', numel(ends.discharge))};
    f = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 27, 11]);
    tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    maximum = data.saturationMaximum;
    for j = 1:3
        ax = nexttile;
        plotCellData(G, result.states{indices(j)}.s(:, 2), 'EdgeColor', 'none');
        hold(ax, 'on');
        x = linspace(0, 50, 150);
        plot(ax, x, 25.1 + 5 * sin(pi * x / 50), 'k-', 'LineWidth', 1.1);
        wc = result.schedule.control(1).W.cells;
        plot(ax, G.cells.centroids(wc, 1), G.cells.centroids(wc, 2), ...
            'wo', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
        view(ax, 2);
        axis(ax, 'equal');
        axis(ax, [0, 50, 0, 50]);
        xlabel(ax, 'Horizontal distance (m)');
        ylabel(ax, 'Elevation (m)');
        title(ax, sprintf('%s · day %.1f', labels{j}, times(indices(j))));
        caxis(ax, [0, max(maximum, 0.01)]);
        colormap(ax, style.saturation);
        cb = colorbar(ax);
        ylabel(cb, 'H_2 gas saturation (-)');
        set(ax, 'FontName', 'Arial', 'FontSize', 10, 'LineWidth', 0.7);
        box(ax, 'on');
    end
    exportPlot(f, opt.outputDirectory, 'aquifer_plume');
    g = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 23, 10]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    ax = nexttile;
    rate = data.rate / day;
    stairs(ax, data.times, [data.rate; data.rate(end)], ...
        'Tag', 'aquifer-well-rate', 'LineWidth', 1.8, 'Color', style.figureTeal);
    yline(ax, 0, ':');
    xlabel(ax, 'Time (days)');
    ylabel(ax, 'Gas surface rate (m^3/day)');
    title(ax, 'Injection and withdrawal');
    ax2 = nexttile;
    bhp = data.bhp * barsa;
    plot(ax2, times, bhp / 1e5, 'LineWidth', 1.8, 'Color', style.figureOrange);
    xlabel(ax2, 'Time (days)');
    ylabel(ax2, 'Bottom-hole pressure (bar)');
    title(ax2, 'Active well pressure');
    for j = 1:numel(ends.charge)
        if j == 1
            cycleStart = times(ends.cushion(1)) + result.setup.timeShut / day;
        else
            cycleStart = times(ends.discharge(j - 1));
        end
        for a = [ax, ax2]
            xline(a, cycleStart, ':', 'Color', [.65, .65, .65], 'HandleVisibility', 'off');
        end
        text(ax, cycleStart + result.setup.timeCharge / day / 2, ...
            max(rate * day) * 1.08, sprintf('Cycle %d', j), ...
            'HorizontalAlignment', 'center', 'FontSize', 8);
    end
    ylim(ax, [min(rate * day) * 1.15, max(rate * day) * 1.2]);
    for a = [ax, ax2]
        set(a, 'FontName', 'Arial', 'FontSize', 10, 'LineWidth', 0.7);
        grid(a, 'on');
        box(a, 'on');
    end
    exportPlot(g, opt.outputDirectory, 'aquifer_well_response');
    % Surface-equivalent inventories use pore volume, liquid saturation and Rs.
    % Dissolution is phase partitioning, not irreversible hydrogen destruction.
    dissolved = data.dissolved(2:end);
    free = data.free(2:end);
    fraction = data.fraction(2:end);
    h = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 23, 10]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    a = nexttile;
    plot(a, times, dissolved, 'LineWidth', 1.8, 'Color', style.figureTeal);
    xlabel(a, 'Time (days)');
    ylabel(a, 'Dissolved H_2 (surface m^3)');
    title(a, 'Hydrogen retained in brine');
    a2 = nexttile;
    plot(a2, times, fraction, 'LineWidth', 1.8, 'Color', style.figureOrange);
    xlabel(a2, 'Time (days)');
    ylabel(a2, 'Dissolved share of retained H_2 (%)');
    title(a2, 'Dissolved share during cycling');
    cycleStart = times(ends.cushion(1)) + result.setup.timeShut / day;
    xlim(a2, [cycleStart, times(end)]);
    ylim(a2, [0, max(1, 1.15 * max(fraction(times >= cycleStart)))]);
    for a = [a, a2]
        set(a, 'FontName', 'Arial', 'FontSize', 10, 'LineWidth', 0.7);
        grid(a, 'on');
        box(a, 'on');
    end
    exportPlot(h, opt.outputDirectory, 'aquifer_dissolution');
    if ~isempty(opt.outputDirectory)
        writetable(table(times, dissolved, free, fraction, 'VariableNames', ...
            {'Time_days', 'DissolvedH2_surface_m3', 'FreeH2_surface_m3', 'DissolvedShare_percent'}), ...
            fullfile(opt.outputDirectory, 'aquifer_dissolution.csv'));
    end
    geology = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 21, 14]);
    ax = axes(geology);
    hold(ax, 'on');
    colors = [0.92, 0.76, 0.43; 0.37, 0.43, 0.51; 0.58, 0.6, 0.64];
    handles = gobjects(3, 1);
    region = result.model.rock.regions.saturation;
    for layer = 1:3
        handles(layer) = plotGrid(G, region == layer, 'Parent', ax, ...
            'FaceColor', colors(layer, :), 'EdgeColor', 'none');
    end
    wc = result.schedule.control(1).W.cells;
    well = plot(ax, G.cells.centroids(wc, 1), G.cells.centroids(wc, 2), ...
        'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 5);
    view(ax, 2);
    axis(ax, 'equal');
    axis(ax, [0, 50, 0, 50]);
    xlabel(ax, 'Horizontal distance (m)');
    ylabel(ax, 'Elevation (m)');
    title(ax, 'Structural trap and well completions');
    legend(ax, [handles; well], 'Reservoir', 'Bedrock', 'Caprock', ...
        'Well completion', 'Location', 'eastoutside');
    set(ax, 'FontName', 'Arial', 'FontSize', 10, 'LineWidth', 0.7, 'Box', 'on');
    exportPlot(geology, opt.outputDirectory, 'aquifer_geology');
    f.UserData = struct('sourceStateIndices', indices + 1, ...
        'actualTimesDays', times(indices), 'saturationLimits', [0, maximum]);
    g.UserData = struct('actualTimesDays', data.times, ...
        'rateSurfaceM3PerDay', data.rate, 'activeBhpBar', data.bhp);
    h.UserData = struct('actualTimesDays', times, ...
        'dissolvedSurfaceM3', dissolved, 'freeSurfaceM3', free);
    figures = [f, g, h, geology];
    if usejava('desktop')
        set(figures, 'Visible', 'on');
    end
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
