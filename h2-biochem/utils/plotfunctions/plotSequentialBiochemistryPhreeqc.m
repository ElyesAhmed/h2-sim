function figures = plotSequentialBiochemistryPhreeqc(summary, varargin)
    % Plot final flow/chemistry profiles and cumulative multirate H2 consumption
    %
    % SYNOPSIS:
    %   figures = plotSequentialBiochemistryPhreeqc(summary);
    %   figures = plotSequentialBiochemistryPhreeqc(summary, ...
    %       'outputDirectory', '');
    %
    % PARAMETERS:
    %   summary - Result from exampleSequentialBiochemistryPhreeqc1D. Required
    %             fields: model, states, schedule and injectedH2Moles. The final
    %             state supplies pressure (Pa), phase saturations, phreeqcPH
    %             and nbact (N/N0). The model supplies the grid, vapor-phase
    %             index and biochemical mixture; the state history and schedule
    %             are used by computeH2Consumption for reaction-wise totals.
    %
    % OPTIONAL PARAMETERS:
    %   outputDirectory - PDF/PNG folder (default build/phreeqc-figures under pwd).
    %                     Pass an empty character vector, '', to disable export.
    %
    % RETURNS:
    %   figures - Two open figure handles owned by the caller:
    %               1. Final pressure (MPa), gas saturation, pH and biomass.
    %               2. Cumulative H2 consumption by reaction (mol), and total
    %                  consumption / total scheduled H2 injection (%).
    %
    % DESCRIPTION:
    %   Redraw saved results without running a simulation. Final profiles are
    %   sorted by dimensionless cell distance x/L. Time is accumulated from
    %   schedule.step.val (seconds) and plotted in days. The total consumption
    %   denominator is summary.injectedH2Moles at every time, including during
    %   injection. Consumption is recomputed from saved states, not simulated.
    %   The MET/ACE/SRB labels follow the benchmark's reaction order.
    %
    %   Exports use vector PDF and 300-dpi PNG with base names
    %   multirate_final_profiles and multirate_H2_consumption. Figures remain
    %   open for inspection or further editing.
    %
    % SEE ALSO:
    %   exampleSequentialBiochemistryPhreeqc1D, computeH2Consumption, paperExport

    opt = merge_options(struct('outputDirectory', ...
        fullfile(pwd, 'build', 'phreeqc-figures')), varargin{:});
    model = summary.model;
    states = summary.states;
    schedule = summary.schedule;
    time = cumsum(schedule.step.val(:)) / day;
    [x, order] = sort(dimensionlessCellDistance(model.G));
    final = states{end};
    colors = paperColors(4);
    colors = colors(2:4, :);
    figures = gobjects(2, 1);

    %% Plot final flow and aqueous chemistry
    figures(1) = plotFinalProfiles(model, final, x, order, colors, time);
    exportFigure(figures(1), 'multirate_final_profiles', opt);

    %% Accumulate saved reaction-wise hydrogen consumption
    [cumulative, n] = collectConsumption(states, schedule, model);

    %% Plot pathway totals and the fraction of scheduled injection
    figures(2) = plotConsumption(time, cumulative, n, colors, summary);
    exportFigure(figures(2), 'multirate_H2_consumption', opt);
end

function fig = plotFinalProfiles(model, final, x, order, colors, time)
    fig = paperFigure([25, 18], 'Multirate final flow and chemistry');
    layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    fields = {value(final.pressure) / 1e6, ...
        value(final.s(:, model.getVaporIndex())), ...
        value(final.phreeqcPH), value(final.nbact)};
    units = {'Pressure (MPa)', 'Gas saturation (-)', 'pH (-)', 'Biomass, N/N_0 (-)'};
    titles = {'(a) Pressure', '(b) Gas saturation', '(c) Aqueous pH', '(d) Microbial biomass'};
    for k = 1:4
        ax = nexttile(layout);
        hold(ax, 'on');
        y = fields{k};
        handles = plot(ax, x, y(order, :), 'LineWidth', 1.8);
        for j = 1:numel(handles)
            handles(j).Color = colors(1 + mod(j - 1, 3), :);
        end
        xlabel(ax, 'Distance from inlet, x/L (-)');
        ylabel(ax, units{k});
        title(ax, titles{k});
        xlim(ax, [0, 1]);
        styleAxes(ax, 11);
        if k == 2
            ylim(ax, [0, 1]);
        end
        if k == 4 && numel(handles) == 3
            lg = legend(ax, handles, {'MET', 'ACE', 'SRB'}, 'Location', 'best');
            lg.FontSize = 10;
            lg.Box = 'off';
        end
    end
    title(layout, sprintf('Multirate flow / chemistry at t = %.4g d', time(end)));
end

function [cumulative, n] = collectConsumption(states, schedule, model)
    n = model.biochemFluid.nbioreact;
    cumulative = zeros(numel(states), n);
    for j = 1:n
        [~, c] = computeH2Consumption(states, schedule, model, j);
        cumulative(:, j) = sum(c, 1).';
    end
end

function fig = plotConsumption(time, cumulative, n, colors, summary)
    fig = paperFigure([27, 13], 'Multirate biological hydrogen consumption');
    layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    ax = nexttile(layout);
    hold(ax, 'on');
    handles = plot(ax, [0; time], [zeros(1, n); cumulative], 'LineWidth', 1.8);
    styles = {'-', '--', ':'};
    for j = 1:n
        handles(j).Color = colors(1 + mod(j - 1, 3), :);
        handles(j).LineStyle = styles{1 + mod(j - 1, 3)};
    end
    xlabel(ax, 'Time (d)');
    ylabel(ax, 'Cumulative H_2 consumed (mol)');
    title(ax, '(a) Consumption by pathway');
    xlim(ax, [0, time(end)]);
    styleAxes(ax, 11);
    lg = legend(ax, handles, {'Methanogenesis (MET)', 'Acetogenesis (ACE)', ...
        'Sulfate reduction (SRB)'}, 'Orientation', 'horizontal');
    lg.Layout.Tile = 'south';
    lg.FontSize = 11;
    lg.Box = 'off';

    ax = nexttile(layout);
    plot(ax, [0; time], [0; 100 * sum(cumulative, 2) / summary.injectedH2Moles], ...
        'Color', [0.15, 0.15, 0.15], 'LineWidth', 1.8);
    xlabel(ax, 'Time (d)');
    ylabel(ax, 'H_2 consumed / total scheduled H_2 injection (%)');
    title(ax, '(b) Total biological consumption');
    xlim(ax, [0, time(end)]);
    styleAxes(ax, 11);
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
