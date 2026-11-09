function figures = plotCompositionalBacterial2DThreeReactions(results, varargin)
    % PLOTCOMPOSITIONALBACTERIAL2DTHREEREACTIONS Redraw the existing 2D storage case.
    %
    % SYNOPSIS:
    %   figures = plotCompositionalBacterial2DThreeReactions(results)
    %   figures = plotCompositionalBacterial2DThreeReactions(results, ...
    %       'outputDirectory', folder)
    %
    % Redraws saved results without running flow. Returns gas-comparison and
    % well-log figures, then population/consumption figures for microbial
    % cases, and a geology figure. PNG/vector PDF exports overwrite outputs.
    % Batch figures are hidden. Population limits span the entire history,
    % matching animateCompositionalBacterial2DThreeReactions.
    % Maps show gas-phase mole fractions, masked where gas saturation < 0.001.
    % Well logs use signed component mass rates: injection positive, production negative.
    opt = merge_options(struct('outputDirectory', ''), varargin{:});
    if ~isempty(opt.outputDirectory) && ~isfolder(opt.outputDirectory)
        mkdir(opt.outputDirectory);
    end
    assert(all([results.complete]), 'Cycle figures require completed simulations.');
    palette = h2simStoragePlotStyle();
    labels = {'H_2', 'CO_2', 'CH_4'};
    components = [2, 3, 4];
    colors = [palette.figureTeal; palette.figureOrange; 0.35, 0.35, 0.7];
    styles = {'-', '--', ':'};
    n = numel(results);
    f = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 27, 6.5 * n]);
    tiledlayout(n, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    for j = 1:n
        r = results(j);
        ends = getCyclesLastSteps(r.schedule);
        index = ends.charge(end);
        t = sum(r.schedule.step.val(1:index)) / day;
        s = r.states{index};
        for c = 1:3
            ax = nexttile;
            data = s.y(:, components(c));
            data(s.s(:, 2) < 1e-3) = nan;
            plotCellData(r.model.G, data, 'EdgeColor', 'none');
            hold(ax, 'on');
            wc = r.schedule.control(1).W.cells;
            plot(ax, r.model.G.cells.centroids(wc, 1), r.model.G.cells.centroids(wc, 2), 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 3);
            view(ax, 2);
            axis(ax, 'equal');
            axis(ax, [0, 50, 0, 50]);
            caxis(ax, [0, 1]);
            colormap(ax, palette.saturation);
            xlabel(ax, 'Horizontal distance (m)');
            ylabel(ax, 'Elevation (m)');
            title(ax, sprintf('%s · %s · injection %d, day %g', labels{c}, r.name, numel(ends.charge), t));
            cb = colorbar(ax);
            ylabel(cb, 'Gas-phase mole fraction (-)');
            set(ax, 'FontName', 'Arial', 'FontSize', 9);
            box(ax, 'on');
        end
    end
    exportPlot(f, opt.outputDirectory, 'compositional_2d_gas_maps');
    g = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 25, 17]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    axesLogs = gobjects(1, 4);
    for c = 1:4
        axesLogs(c) = nexttile;
        hold(axesLogs(c), 'on');
    end
    for j = 1:n
        r = results(j);
        t = cumsum(r.schedule.step.val) / day;
        color = colors(mod(j - 1, size(colors, 1)) + 1, :);
        style = styles{mod(j - 1, 3) + 1};
        presentation = biochemistryStoragePresentationData(r);
        logData = [presentation.massRate, presentation.bhp];
        for c = 1:4
            if c <= 3
                stairs(axesLogs(c), presentation.times, ...
                    [logData(:, c); logData(end, c)], 'Color', color, ...
                    'LineStyle', style, 'LineWidth', 1.7, 'DisplayName', r.name, ...
                    'Tag', sprintf('%s-rate-%d', r.name, c));
            else
                plot(axesLogs(c), t, logData(:, c), 'Color', color, ...
                    'LineStyle', style, 'LineWidth', 1.7, 'DisplayName', r.name, ...
                    'Tag', sprintf('%s-bhp', r.name));
            end
        end
        if ~isempty(opt.outputDirectory)
            writetable(array2table([t, logData], 'VariableNames', ...
                {'Time_days', 'H2_kg_day', 'CO2_kg_day', 'CH4_kg_day', 'BHP_bar'}), ...
                fullfile(opt.outputDirectory, [r.name, '_well_logs.csv']));
        end
    end
    for c = 1:4
        a = axesLogs(c);
        xlabel(a, 'Time (days)');
        if c <= 3
            ylabel(a, [labels{c}, ' component rate (kg/day)']);
            title(a, [labels{c}, ' well log']);
            yline(a, 0, ':', 'HandleVisibility', 'off');
        else
            ylabel(a, 'Bottom-hole pressure (bar)');
            title(a, 'Well pressure');
        end
        grid(a, 'on');
        box(a, 'on');
        legend(a, 'Location', 'best');
        set(a, 'FontName', 'Arial', 'FontSize', 10);
    end
    exportPlot(g, opt.outputDirectory, 'compositional_2d_cycle_logs');
    figures = [f, g];
    for j = 1:n
        r = results(j);
        if ~r.model.bacteriamodel
            continue
        end
        t = cumsum(r.schedule.step.val) / day;
        ends = getCyclesLastSteps(r.schedule);
        samples = [ends.cushion(1), ends.charge(end)];
        presentation = biochemistryStoragePresentationData(r);
        reactionNames = {'MET', 'ACE', 'SRB'};
        h = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 32, 13]);
        tiledlayout(2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
        for row = 1:2
            state = r.states{samples(row)};
            for c = 1:4
                a = nexttile;
                if c == 1
                    data = state.y(:, 2);
                    data(state.s(:, 2) < 1e-3) = nan;
                    clim = [0, 1];
                    name = 'H_2';
                    unit = 'Gas mole fraction (-)';
                else
                    data = state.nbact(:, c - 1);
                    name = reactionNames{c - 1};
                    unit = 'nbact (model units)';
                    clim = presentation.biomassLimits(c - 1, :);
                end
                plotCellData(r.model.G, data, 'EdgeColor', 'none');
                view(a, 2);
                axis(a, 'equal');
                axis(a, [0, 50, 0, 50]);
                caxis(a, clim);
                colormap(a, palette.saturation);
                cb = colorbar(a);
                ylabel(cb, unit);
                title(a, sprintf('%s · day %g', name, t(samples(row))));
                xlabel(a, 'Horizontal distance (m)');
                ylabel(a, 'Elevation (m)');
                set(a, 'FontName', 'Arial', 'FontSize', 9);
            end
        end
        exportPlot(h, opt.outputDirectory, 'compositional_2d_bacterial_maps');
        pct = presentation.percent(2:end, :);
        h.UserData = struct('sourceStateIndices', samples + 1, ...
            'actualTimesDays', t(samples), 'biomassLimits', presentation.biomassLimits);
        q = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 23, 11]);
        a = axes(q);
        hold(a, 'on');
        for c = 1:3
            reactionColors = [palette.figureTeal; palette.figureOrange; 0.35, 0.35, 0.7];
            plot(a, t, pct(:, c), 'LineWidth', 1.8, ...
                'Color', reactionColors(c, :), 'DisplayName', reactionNames{c});
        end
        plot(a, t, sum(pct, 2), 'k--', 'LineWidth', 1.8, 'DisplayName', 'Total');
        xlabel(a, 'Time (days)');
        ylabel(a, 'Consumed H_2 / cumulative injected H_2 (%)');
        title(a, 'Hydrogen consumption by microbial reaction');
        legend(a, 'Location', 'best');
        grid(a, 'on');
        box(a, 'on');
        q.UserData = struct('actualTimesDays', t, 'consumptionPercent', pct);
        exportPlot(q, opt.outputDirectory, 'compositional_2d_h2_consumption');
        if ~isempty(opt.outputDirectory)
            writetable(array2table([t, pct, sum(pct, 2)], 'VariableNames', ...
                {'Time_days', 'MET_percent', 'ACE_percent', 'SRB_percent', 'Total_percent'}), ...
                fullfile(opt.outputDirectory, 'compositional_2d_h2_consumption.csv'));
        end
        figures = [figures, h, q]; %#ok<AGROW>
    end
    geology = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 21, 14]);
    ax = axes(geology);
    hold(ax, 'on');
    G = results(1).model.G;
    colors = [0.92, 0.76, 0.43; 0.37, 0.43, 0.51; 0.58, 0.6, 0.64];
    handles = gobjects(3, 1);
    region = results(1).model.rock.regions.saturation;
    for layer = 1:3
        handles(layer) = plotGrid(G, region == layer, 'Parent', ax, ...
            'FaceColor', colors(layer, :), 'EdgeColor', 'none');
    end
    wc = results(1).schedule.control(1).W.cells;
    well = plot(ax, G.cells.centroids(wc, 1), G.cells.centroids(wc, 2), ...
        'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 4);
    view(ax, 2);
    axis(ax, 'equal');
    axis(ax, [0, 50, 0, 50]);
    xlabel(ax, 'Horizontal distance (m)');
    ylabel(ax, 'Elevation (m)');
    title(ax, 'Depleted-reservoir geometry and well completions');
    legend(ax, [handles; well], 'Reservoir', 'Bedrock', 'Caprock', ...
        'Well completion', 'Location', 'eastoutside');
    set(ax, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on');
    exportPlot(geology, opt.outputDirectory, 'compositional_2d_geology');
    figures = [figures, geology];
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
