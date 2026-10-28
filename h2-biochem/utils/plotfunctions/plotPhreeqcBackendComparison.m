function figures = plotPhreeqcBackendComparison(scenarios, varargin)
    % Plot saved aqueous profiles and hydrogen consumption for chemistry backends
    %
    % SYNOPSIS:
    %   figures = plotPhreeqcBackendComparison(scenarios);
    %   figures = plotPhreeqcBackendComparison(scenarios, 'outputDirectory', '');
    %
    % PARAMETERS:
    %   scenarios - Nonempty struct array returned by runThreeBackendComparison.
    %               Each entry supplies name, snapshotIndices, snapshotLabels,
    %               timeDays, aqueousH2, aqueousDIC, lossPercent,
    %               xDimensionless and finalSpatialConsumptionMoles. Snapshot
    %               counts must agree, and corresponding times must match within
    %               1e-8 day. Models and state histories are not used for plotting.
    %
    % OPTIONAL PARAMETERS:
    %   outputDirectory - PDF/PNG export folder (default build/phreeqc-figures
    %                     under pwd). Pass an empty character vector, '', to
    %                     create figures without writing files.
    %
    % RETURNS:
    %   figures - Three figure handles, in this order:
    %               1. Aqueous H2 mole fraction and DIC (mol/kgw) profiles.
    %               2. Cumulative H2 consumption / total scheduled injection (%).
    %               3. Final cumulative H2 consumption per cell (mol/cell).
    %             Time is in days; distance is x/L. Values and normalization
    %             come from scenarios; plotting does not recompute consumption.
    %
    % DESCRIPTION:
    %   Redraw existing results without running simulations. Profiles and final
    %   spatial consumption are sorted by dimensionless cell position. Each row
    %   of profile axes shares y limits. Case labels and snapshot labels are
    %   taken from the input array.
    %
    %   Exports use vector PDF and 300-dpi PNG, with these base names:
    %     backends_aqueous_profiles
    %     backends_H2_consumption_time
    %     backends_H2_consumption_space
    %   Figures remain open; the caller owns the returned handles.
    %
    % SEE ALSO:
    %   runThreeBackendComparison, paperExport, paperFigure, paperColors

    opt = merge_options(struct('outputDirectory', ...
        fullfile(pwd, 'build', 'phreeqc-figures')), varargin{:});
    colors = paperColors(numel(scenarios));
    styles = {'-', '--', ':', '-.'};
    labels = cellstr(vertcat(scenarios.name));
    nSnapshots = numel(scenarios(1).snapshotIndices);

    %% Plot aqueous hydrogen and inorganic carbon profiles
    figures = gobjects(3, 1);
    figures(1) = plotProfiles(scenarios, colors, styles, labels, nSnapshots);
    exportFigure(figures(1), 'backends_aqueous_profiles', opt);

    %% Plot cumulative hydrogen consumption over time
    figures(2) = plotConsumptionTime(scenarios, colors, styles, labels, nSnapshots);
    exportFigure(figures(2), 'backends_H2_consumption_time', opt);

    %% Plot final spatial hydrogen consumption
    figures(3) = plotConsumptionSpace(scenarios, colors, styles, labels);
    exportFigure(figures(3), 'backends_H2_consumption_space', opt);
end

