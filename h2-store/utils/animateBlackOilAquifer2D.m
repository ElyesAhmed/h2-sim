function files = animateBlackOilAquifer2D(result, outputFolder, varargin)
    % ANIMATEBLACKOILAQUIFER2D Animate saved saline-aquifer storage states.
    %
    % SYNOPSIS:
    %   files = animateBlackOilAquifer2D(result, 'build/aquifer')
    %   files = animateBlackOilAquifer2D(result, folder, 'writeVideo', false)
    %
    % Exports aquifer_storage.gif, .mp4 and a build-up poster .png. Overwrites
    % existing outputs. MP4 needs the MPEG-4 VideoWriter profile; GIF and PNG
    % can be written independently. Defaults: frameRate=6, maxFrames=100.
    % Frames select actual initial/accepted states by physical time, retain
    % stage endpoints and use equal playback durations. No interpolation.
    % Returned sourceStateIndices index [{result.state0}; result.states(:)].
    parser = inputParser();
    parser.PartialMatching = false;
    addParameter(parser, 'writeVideo', true, @(x) islogical(x) && isscalar(x));
    addParameter(parser, 'frameRate', 6, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
    addParameter(parser, 'maxFrames', 100, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 2 && x == fix(x));
    parse(parser, varargin{:});
    opt = parser.Results;
    data = aquiferPresentationData(result);
    mandatory = unique([1; data.endpoints]);
    assert(numel(mandatory) <= opt.maxFrames, 'H2sim:AquiferAnimationFrames', ...
        'maxFrames must accommodate all operating-stage endpoints.');
    targets = linspace(0, data.times(end), opt.maxFrames - numel(mandatory));
    sampled = zeros(numel(targets), 1);
    for k = 1:numel(targets)
        [~, sampled(k)] = min(abs(data.times - targets(k)));
    end
    indices = unique([mandatory; sampled]);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    files = struct('gif', fullfile(outputFolder, 'aquifer_storage.gif'), ...
        'poster', fullfile(outputFolder, 'aquifer_storage.png'), 'video', '', ...
        'sourceStateIndices', indices);
    style = h2simStoragePlotStyle();
    fig = figure('Visible', 'off', 'Color', style.background, ...
        'Position', [40, 40, 1280, 740]);
    cleanupFigure = onCleanup(@() close(fig));
    ax = axes(fig, 'Position', [0.07, 0.23, 0.47, 0.58]);
    G = result.model.G;
    states = [{result.state0}; result.states(:)];
    patch = plotCellData(G, states{1}.s(:, 2), 'Parent', ax, 'EdgeColor', 'none');
    hold(ax, 'on');
    x = linspace(0, 50, 100);
    plot(ax, x, 25.1 + 5 * sin(pi * x / 50), 'Color', [0.7, 0.77, 0.84]);
    plot(ax, [0, 50], [5, 5], 'Color', [0.7, 0.77, 0.84]);
    wc = result.schedule.control(1).W.cells;
    well = plot(ax, G.cells.centroids(wc, 1), G.cells.centroids(wc, 2), ...
        'wo', 'MarkerFaceColor', style.injection, 'MarkerSize', 5);
    view(ax, 2);
    axis(ax, 'equal');
    axis(ax, [0, 50, 0, 50]);
    xlabel(ax, 'Horizontal distance (m)');
    ylabel(ax, 'Elevation (m)');
    title(ax, 'Hydrogen gas saturation | structural trap');
    colormap(ax, style.saturation);
    % caxis supports MATLAB R2021a.
    caxis(ax, [0, data.saturationMaximum]);
    cb = colorbar(ax, 'Location', 'southoutside');
    cb.Color = 'w';
    cb.Label.String = 'Gas saturation (-)';
    h2simStoragePlotStyle(ax);
    inventoryAxes = axes(fig, 'Position', [0.65, 0.52, 0.3, 0.25]);
    hold(inventoryAxes, 'on');
    total = plot(inventoryAxes, 0, data.total(1), 'Color', style.injection, 'LineWidth', 2);
    dissolved = plot(inventoryAxes, 0, data.dissolved(1), ...
        'Color', style.withdrawal, 'LineWidth', 2);
    xlim(inventoryAxes, [0, data.times(end)]);
    ylim(inventoryAxes, [0, max(1, 1.1 * max(data.total))]);
    xlabel(inventoryAxes, 'Simulated time (days)');
    ylabel(inventoryAxes, 'Retained H_2 (surface m^3)');
    title(inventoryAxes, 'Hydrogen inventory');
    lg = legend(inventoryAxes, 'Total', 'Dissolved', 'Location', 'northwest');
    set(lg, 'TextColor', 'w', 'Color', style.background, 'EdgeColor', 'none');
    h2simStoragePlotStyle(inventoryAxes);
    rateAxes = axes(fig, 'Position', [0.65, 0.22, 0.3, 0.17]);
    stairs(rateAxes, data.times, [data.rate; data.rate(end)], ...
        'Color', style.injection, 'LineWidth', 1.3);
    hold(rateAxes, 'on');
    cursor = xline(rateAxes, 0, '-', 'Color', style.withdrawal, 'LineWidth', 2);
    xlim(rateAxes, [0, data.times(end)]);
    xlabel(rateAxes, 'Simulated time (days)');
    ylabel(rateAxes, 'Gas rate (surface m^3/day)');
    h2simStoragePlotStyle(rateAxes);
    annotation(fig, 'textbox', [0.04, 0.91, 0.92, 0.07], ...
        'String', 'H2sim | Hydrogen storage in a saline aquifer', 'Color', 'w', ...
        'FontSize', 22, 'FontWeight', 'bold', 'EdgeColor', 'none');
    label = annotation(fig, 'textbox', [0.04, 0.84, 0.92, 0.05], ...
        'String', '', 'Color', style.text, 'FontSize', 13, 'EdgeColor', 'none');
    annotation(fig, 'textbox', [0.04, 0.035, 0.92, 0.08], ...
        'String', {'50 m structural trap | Dissolution and capillarity | Zero added salt', ...
        'Initial and accepted simulation states | Uneven simulated time intervals', ...
        'Positive rate: injection | Negative rate: withdrawal | No vertical exaggeration'}, ...
        'Color', [0.7, 0.77, 0.84], 'FontSize', 10, 'EdgeColor', 'none');
    writer = [];
    if opt.writeVideo
        files.video = fullfile(outputFolder, 'aquifer_storage.mp4');
        writer = VideoWriter(files.video, 'MPEG-4');
        writer.FrameRate = opt.frameRate;
        writer.Quality = 95;
        open(writer);
    end
    cleanupVideo = onCleanup(@() closeVideo(writer));
    ends = getCyclesLastSteps(result.schedule);
    poster = ends.cushion(1) + 1;
    map = [];
    for k = 1:numel(indices)
        index = indices(k);
        set(patch, 'FaceVertexCData', states{index}.s(:, 2));
        set(total, 'XData', data.times(1:index), 'YData', data.total(1:index));
        set(dissolved, 'XData', data.times(1:index), 'YData', data.dissolved(1:index));
        cursor.Value = data.times(index);
        stage = 'Initially brine-saturated';
        color = [0.65, 0.7, 0.75];
        if index > 1
            stage = data.stages{index - 1};
            if strcmp(stage, 'discharge')
                color = style.withdrawal;
                stage = 'Withdrawal';
            elseif any(strcmp(stage, {'charge', 'cushion'}))
                color = style.injection;
                stage = 'Injection';
            else
                stage = 'Shut-in';
            end
        end
        set(well, 'MarkerFaceColor', color);
        label.String = sprintf('Day %6.1f | %s | %d cells | %.1f%% dissolved', ...
            data.times(index), stage, G.cells.num, data.fraction(index));
        drawnow;
        frame = getframe(fig);
        rgb = frame.cdata;
        rgb = rgb(1:2 * floor(size(rgb, 1) / 2), 1:2 * floor(size(rgb, 2) / 2), :);
        rows = round(linspace(1, size(rgb, 1), round(800 * size(rgb, 1) / size(rgb, 2))));
        columns = round(linspace(1, size(rgb, 2), 800));
        preview = rgb(rows, columns, :);
        if k == 1
            [indexed, map] = rgb2ind(preview, 128, 'nodither');
            imwrite(indexed, map, files.gif, 'gif', 'LoopCount', Inf, 'DelayTime', 1 / opt.frameRate);
        else
            indexed = rgb2ind(preview, map, 'nodither');
            imwrite(indexed, map, files.gif, 'gif', 'WriteMode', 'append', 'DelayTime', 1 / opt.frameRate);
        end
        if index == poster
            imwrite(rgb, files.poster);
        end
        if ~isempty(writer)
            writeVideo(writer, rgb);
        end
    end
end

function closeVideo(writer)
    if ~isempty(writer)
        close(writer);
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
