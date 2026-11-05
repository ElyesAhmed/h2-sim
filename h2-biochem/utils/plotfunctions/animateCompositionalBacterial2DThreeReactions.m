function files = animateCompositionalBacterial2DThreeReactions(result, outputFolder, varargin)
    % ANIMATECOMPOSITIONALBACTERIAL2DTHREEREACTIONS Animate a saved microbial case.
    %
    % SYNOPSIS:
    %   files = animateCompositionalBacterial2DThreeReactions(results(1), folder)
    %   files = animateCompositionalBacterial2DThreeReactions(result, folder, ...
    %       'writeVideo', false)
    %
    % Exports biochemistry_storage.gif, .mp4 and a build-up .png poster.
    % Defaults: frameRate=6, maxFrames=100, writeVideo=true. Existing files
    % are overwritten. MP4 requires the MPEG-4 VideoWriter profile. GIF/PNG
    % remain available with writeVideo=false. No simulation is run.
    %
    % Maps show gas H2 mole fraction (hidden below gas saturation 0.001) and
    % MET/ACE/SRB nbact in model units. Limits are fixed over the entire saved
    % history and shared with the static figures. The timeline shows consumed
    % H2 divided by cumulative injected H2, not retained inventory or loss by
    % dissolution. Equal-duration frames select initial/accepted states by
    % physical time, preserving stage endpoints without temporal interpolation.
    % sourceStateIndices index [{result.state0}; result.states(:)].
    parser = inputParser();
    parser.PartialMatching = false;
    addParameter(parser, 'writeVideo', true, @(x) islogical(x) && isscalar(x));
    addParameter(parser, 'frameRate', 6, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
    addParameter(parser, 'maxFrames', 100, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 2 && x == fix(x));
    parse(parser, varargin{:});
    opt = parser.Results;
    data = biochemistryStoragePresentationData(result);
    mandatory = unique([1; data.endpoints]);
    assert(numel(mandatory) <= opt.maxFrames, 'H2sim:BiochemistryAnimationFrames', ...
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
    files = struct('gif', fullfile(outputFolder, 'biochemistry_storage.gif'), ...
        'poster', fullfile(outputFolder, 'biochemistry_storage.png'), 'video', '', ...
        'sourceStateIndices', indices);
    style = h2simStoragePlotStyle();
    fig = figure('Visible', 'off', 'Color', style.background, ...
        'Position', [40, 40, 1280, 740]);
    cleanupFigure = onCleanup(@() close(fig));
    G = result.model.G;
    assert(result.model.bacteriamodel, 'H2sim:BiochemistryAnimationCase', ...
        'Select a microbial case with MET, ACE and SRB populations.');
    states = [{result.state0}; result.states(:)];
    positions = [0.055, 0.52, 0.23, 0.28; 0.34, 0.52, 0.23, 0.28; ...
        0.055, 0.17, 0.23, 0.28; 0.34, 0.17, 0.23, 0.28];
    titles = {'Hydrogen in the gas phase', 'Methanogenesis (MET)', ...
        'Acetogenesis (ACE)', 'Sulfate reduction (SRB)'};
    patches = gobjects(4, 1);
    wells = gobjects(4, 1);
    for panel = 1:4
        ax = axes(fig, 'Position', positions(panel, :));
        patches(panel) = plotCellData(G, zeros(G.cells.num, 1), ...
            'Parent', ax, 'EdgeColor', 'none');
        hold(ax, 'on');
        wc = result.schedule.control(1).W.cells;
        wells(panel) = plot(ax, G.cells.centroids(wc, 1), G.cells.centroids(wc, 2), ...
            'wo', 'MarkerFaceColor', style.injection, 'MarkerSize', 3);
        view(ax, 2);
        axis(ax, 'equal');
        axis(ax, [0, 50, 0, 50]);
        xlabel(ax, 'Horizontal distance (m)');
        ylabel(ax, 'Elevation (m)');
        title(ax, titles{panel}, 'FontSize', 10);
        colormap(ax, style.saturation);
        limits = [0, 1];
        unit = 'Gas H_2 mole fraction (-)';
        if panel > 1
            limits = data.biomassLimits(panel - 1, :);
            unit = 'nbact (model units)';
        end
        % caxis supports MATLAB R2021a.
        caxis(ax, limits);
        cb = colorbar(ax, 'Location', 'eastoutside');
        cb.Color = 'w';
        cb.Label.String = unit;
        cb.FontSize = 8;
        h2simStoragePlotStyle(ax);
        ax.FontSize = 8;
    end
    inventoryAxes = axes(fig, 'Position', [0.65, 0.52, 0.3, 0.25]);
    hold(inventoryAxes, 'on');
    reactionColors = [style.injection; style.withdrawal; 0.65, 0.6, 0.95];
    histories = gobjects(4, 1);
    for reaction = 1:3
        histories(reaction) = plot(inventoryAxes, 0, data.percent(1, reaction), ...
            'Color', reactionColors(reaction, :), 'LineWidth', 1.5);
    end
    histories(4) = plot(inventoryAxes, 0, sum(data.percent(1, :)), ...
        'Color', 'w', 'LineStyle', '--', 'LineWidth', 1.5);
    xlim(inventoryAxes, [0, data.times(end)]);
    ylim(inventoryAxes, [0, max(1, 1.1 * max(sum(data.percent, 2)))]);
    xlabel(inventoryAxes, 'Simulated time (days)');
    ylabel(inventoryAxes, 'Consumed / injected H_2 (%)');
    title(inventoryAxes, 'Cumulative microbial consumption');
    lg = legend(inventoryAxes, 'MET', 'ACE', 'SRB', 'Total', 'Location', 'northwest');
    set(lg, 'TextColor', 'w', 'Color', style.background, 'EdgeColor', 'none');
    h2simStoragePlotStyle(inventoryAxes);
    rateAxes = axes(fig, 'Position', [0.65, 0.22, 0.3, 0.17]);
    stairs(rateAxes, data.times, [data.massRate(:, 1); data.massRate(end, 1)], ...
        'Color', style.injection, 'LineWidth', 1.3);
    hold(rateAxes, 'on');
    cursor = xline(rateAxes, 0, '-', 'Color', style.withdrawal, 'LineWidth', 2);
    xlim(rateAxes, [0, data.times(end)]);
    xlabel(rateAxes, 'Simulated time (days)');
    ylabel(rateAxes, 'H_2 well rate (kg/day)');
    h2simStoragePlotStyle(rateAxes);
    annotation(fig, 'textbox', [0.04, 0.91, 0.92, 0.07], ...
        'String', 'H2sim | Hydrogen storage with microbial reactions', 'Color', 'w', ...
        'FontSize', 22, 'FontWeight', 'bold', 'EdgeColor', 'none');
    label = annotation(fig, 'textbox', [0.04, 0.84, 0.92, 0.05], ...
        'String', '', 'Color', style.text, 'FontSize', 13, 'EdgeColor', 'none');
    annotation(fig, 'textbox', [0.04, 0.035, 0.92, 0.08], ...
        'String', {'50 m structural trap | Residual methane | MET, ACE and SRB | No PHREEQC', ...
        'Initial and accepted simulation states | Uneven simulated time intervals', ...
        'H2 hidden where gas saturation < 0.001 | nbact in model units | No vertical exaggeration'}, ...
        'Color', [0.7, 0.77, 0.84], 'FontSize', 10, 'EdgeColor', 'none');
    writer = [];
    if opt.writeVideo
        files.video = fullfile(outputFolder, 'biochemistry_storage.mp4');
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
        for panel = 1:4
            set(patches(panel), 'FaceVertexCData', fieldValues(states{index}, panel));
        end
        for reaction = 1:3
            set(histories(reaction), 'XData', data.times(1:index), ...
                'YData', data.percent(1:index, reaction));
        end
        set(histories(4), 'XData', data.times(1:index), ...
            'YData', sum(data.percent(1:index, :), 2));
        cursor.Value = data.times(index);
        stage = 'Initial residual methane';
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
        set(wells, 'MarkerFaceColor', color);
        label.String = sprintf('Day %6.1f | %s | %d cells | %.1f%% of injected H2 consumed', ...
            data.times(index), stage, G.cells.num, sum(data.percent(index, :)));
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

function values = fieldValues(state, panel)
    if panel == 1
        values = state.y(:, 2);
        values(state.s(:, 2) < 0.001) = nan;
    else
        values = state.nbact(:, panel - 1);
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
