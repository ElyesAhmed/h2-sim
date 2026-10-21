function figures = plotPhreeqcMineralComparison(comparison, varargin)
%Plot saved mineral-case hydrogen consumption and final aqueous pH
%
% SYNOPSIS:
%   figures = plotPhreeqcMineralComparison(comparison);
%   figures = plotPhreeqcMineralComparison(comparison, ...
%       'dimension', 2, 'outputDirectory', '');
%
% PARAMETERS:
%   comparison - Result struct array from the mineral-comparison examples.
%                The first entry is the baseline; subsequent entries are
%                PHREEQC mineral cases. Required fields: name, rock,
%                h2ConsumedByReactionMoles, finalPH, timeDays and h2LossPercent.
%                Reaction columns are MET, ACE and SRB, in mol H2. finalPH
%                contains cellwise pH, or [] when unavailable. timeDays is
%                in days. h2LossPercent uses cumulative injected H2 to date.
%                Optional spatialH2LossPercent and xDimensionless supply
%                per-cell contributions normalized by total injected H2,
%                and dimensionless distance x/L, respectively.
%
% OPTIONAL PARAMETERS:
%   dimension       - Dimension label for titles and filenames (default 1).
%                     This does not change the data or perform a grid mapping.
%   outputDirectory - PDF/PNG folder (default build/phreeqc-figures under pwd).
%                     Pass an empty character vector, '', to disable export.
%
% RETURNS:
%   figures - Two open figure handles owned by the caller:
%               1. Reaction-specific H2 consumption bars and final-pH boxes.
%               2. H2 loss over time and, when supplied, spatial contributions.
%
% DESCRIPTION:
%   Redraw existing results without running simulations. Baseline kinetics
%   and PHREEQC cases occupy separate bar panels; unavailable pH is omitted.
%   The second figure shows all cases beside PHREEQC-only detail. Spatial
%   curves are sorted by x/L and appear only when spatialH2LossPercent exists.
%   Labels, values and normalization are taken from the supplied metrics.
%   The final time in the first case is used in titles and time-axis limits.
%
%   Exports are vector PDF and 300-dpi PNG. Base names are
%   minerals_<dimension>D_consumption_pH and
%   minerals_<dimension>D_H2_consumption.
%
% SEE ALSO:
%   exampleCompositionalBacterial1DPhreeqcMinerals,
%   exampleCompositionalBacterial2DPhreeqcMinerals, paperExport

    opt = merge_options(struct('dimension', 1, 'outputDirectory', ...
        fullfile(pwd, 'build', 'phreeqc-figures')), varargin{:});
    colors = paperColors(numel(comparison));
    styles = {'-', '--', ':', '-.'};
    labels = makeLabels(comparison);
    h2 = vertcat(comparison.h2ConsumedByReactionMoles);

    %% Compare reaction-specific consumption and final cellwise pH
    figures = gobjects(2, 1);
    [figures(1), lastTime] = plotConsumptionAndPH(comparison, labels, colors, h2, opt);
    exportFigure(figures(1), 'consumption_pH', opt);

    %% Compare time histories and optional spatial contributions
    figures(2) = plotHydrogenLoss(comparison, labels, colors, styles, lastTime, opt);
    exportFigure(figures(2), 'H2_consumption', opt);
end

function labels = makeLabels(comparison)
    names = vertcat(comparison.name);
    labels = names;
    for k = 2:numel(comparison)
        labels(k) = names(k) + ": " + erase(string(comparison(k).rock), " sandstone");
    end
end

