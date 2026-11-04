function files = animateHydrogenAnticline(result, outputFolder, varargin)
    % ANIMATEHYDROGENANTICLINE Export reservoir cycling to GIF, MP4 and PNG.
    %
    % SYNOPSIS:
    %   files = animateHydrogenAnticline(result, 'build/anticline')
    %   files = animateHydrogenAnticline(result, folder, 'writeVideo', false)
    %
    % The surface shows pore-volume-weighted column gas saturation draped on
    % the storage top. The centre section shows actual cell gas saturations.
    % Initial and accepted states are rendered without temporal interpolation.
    % At most maxFrames (default 90) are selected by physical time, retaining
    % every operating-stage endpoint. Files return the selected state indices.
    % Frames have equal playback duration and labelled, uneven simulation times.
    % Output files are overwritten. MP4 requires MATLAB MPEG-4 VideoWriter;
    % GIF and PNG export remain available with writeVideo=false.
    parser = inputParser();
    parser.PartialMatching = false;
    addParameter(parser, 'writeVideo', true, @(x) islogical(x) && isscalar(x));
    addParameter(parser, 'frameRate', 8, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
    addParameter(parser, 'maxFrames', 90, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 2 && x == fix(x));
    parse(parser, varargin{:});
    opt = parser.Results;
    diagnostics = checkHydrogenAnticline(result);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    files = struct('gif', fullfile(outputFolder, 'hydrogen_anticline.gif'), ...
        'poster', fullfile(outputFolder, 'hydrogen_anticline.png'), 'video', '');
    fig = figure('Visible', 'off', 'Color', [0.025, 0.055, 0.1], ...
        'Position', [40, 40, 1280, 740], 'Name', 'H2sim anticlinal storage');
    cleanupFigure = onCleanup(@() close(fig));
    G = result.model.G;
    dimensions = G.cartDims;
    region = result.model.rock.regions.saturation;
    [~, j, ~] = ind2sub(dimensions, G.cells.indexMap);
    section = j == (dimensions(2) + 1) / 2;
    files.sectionCellIndices = find(section);
    storage = region == 3;
    [surfaceX, surfaceY, surfaceZ] = storageSurface(G);
    ax3 = axes(fig, 'Position', [0.08, 0.23, 0.47, 0.58]);
    surface = surf(ax3, surfaceX / 1000, surfaceY / 1000, surfaceZ, ...
        zeros(size(surfaceX)), 'EdgeColor', 'none', 'FaceColor', 'flat');
    hold(ax3, 'on');
    well = plot3(ax3, [2.5, 2.5], [2.5, 2.5], [250, 415], ...
        'Color', [0.4, 0.9, 0.9], 'LineWidth', 3);
    view(ax3, [-35, 28]);
    daspect(ax3, [1, 1, 200]);
    set(ax3, 'ZDir', 'reverse');
    zlim(ax3, [250, 780]);
    xlim(ax3, [0, 5]);
    ylim(ax3, [0, 5]);
    xlabel(ax3, 'East (km)');
    ylabel(ax3, 'North (km)');
    zlabel(ax3, 'Depth (m)');
    title(ax3, 'Column mean gas saturation on the storage top');
    % caxis keeps this renderer compatible with MATLAB R2021a.
    caxis(ax3, [0, 0.8]);
    colormap(ax3, storageColors());
    color = colorbar(ax3, 'Location', 'southoutside');
    color.Color = 'w';
    color.Label.String = 'Gas saturation (column pore-volume mean)';
    color.Label.Color = 'w';
    styleAxes(ax3);

    ax2 = axes(fig, 'Position', [0.66, 0.47, 0.3, 0.32]);
    hold(ax2, 'on');
    layerColors = [0.2, 0.32, 0.42; 0.38, 0.4, 0.43; ...
        0.25, 0.38, 0.47; 0.3, 0.31, 0.34];
    for layer = 1:4
        plotGrid(G, section & region == layer, 'Parent', ax2, ...
            'FaceColor', layerColors(layer, :), 'EdgeColor', 'none');
    end
    plot3(ax2, [2500, 2500], [2500, 2500], [260, 425], ...
        'Color', 'w', 'LineWidth', 2);
    view(ax2, [0, 0]);
    daspect(ax2, [1, 1, 0.5]);
    set(ax2, 'ZDir', 'reverse');
    xlim(ax2, [1400, 3600]);
    zlim(ax2, [300, 780]);
    xlabel(ax2, 'East (m)');
    zlabel(ax2, 'Depth (m)');
    title(ax2, 'Central section: cell gas saturation');
    caxis(ax2, [0, 0.8]);
    colormap(ax2, storageColors());
    styleAxes(ax2);
    gasPatch = [];

    axHistory = axes(fig, 'Position', [0.66, 0.2, 0.3, 0.16]);
    times = [0; cumsum(result.schedule.step.val)] / day;
    inventory = diagnostics.hydrogenSurfaceVolumeM3 / 1e6;
    history = plot(axHistory, 0, 0, 'Color', [0.4, 0.9, 0.9], 'LineWidth', 2);
    xlim(axHistory, [0, times(end)]);
    ylim(axHistory, [0, max(1, 1.1 * max(inventory))]);
    xlabel(axHistory, 'Simulated time (days)');
    ylabel(axHistory, 'Stored H_2 (million sm^3)');
    styleAxes(axHistory);
    annotation(fig, 'textbox', [0.04, 0.91, 0.92, 0.07], ...
        'String', 'H2sim | Hydrogen storage beneath an anticline', ...
        'Color', 'w', 'FontSize', 22, 'FontWeight', 'bold', 'EdgeColor', 'none');
    label = annotation(fig, 'textbox', [0.04, 0.84, 0.92, 0.05], ...
        'String', '', 'Color', [0.7, 0.85, 0.95], 'FontSize', 13, ...
        'EdgeColor', 'none');
    annotation(fig, 'textbox', [0.04, 0.035, 0.92, 0.08], ...
        'String', {'Four-layer Gaussian reservoir | 50 deg C | No dissolution or reactions', ...
        'Coarse adaptation: Okoroafor et al. (2023), Problem 4 | Uneven simulated time intervals', ...
        'Vertical exaggeration: 5x on the surface, 2x in the section'}, ...
        'Color', [0.7, 0.77, 0.84], 'FontSize', 10, 'EdgeColor', 'none');
    writer = [];
    if opt.writeVideo
        files.video = fullfile(outputFolder, 'hydrogen_anticline.mp4');
        writer = VideoWriter(files.video, 'MPEG-4');
        writer.FrameRate = opt.frameRate;
        writer.Quality = 95;
        open(writer);
    end
    cleanupVideo = onCleanup(@() closeVideo(writer));
    states = [{result.state0}; result.states(:)];
    posterIndex = find(result.schedule.step.control == 1, 1, 'last') + 1;
    indices = selectFrames(result.schedule.step.control, times, opt.maxFrames);
    files.sourceStateIndices = indices;
    map = [];
    for frameIndex = 1:numel(indices)
        index = indices(frameIndex);
        state = states{index};
        saturation = state.s(:, result.model.getPhaseIndex('G'));
        columnMean = columnSaturation(result.model, state, storage);
        set(surface, 'CData', padColumnData(columnMean));
        if ~isempty(gasPatch)
            delete(gasPatch);
        end
        visible = section & saturation > 0.005;
        if any(visible)
            gasPatch = plotCellData(G, saturation, visible, 'Parent', ax2, ...
                'EdgeColor', 'none');
        else
            gasPatch = [];
        end
        set(history, 'XData', times(1:index), 'YData', inventory(1:index));
        [stage, stageColor] = operation(result, index);
        set(well, 'Color', stageColor);
        label.String = sprintf('Day %6.1f | %s | %d cells | %.2f million sm^3 H2', ...
            times(index), stage, G.cells.num, inventory(index));
        styleAxes(ax2);
        caxis(ax2, [0, 0.8]);
        drawnow;
        frame = getframe(fig);
        rgb = frame.cdata;
        rgb = rgb(1:2 * floor(size(rgb, 1) / 2), ...
            1:2 * floor(size(rgb, 2) / 2), :);
        map = appendGif(rgb, files.gif, frameIndex, opt.frameRate, map);
        if index == posterIndex
            imwrite(rgb, files.poster);
        end
        if ~isempty(writer)
            writeVideo(writer, rgb);
        end
    end
end

function indices = selectFrames(controls, times, maximum)
    if numel(times) <= maximum
        indices = (1:numel(times)).';
        return
    end
    endpoints = find([diff(controls(:)) ~= 0; true]) + 1;
    mandatory = unique([1; endpoints]);
    assert(numel(mandatory) <= maximum, 'H2sim:AnticlineAnimationFrames', ...
        'maxFrames must accommodate every operating-stage endpoint.');
    targets = linspace(times(1), times(end), maximum - numel(mandatory));
    sampled = zeros(numel(targets), 1);
    for target = 1:numel(targets)
        [~, sampled(target)] = min(abs(times - targets(target)));
    end
    indices = unique([mandatory; sampled]);
end

function [X, Y, Z] = storageSurface(G)
    sizeNodes = G.cartDims + 1;
    X = reshape(G.nodes.coords(:, 1), sizeNodes);
    Y = reshape(G.nodes.coords(:, 2), sizeNodes);
    Z = reshape(G.nodes.coords(:, 3), sizeNodes);
    X = X(:, :, 4);
    Y = Y(:, :, 4);
    Z = Z(:, :, 4);
end

function saturation = columnSaturation(model, state, storage)
    dimensions = model.G.cartDims;
    pv = value(model.getProp(state, 'PoreVolume'));
    weight = reshape(pv .* storage, dimensions);
    gas = reshape(state.s(:, model.getPhaseIndex('G')), dimensions);
    saturation = sum(gas .* weight, 3) ./ sum(weight, 3);
end

function padded = padColumnData(data)
    padded = data([1:end, end], [1:end, end]);
end

function [name, color] = operation(result, frame)
    names = {'Cushion injection', 'Shut-in', 'Hydrogen withdrawal', 'Reinjection'};
    colors = [0.4, 0.9, 0.9; 0.65, 0.7, 0.75; 1, 0.65, 0.25; 0.4, 0.9, 0.9];
    if frame == 1
        name = 'Initially brine-saturated';
        color = colors(2, :);
    else
        control = result.schedule.step.control(frame - 1);
        name = names{control};
        color = colors(control, :);
    end
end

function map = appendGif(rgb, file, frame, rate, map)
    columns = round(linspace(1, size(rgb, 2), 800));
    rows = round(linspace(1, size(rgb, 1), ...
        round(800 * size(rgb, 1) / size(rgb, 2))));
    preview = rgb(rows, columns, :);
    if frame == 1
        [indexed, map] = rgb2ind(preview, 128, 'nodither');
        imwrite(indexed, map, file, 'gif', 'LoopCount', Inf, 'DelayTime', 1 / rate);
    else
        indexed = rgb2ind(preview, map, 'nodither');
        imwrite(indexed, map, file, 'gif', 'WriteMode', 'append', 'DelayTime', 1 / rate);
    end
end

function colors = storageColors()
    anchors = [0.12, 0.22, 0.35; 0.08, 0.48, 0.65; ...
        0.15, 0.75, 0.62; 0.85, 0.88, 0.3; 1, 0.65, 0.18];
    colors = interp1(linspace(0, 1, size(anchors, 1)), anchors, linspace(0, 1, 256));
end

function styleAxes(ax)
    set(ax, 'Color', [0.025, 0.055, 0.1], 'XColor', 'w', 'YColor', 'w', ...
        'ZColor', 'w', 'FontSize', 10, 'Box', 'off');
    ax.Title.Color = 'w';
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
