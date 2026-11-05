function figures = plotHydrogenAnticline(result, varargin)
    % PLOTHYDROGENANTICLINE Geology, plume snapshots and storage-cycle figures.
    %
    % SYNOPSIS:
    %   figures = plotHydrogenAnticline(result)
    %   figures = plotHydrogenAnticline(result, 'outputDirectory', folder)
    %
    % Uses saved initial/accepted states without running a simulation. Returns
    % geology, plume and operations figure handles. With outputDirectory set,
    % writes anticline_geology, anticline_plume_snapshots and anticline_operations
    % as 200-dpi PNG and vector PDF files. Existing output files are overwritten.
    %
    % Snapshot times are nearest accepted times, labelled with their actual
    % day and operation. Saturations share [0,0.8] limits; cells below 0.005
    % are hidden in the section. Section depth has twofold vertical exaggeration.
    % Well BHP is shown only while active. Rate signs and surface reference
    % conditions follow the simulation. Figure UserData records plotted times.
    parser = inputParser();
    parser.PartialMatching = false;
    addParameter(parser, 'outputDirectory', '', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(parser, varargin{:});
    diagnostics = checkHydrogenAnticline(result);
    model = result.model;
    G = model.G;
    [~, j, ~] = ind2sub(G.cartDims, G.cells.indexMap);
    section = j == (G.cartDims(2) + 1) / 2;
    states = [{result.state0}; result.states(:)];
    times = [0; cumsum(result.schedule.step.val)] / day;

    figures.geology = geologyFigure(result, section);
    figures.plume = plumeFigure(result, states, times, section);
    figures.operations = operationFigure(result, states, times, diagnostics);
    if usejava('desktop')
        set([figures.geology, figures.plume, figures.operations], 'Visible', 'on');
    end
    output = char(parser.Results.outputDirectory);
    if ~isempty(output)
        if ~isfolder(output)
            mkdir(output);
        end
        names = {'geology', 'plume', 'operations'};
        files = {'anticline_geology', 'anticline_plume_snapshots', 'anticline_operations'};
        for index = 1:numel(names)
            figureHandle = figures.(names{index});
            exportgraphics(figureHandle, fullfile(output, [files{index}, '.png']), ...
                'Resolution', 200, 'BackgroundColor', 'white');
            exportgraphics(figureHandle, fullfile(output, [files{index}, '.pdf']), ...
                'ContentType', 'vector', 'BackgroundColor', 'white');
        end
    end
end

function fig = geologyFigure(result, section)
    fig = newFigure('Anticline geology', [24, 12]);
    ax = axes(fig, 'Position', [0.09, 0.2, 0.86, 0.66]);
    hold(ax, 'on');
    G = result.model.G;
    region = result.model.rock.regions.saturation;
    colors = [0.55, 0.77, 0.85; 0.58, 0.6, 0.64; ...
        0.92, 0.76, 0.43; 0.37, 0.43, 0.51];
    handles = gobjects(4, 1);
    for layer = 1:4
        handles(layer) = plotGrid(G, section & region == layer, ...
            'Parent', ax, 'FaceColor', colors(layer, :), 'EdgeColor', 'none');
    end
    plot3(ax, [2500, 2500], [2500, 2500], [260, 425], ...
        'k-', 'LineWidth', 2.4);
    text(ax, 2570, 2500, 278, 'Storage well', 'FontSize', 10);
    sectionAxes(ax, [0, 5000], [250, 800]);
    title(ax, 'Four-layer Gaussian structure and central storage well');
    names = result.configuration.layerNames;
    legend(ax, handles, names, 'Location', 'southoutside', ...
        'Orientation', 'horizontal', 'Box', 'off');
    fig.UserData = struct('sectionCellIndices', find(section), ...
        'verticalExaggeration', 2);
end

function fig = plumeFigure(result, states, times, section)
    config = result.configuration;
    buildup = config.buildupDays;
    shut = buildup + config.shutInDays;
    targets = [min(30, buildup / 4), buildup / 2, buildup, ...
        shut, shut + config.cycleStageDays, shut + 2 * config.cycleStageDays];
    targets = min(targets, times(end));
    indices = zeros(size(targets));
    for index = 1:numel(targets)
        [~, indices(index)] = min(abs(times - targets(index)));
    end
    fig = newFigure('Anticline plume development', [26, 10]);
    layout = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    G = result.model.G;
    region = result.model.rock.regions.saturation;
    for panel = 1:numel(indices)
        ax = nexttile(layout);
        hold(ax, 'on');
        for layer = 1:4
            gray = [0.9, 0.92, 0.94] - (layer == 2) * 0.12;
            plotGrid(G, section & region == layer, 'Parent', ax, ...
                'FaceColor', gray, 'EdgeColor', 'none');
        end
        frame = indices(panel);
        saturation = states{frame}.s(:, result.model.getPhaseIndex('G'));
        visible = section & saturation >= 0.005;
        if any(visible)
            plotCellData(G, saturation, visible, 'Parent', ax, 'EdgeColor', 'none');
        end
        plot3(ax, [2500, 2500], [2500, 2500], [300, 425], ...
            'k-', 'LineWidth', 1.2);
        sectionAxes(ax, [1400, 3600], [300, 760]);
        colormap(ax, plumeColors());
        % caxis preserves support for MATLAB R2021a.
        caxis(ax, [0, 0.8]);
        title(ax, sprintf('(%s) Day %.1f | %s', char('a' + panel - 1), ...
            times(frame), operationName(result, frame)), 'FontSize', 9);
        if panel <= 3
            xlabel(ax, '');
        end
        if mod(panel, 3) ~= 1
            zlabel(ax, '');
        end
    end
    color = colorbar(ax);
    color.Layout.Tile = 'east';
    color.Label.String = 'Hydrogen gas saturation';
    title(layout, 'Plume development through cushion injection and the first storage cycle');
    fig.UserData = struct('sourceStateIndices', indices, ...
        'actualTimesDays', times(indices), 'targetTimesDays', targets, ...
        'verticalExaggeration', 2, 'gasSaturationThreshold', 0.005);
end

function fig = operationFigure(result, states, times, diagnostics)
    fig = newFigure('Anticline storage operations', [25, 18]);
    layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    style = h2simStoragePlotStyle();
    teal = style.figureTeal;
    orange = style.figureOrange;
    inventory = diagnostics.hydrogenSurfaceVolumeM3 / 1e6;
    dt = result.schedule.step.val;
    exchange = inventory(1) + [0; cumsum(dt .* ( ...
        diagnostics.wellGasSurfaceRateM3PerSecond + ...
        diagnostics.boundaryGasSurfaceRateM3PerSecond))] / 1e6;
    ax = nexttile(layout);
    plot(ax, times, inventory, 'Color', teal, 'LineWidth', 2, ...
        'Tag', 'inventory-history');
    hold(ax, 'on');
    plot(ax, times, exchange, '--', 'Color', orange, 'LineWidth', 1.1);
    xlabel(ax, 'Time (days)');
    ylabel(ax, 'Hydrogen (million surface m^3)');
    title(ax, '(a) Stored inventory and integrated exchange');
    legend(ax, {'Inventory', 'Well + boundary exchange'}, 'Location', 'southeast', 'Box', 'off');
    styleAxes(ax);

    ax = nexttile(layout);
    rates = diagnostics.wellGasSurfaceRateM3PerSecond * day / 1000;
    stairs(ax, times, [rates; rates(end)], 'Color', teal, 'LineWidth', 1.6, ...
        'Tag', 'well-gas-rate');
    yline(ax, 0, '-', 'Color', [0.6, 0.6, 0.6]);
    xlabel(ax, 'Time (days)');
    ylabel(ax, 'Gas rate (1000 surface m^3/day)');
    title(ax, '(b) Positive injection; negative withdrawal');
    styleAxes(ax);

    ax = nexttile(layout);
    bhp = nan(size(times));
    reservoir = zeros(size(times));
    cells = result.schedule.control(1).W.cells;
    for index = 1:numel(states)
        reservoir(index) = mean(states{index}.pressure(cells)) / barsa;
        if index > 1
            control = result.schedule.control(result.schedule.step.control(index - 1));
            if control.W.status
                bhp(index) = result.wellSolutions{index - 1}.bhp / barsa;
            end
        end
    end
    plot(ax, times, bhp, 'Color', teal, 'LineWidth', 1.5);
    hold(ax, 'on');
    plot(ax, times, reservoir, '--', 'Color', [0.4, 0.43, 0.48], 'LineWidth', 1.2);
    xlabel(ax, 'Time (days)');
    ylabel(ax, 'Pressure (bar)');
    title(ax, '(c) Active well and completion reference pressure');
    legend(ax, {'Well BHP (active only)', 'Mean completion brine pressure'}, ...
        'Location', 'best', 'Box', 'off');
    styleAxes(ax);

    ax = nexttile(layout);
    hold(ax, 'on');
    start = min(result.configuration.buildupDays + result.configuration.shutInDays, times(end));
    if start == times(end)
        start = 0;
    end
    selected = times >= start;
    low = min(inventory(selected));
    high = max(inventory(selected));
    padding = max(0.1, 0.15 * (high - low));
    limits = [low - padding, high + padding];
    controls = result.schedule.step.control;
    endpoints = [0; find(diff(controls) ~= 0); numel(controls)];
    for interval = 1:numel(endpoints) - 1
        first = endpoints(interval) + 1;
        last = endpoints(interval + 1);
        if controls(first) < 3
            continue
        end
        if controls(first) == 3
            color = orange;
        else
            color = teal;
        end
        patch(ax, times([first, last + 1, last + 1, first]), ...
            limits([1, 1, 2, 2]), color, 'FaceAlpha', 0.08, ...
            'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
    plot(ax, times(selected), inventory(selected), 'Color', teal, 'LineWidth', 1.8);
    xlim(ax, [start, times(end)]);
    ylim(ax, limits);
    xlabel(ax, 'Time (days)');
    ylabel(ax, 'Hydrogen (million surface m^3)');
    title(ax, '(d) Working-gas cycles: withdrawal / reinjection');
    styleAxes(ax);
    fig.UserData = struct('actualTimesDays', times, ...
        'inventorySurfaceM3', diagnostics.hydrogenSurfaceVolumeM3);
end

function name = operationName(result, index)
    names = {'Cushion injection', 'Shut-in', 'Withdrawal', 'Reinjection'};
    if index == 1
        name = 'Initial';
    else
        name = names{result.schedule.step.control(index - 1)};
    end
end

function fig = newFigure(name, dimensions)
    fig = figure('Name', name, 'Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, dimensions], 'Visible', 'off');
end

function sectionAxes(ax, xlimits, zlimits)
    view(ax, [0, 0]);
    set(ax, 'ZDir', 'reverse', 'YTick', []);
    daspect(ax, [1, 1, 0.5]);
    xlim(ax, xlimits);
    zlim(ax, zlimits);
    ticks = ceil(xlimits(1) / 500) * 500:500:floor(xlimits(2) / 500) * 500;
    set(ax, 'XTick', ticks, 'XTickLabel', compose('%g', ticks / 1000));
    xlabel(ax, 'East (km)');
    zlabel(ax, 'Depth (m)');
    styleAxes(ax);
end

function styleAxes(ax)
    set(ax, 'FontName', 'Arial', 'FontSize', 10, 'LineWidth', 0.7, ...
        'Box', 'on', 'Layer', 'top');
    grid(ax, 'on');
    ax.GridAlpha = 0.12;
end

function colors = plumeColors()
    style = h2simStoragePlotStyle();
    colors = style.saturation;
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