function fig = plotProfiles(scenarios, colors, styles, labels, nSnapshots)
    fig = paperFigure([30, 19], 'Aqueous hydrogen and inorganic carbon');
    layout = tiledlayout(fig, 2, nSnapshots, ...
        'TileSpacing', 'compact', 'Padding', 'compact');
    axesList = gobjects(2, nSnapshots);
    for row = 1:2
        for snapshot = 1:nSnapshots
            ax = nexttile(layout);
            axesList(row, snapshot) = ax;
            hold(ax, 'on');
            handles = gobjects(numel(scenarios), 1);
            times = zeros(numel(scenarios), 1);
            for k = 1:numel(scenarios)
                if row == 1
                    y = scenarios(k).aqueousH2(:, snapshot);
                else
                    y = scenarios(k).aqueousDIC(:, snapshot);
                end
                [x, order] = sort(scenarios(k).xDimensionless);
                handles(k) = plot(ax, x, y(order), 'Color', colors(k, :), ...
                    'LineStyle', styles{1 + mod(k - 1, 4)}, 'LineWidth', 1.8);
                times(k) = scenarios(k).timeDays( ...
                    scenarios(k).snapshotIndices(snapshot));
            end
            assert(max(times) - min(times) < 1e-8, ...
                'Profile snapshots must use matched times.');
            title(ax, sprintf('(%c) %s, t = %.4g d', ...
                'a' + (row - 1) * nSnapshots + snapshot - 1, ...
                scenarios(1).snapshotLabels(snapshot), times(1)));
            if snapshot == 1
                if row == 1
                    ylabel(ax, 'Aqueous H_2 mole fraction (-)');
                else
                    ylabel(ax, 'DIC (mol kg_{w}^{-1})');
                end
            end
            if row == 2
                xlabel(ax, 'Distance from inlet, x/L (-)');
            end
            xlim(ax, [0, 1]);
            styleAxes(ax, 11);
            if row == 1 && snapshot == 1
                addLegend(ax, handles, labels);
            end
        end
        linkaxes(axesList(row, :), 'y');
    end
end

function fig = plotConsumptionTime(scenarios, colors, styles, labels, nSnapshots)
    fig = paperFigure([22, 13], 'Cumulative biological hydrogen consumption');
    layout = tiledlayout(fig, 1, 1, 'Padding', 'compact');
    ax = nexttile(layout);
    hold(ax, 'on');
    handles = gobjects(numel(scenarios), 1);
    for k = 1:numel(scenarios)
        handles(k) = plot(ax, [0; scenarios(k).timeDays(:)], ...
            [0; scenarios(k).lossPercent(:)], ...
            'Color', colors(k, :), 'LineStyle', styles{1 + mod(k - 1, 4)}, ...
            'LineWidth', 1.8);
    end
    for k = 1:min(2, nSnapshots)
        t = scenarios(1).timeDays(scenarios(1).snapshotIndices(k));
        xline(ax, t, ':', char(scenarios(1).snapshotLabels(k)), ...
            'HandleVisibility', 'off', 'LabelVerticalAlignment', 'bottom');
    end
    xlabel(ax, 'Time (d)');
    ylabel(ax, 'H_2 consumed / total scheduled H_2 injection (%)');
    title(ax, 'Cumulative biological H_2 consumption');
    xlim(ax, [0, max(arrayfun(@(s) s.timeDays(end), scenarios))]);
    styleAxes(ax, 11);
    addLegend(ax, handles, labels);
end

function fig = plotConsumptionSpace(scenarios, colors, styles, labels)
    fig = paperFigure([22, 13], 'Spatial biological hydrogen consumption');
    layout = tiledlayout(fig, 1, 1, 'Padding', 'compact');
    ax = nexttile(layout);
    hold(ax, 'on');
    handles = gobjects(numel(scenarios), 1);
    for k = 1:numel(scenarios)
        [x, order] = sort(scenarios(k).xDimensionless);
        handles(k) = plot(ax, x, scenarios(k).finalSpatialConsumptionMoles(order), ...
            'Color', colors(k, :), 'LineStyle', styles{1 + mod(k - 1, 4)}, ...
            'LineWidth', 1.8);
    end
    xlabel(ax, 'Distance from inlet, x/L (-)');
    ylabel(ax, 'Cumulative H_2 consumed (mol cell^{-1})');
    title(ax, 'Final spatial H_2 consumption');
    xlim(ax, [0, 1]);
    styleAxes(ax, 11);
    addLegend(ax, handles, labels);
end

function addLegend(ax, handles, labels)
    lg = legend(ax, handles, labels, 'Orientation', 'horizontal', 'NumColumns', 2);
    lg.Layout.Tile = 'south';
    lg.FontSize = 10;
    lg.Box = 'off';
end

function exportFigure(fig, name, opt)
    if ~isempty(opt.outputDirectory)
        paperExport(fig, name, 'dir', opt.outputDirectory, ...
            'formats', {'pdf', 'png'});
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
