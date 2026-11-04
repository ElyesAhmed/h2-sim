function files = animateHydrogenMixing2D(result, outputFolder, varargin)
    % ANIMATEHYDROGENMIXING2D Export simulation frames to GIF, MP4 and PNG.
    %
    % SYNOPSIS:
    %   files = animateHydrogenMixing2D(result, 'build/mixing')
    %   files = animateHydrogenMixing2D(result, folder, 'writeVideo', false)
    %
    % Render accepted states, including the initial condition. Colors show
    % hydrogen mole fraction on a fixed [0,1] scale. Depth increases downward.
    % Playback uses equal frame durations; simulated output times are uneven
    % and labelled on every frame. Files are overwritten in outputFolder.
    % MP4 export requires VideoWriter MPEG-4 support; use writeVideo=false
    % on platforms without that profile. GIF export uses MATLAB imwrite.
    % No simulation, interpolation of states or chemistry is performed here.
    parser = inputParser();
    parser.PartialMatching = false;
    addParameter(parser, 'writeVideo', true, @(x) islogical(x) && isscalar(x));
    addParameter(parser, 'frameRate', 8, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
    parse(parser, varargin{:});
    opt = parser.Results;
    diagnostics = checkHydrogenMixing2D(result);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    files = struct('gif', fullfile(outputFolder, 'hydrogen_mixing.gif'), ...
        'poster', fullfile(outputFolder, 'hydrogen_mixing.png'), ...
        'video', '');
    figureHandle = figure('Visible', 'off', 'Color', [0.025, 0.055, 0.1], ...
        'Position', [80, 80, 1000, 650], 'Name', 'H2sim hydrogen mixing');
    cleanupFigure = onCleanup(@() close(figureHandle));
    ax = axes(figureHandle, 'Position', [0.1, 0.21, 0.68, 0.62], ...
        'Color', [0.025, 0.055, 0.1], 'XColor', 'w', 'YColor', 'w', ...
        'FontSize', 12);
    dimensions = result.parameters.gridSize;
    x = linspace(50 / dimensions(1), 100 - 50 / dimensions(1), dimensions(1));
    z = linspace(400 + 50 / dimensions(2), ...
        500 - 50 / dimensions(2), dimensions(2));
    imageHandle = imagesc(ax, x, z, zeros(fliplr(dimensions)), [0, 1]);
    axis(ax, 'image');
    xlim(ax, [0, 100]);
    ylim(ax, [400, 500]);
    set(ax, 'YDir', 'reverse', 'Box', 'off', 'XColor', 'w', ...
        'YColor', 'w', 'TickDir', 'out', 'Layer', 'top');
    xlabel(ax, 'Horizontal distance (m)', 'Color', 'w');
    ylabel(ax, 'Depth (m)', 'Color', 'w');
    colormap(ax, mixingColors());
    colorbarHandle = colorbar(ax);
    colorbarHandle.Color = 'w';
    colorbarHandle.Label.String = 'Hydrogen mole fraction';
    colorbarHandle.Label.Color = 'w';
    annotation(figureHandle, 'textbox', [0.08, 0.9, 0.85, 0.07], ...
        'String', 'H2sim | Hydrogen meets methane', 'Color', 'w', ...
        'FontSize', 23, 'FontWeight', 'bold', 'EdgeColor', 'none');
    timeLabel = annotation(figureHandle, 'textbox', [0.1, 0.82, 0.8, 0.05], ...
        'String', '', 'Color', [0.7, 0.85, 0.95], ...
        'FontSize', 13, 'EdgeColor', 'none');
    annotation(figureHandle, 'textbox', [0.08, 0.04, 0.9, 0.1], ...
        'String', {'Closed reservoir | Gravity + binary molecular diffusion', ...
        'Adapted from Okoroafor et al. (2023), Problem 2 | Uneven simulated time intervals'}, ...
        'Color', [0.7, 0.77, 0.84], 'FontSize', 11, 'EdgeColor', 'none');
    writer = [];
    if opt.writeVideo
        files.video = fullfile(outputFolder, 'hydrogen_mixing.mp4');
        writer = VideoWriter(files.video, 'MPEG-4');
        writer.FrameRate = opt.frameRate;
        writer.Quality = 95;
        open(writer);
    end
    cleanupVideo = onCleanup(@() closeVideo(writer));
    states = [{result.state0}; result.states(:)];
    times = [0; cumsum(result.schedule.step.val)] / day;
    [~, posterIndex] = min(diagnostics.hydrogenMeanDepthM);
    for frameIndex = 1:numel(states)
        field = reshape(states{frameIndex}.components(:, 1), dimensions).';
        set(imageHandle, 'CData', field);
        timeLabel.String = sprintf('Day %7.2f | %d x %d cells | 50 deg C', ...
            times(frameIndex), dimensions(1), dimensions(2));
        drawnow;
        frame = getframe(figureHandle);
        rgb = frame.cdata;
        % Keep the README preview smaller than the full-resolution video.
        columns = round(linspace(1, size(rgb, 2), 800));
        height = round(800 * size(rgb, 1) / size(rgb, 2));
        rows = round(linspace(1, size(rgb, 1), height));
        gifRgb = rgb(rows, columns, :);
        if frameIndex == 1
            [indexed, map] = rgb2ind(gifRgb, 128, 'nodither');
        else
            indexed = rgb2ind(gifRgb, map, 'nodither');
        end
        delay = 1 / opt.frameRate;
        if frameIndex == 1
            imwrite(indexed, map, files.gif, 'gif', 'LoopCount', Inf, ...
                'DelayTime', delay);
        else
            imwrite(indexed, map, files.gif, 'gif', 'WriteMode', 'append', ...
                'DelayTime', delay);
        end
        if frameIndex == posterIndex
            imwrite(rgb, files.poster);
        end
        if ~isempty(writer)
            writeVideo(writer, frame);
        end
    end
end

function colors = mixingColors()
    anchors = [0.12, 0.22, 0.48; 0.1, 0.5, 0.7; ...
        0.1, 0.75, 0.65; 0.75, 0.9, 0.4; 1, 0.8, 0.25];
    colors = interp1(linspace(0, 1, size(anchors, 1)), anchors, ...
        linspace(0, 1, 256));
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