function [fig, lastTime] = plotConsumptionAndPH(comparison, labels, colors, h2, opt)
    fig = paperFigure([32, 14], sprintf('%dD mineral comparison', opt.dimension));
    layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    reactionColors = paperColors(4);
    reactionColors = reactionColors(2:4, :);
    for panel = 1:2
        ax = nexttile(layout);
        if panel == 1
            indices = 1;
        else
            indices = 2:numel(comparison);
        end
        category = categorical(labels(indices), labels(indices), 'Ordinal', true);
        bars = bar(ax, category, h2(indices, :), 'stacked', 'BarWidth', 0.65);
        for k = 1:numel(bars)
            bars(k).FaceColor = reactionColors(k, :);
        end
        xlabel(ax, 'Model / mineral case');
        ylabel(ax, 'H_2 consumed (mol)');
        if panel == 1
            title(ax, '(a) Original kinetics');
        else
            title(ax, '(b) PHREEQC kinetics');
        end
        totals = sum(h2(indices, :), 2);
        upper = max(totals)*1.18 + eps;
        ylim(ax, [0, upper]);
        styleAxes(ax, 11);
        ax.XTickLabelRotation = 20;
        text(ax, category, totals + 0.035*upper, ...
            cellstr(compose('%.3g', totals)), 'HorizontalAlignment', 'center', ...
            'FontName', 'Times New Roman', 'FontSize', 10);
        if panel == 1
            lg = legend(ax, bars, {'Methanogenesis (MET)', 'Acetogenesis (ACE)', ...
                'Sulfate reduction (SRB)'}, 'Orientation', 'horizontal');
            lg.Layout.Tile = 'south';
            lg.FontSize = 11;
            lg.Box = 'off';
        end
    end

    ax = nexttile(layout);
    hold(ax, 'on');
    pHMask = arrayfun(@(s) ~isempty(s.finalPH), comparison);
    pHLabels = labels(pHMask);
    for k = 1:numel(comparison)
        if isempty(comparison(k).finalPH)
            continue;
        end
        boxchart(ax, repmat(categorical(labels(k), pHLabels, 'Ordinal', true), ...
            numel(comparison(k).finalPH), 1), comparison(k).finalPH(:), ...
            'BoxFaceColor', colors(k, :), 'MarkerStyle', '.', 'HandleVisibility', 'off');
    end
    xlabel(ax, 'PHREEQC mineral case');
    ylabel(ax, 'pH (-)');
    title(ax, '(c) Final cellwise pH');
    styleAxes(ax, 11);
    ax.XTickLabelRotation = 20;
    lastTime = comparison(1).timeDays(end);
    title(layout, sprintf('%dD mineral comparison at t = %.4g d', ...
        opt.dimension, lastTime));
    layout.Title.FontName = 'Times New Roman';
    layout.Title.FontSize = 12;
end

function fig = plotHydrogenLoss(comparison, labels, colors, styles, lastTime, opt)
    hasSpatial = isfield(comparison, 'spatialH2LossPercent');
    if hasSpatial
        sizeCm = [28, 20];
    else
        sizeCm = [28, 13];
    end
    fig = paperFigure(sizeCm, sprintf('%dD hydrogen consumption', opt.dimension));
    layout = tiledlayout(fig, 1 + hasSpatial, 2, ...
        'TileSpacing', 'compact', 'Padding', 'compact');
    for panel = 1:2 + 2*hasSpatial
        ax = nexttile(layout);
        hold(ax, 'on');
        if mod(panel, 2) == 1
            indices = 1:numel(comparison);
        else
            indices = 2:numel(comparison);
        end
        handles = gobjects(numel(indices), 1);
        for i = 1:numel(indices)
            k = indices(i);
            if panel <= 2
                x = [0; comparison(k).timeDays(:)];
                y = [0; comparison(k).h2LossPercent(:)];
            else
                [x, order] = sort(comparison(k).xDimensionless);
                y = comparison(k).spatialH2LossPercent(order);
            end
            handles(i) = plot(ax, x, y, 'LineWidth', 1.8, 'Color', colors(k, :), ...
                'LineStyle', styles{1 + mod(k - 1, 4)});
        end
        if panel <= 2
            xlabel(ax, 'Time (d)');
            ylabel(ax, 'H_2 consumed / H_2 injected to date (%)');
            xlim(ax, [0, lastTime]);
        else
            xlabel(ax, 'Distance from inlet, x/L (-)');
            ylabel(ax, 'Cell H_2 consumed / total H_2 injected (%)');
            xlim(ax, [0, 1]);
        end
        titles = {'(a) Consumed fraction: all cases', '(b) PHREEQC detail', ...
            '(c) Spatial contribution: all cases', '(d) PHREEQC detail'};
        title(ax, titles{panel});
        styleAxes(ax, 11);
        if panel == 1
            lg = legend(ax, handles, cellstr(labels), 'Orientation', 'horizontal');
            lg.Layout.Tile = 'south';
            lg.FontSize = 11;
            lg.Box = 'off';
        end
    end
    title(layout, sprintf('%dD biological H_2 consumption at t = %.4g d', ...
        opt.dimension, lastTime));
    layout.Title.FontName = 'Times New Roman';
    layout.Title.FontSize = 12;
end

function exportFigure(fig, name, opt)
    if ~isempty(opt.outputDirectory)
        paperExport(fig, sprintf('minerals_%dD_%s', opt.dimension, name), ...
            'dir', opt.outputDirectory, 'formats', {'pdf', 'png'});
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
