function figures = plotCompositionalPhreeqcValidation(result, varargin)
    % Plot storage-cycle chemistry with an optional external reference
    %
    % SYNOPSIS:
    %   figures = plotCompositionalPhreeqcValidation(result)
    %   figures = plotCompositionalPhreeqcValidation(result, 'outputDirectory', folder)
    %
    % PARAMETERS:
    %   result - Result returned by exampleCompositionalPhreeqcValidation, or a
    %            struct with cached diagnostics. diagnostics.h2sim is required;
    %            diagnostics.reference is optional. Each diagnostic entry has
    %            timeDays, coordinates (m), h2 (aqueous mole fraction), pH, dic
    %            (mol/kg water), consumption (cumulative mol H2, cells-by-times-
    %            reactions), injectedMoles and lossPercent. Reaction order is
    %            MET, ACE, SRB. Reference times and first coordinate columns
    %            must match H2sim exactly. Without cached diagnostics, the collector uses
    %            result.h2sim and any optional result.reference saved states.
    %
    % OPTIONAL PARAMETERS:
    %   outputDirectory - Export folder (default '', figures only). A nonempty
    %                     folder receives three 200-dpi PNGs, three vector PDFs
    %                     and phreeqc_loss_history.csv.
    %
    % RETURNS:
    %   figures - Row vector of three open figure handles, owned by the caller:
    %               1. Hydrogen loss and aqueous hydrogen maps.
    %               2. pH and DIC maps with shared per-quantity color limits.
    %               3. MET/ACE/SRB contributions to hydrogen loss.
    %
    % DESCRIPTION:
    %   Redraw stored results without running simulations or an external driver.
    %   Cached diagnostics are preferred; otherwise collect them from the saved
    %   model, schedule and accepted states. Legacy ugfact fields remain readable
    %   as optional reference data; stored provenance is not changed.
    %
    %   All loss percentages use total prescribed injection as their denominator
    %   at every time. Reaction contributions must sum to total loss within
    %   1e-8 percentage points. Time is in days; maps use the first cell coordinate
    %   as distance. Operating-period markers appear at days 50 and 200 when the
    %   final time exceeds them. Common color limits are padded for constant data.
    %
    %   Export base names are phreeqc_validation_full_cycle,
    %   phreeqc_geochemistry_full_cycle and phreeqc_reaction_loss_full_cycle.
    %   The CSV contains time, total loss and reaction percentages, adding reference
    %   columns only when reference diagnostics are present. Short datasets retain
    %   these historical filenames; filenames do not establish full-cycle coverage.
    %
    % SEE ALSO:
    %   exampleCompositionalPhreeqcValidation, collectPhreeqcValidationDiagnostics

    opt = merge_options(struct('outputDirectory', ''), varargin{:});
    [data, labels, time, distance, nCases, styles] = prepareData(result);

    %% Hydrogen consumption and aqueous profiles
    figures = gobjects(1, 3);
    figures(1) = plotHydrogenProfiles(data, labels, time, distance, nCases, styles);

    %% pH and dissolved inorganic carbon
    figures(2) = plotGeochemistry(data, labels, time, distance, nCases);

    %% Reaction-specific hydrogen consumption
    [figures(3), contributions] = plotReactionConsumption( ...
        data, labels, time, nCases, styles);
    styleFigures(figures, time(end));
    exportResults(figures, time, data, contributions, opt.outputDirectory);
end

function [data, labels, time, distance, nCases, styles] = prepareData(result)
    if isfield(result, 'diagnostics')
        diagnostics = result.diagnostics;
    else
        diagnostics = collectPhreeqcValidationDiagnostics(result);
    end
    % Read older saved reference datasets without changing their provenance.
    if ~isfield(diagnostics, 'reference') && isfield(diagnostics, 'ugfact')
        diagnostics.reference = diagnostics.ugfact;
    end
    data = {diagnostics.h2sim};
    labels = {'Compositional PHREEQC'};
    if isfield(diagnostics, 'reference') && ~isempty(diagnostics.reference)
        data{end + 1} = diagnostics.reference;
        labels{end + 1} = 'Reference';
    end
    time = double(data{1}.timeDays(:));
    distance = data{1}.coordinates(:, 1);
    validateComparisonCoordinates(data, time, distance);
    nCases = numel(data);
    styles = {'-', '--'};
end

function fig = plotHydrogenProfiles(data, labels, time, distance, nCases, styles)
    fig = figure('Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 29, 11]);
    tiledlayout(1, 1 + nCases, 'TileSpacing', 'compact', 'Padding', 'compact');
    ax = nexttile;
    hold(ax, 'on');
    maximum = 0;
    for j = 1:nCases
        plot(ax, time, data{j}.lossPercent, styles{j}, 'LineWidth', 1.8);
        maximum = max(maximum, max(data{j}.h2(:)));
    end
    xlabel(ax, 'Time (days)');
    ylabel(ax, 'Consumed H_2 / total prescribed injection (%)');
    title(ax, 'Hydrogen consumption');
    legend(ax, labels, 'Location', 'best');
    grid(ax, 'on');
    for j = 1:nCases
        ax = nexttile;
        plotChemistryMap(ax, time, distance, data{j}.h2, ...
            labels{j}, 'Aqueous H_2 mole fraction (-)', plotLimits(0, maximum));
    end
end

function fig = plotGeochemistry(data, labels, time, distance, nCases)
    fig = figure('Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 26, 18]);
    tiledlayout(2, nCases, 'TileSpacing', 'compact', 'Padding', 'compact');
    fields = {'pH', 'dic'};
    units = {'pH (-)', 'DIC (mol/kg water)'};
    for c = 1:numel(fields)
        low = inf;
        high = -inf;
        for j = 1:nCases
            values = data{j}.(fields{c});
            low = min(low, min(values(:)));
            high = max(high, max(values(:)));
        end
        for j = 1:nCases
            ax = nexttile;
            plotChemistryMap(ax, time, distance, data{j}.(fields{c}), ...
                [labels{j}, ' · ', fields{c}], units{c}, plotLimits(low, high));
        end
    end
end

function [fig, contributions] = plotReactionConsumption( ...
    data, labels, time, nCases, styles)
    fig = figure('Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 29, 11]);
    tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    reactions = {'MET', 'ACE', 'SRB'};
    contributions = cell(1, nCases);
    for j = 1:nCases
        contributions{j} = 100 * reshape(sum(data{j}.consumption, 1), ...
            numel(time), 3) / data{j}.injectedMoles;
        assert(max(abs(sum(contributions{j}, 2) - data{j}.lossPercent(:))) < 1e-8, ...
            'Reaction contributions must sum to total hydrogen consumption.');
    end
    for c = 1:numel(reactions)
        ax = nexttile;
        hold(ax, 'on');
        for j = 1:nCases
            plot(ax, time, contributions{j}(:, c), styles{j}, 'LineWidth', 1.8);
        end
        xlabel(ax, 'Time (days)');
        ylabel(ax, 'Consumed H_2 / total prescribed injection (%)');
        title(ax, reactions{c});
        legend(ax, labels, 'Location', 'best');
        grid(ax, 'on');
    end
end

function validateComparisonCoordinates(data, time, distance)
    for j = 2:numel(data)
        assert(isequal(time, double(data{j}.timeDays(:))) && ...
            isequal(distance, data{j}.coordinates(:, 1)), ...
            'Comparison datasets must use matching times and coordinates.');
    end
end

function limits = plotLimits(low, high)
    if low == high
        padding = eps(max(1, abs(low)));
        limits = [low - padding, high + padding];
    else
        limits = [low, high];
    end
end

function plotChemistryMap(ax, time, distance, values, name, unit, limits)
    imagesc(ax, time, distance, values);
    set(ax, 'YDir', 'normal');
    caxis(ax, limits);
    xlabel(ax, 'Time (days)');
    ylabel(ax, 'Distance (m)');
    title(ax, name);
    cb = colorbar(ax);
    ylabel(cb, unit);
end

function styleFigures(figures, finalDay)
    for fig = figures
        axesList = findall(fig, 'Type', 'axes');
        for ax = reshape(axesList, 1, [])
            xlim(ax, [0, finalDay]);
            set(ax, 'FontName', 'Arial', 'FontSize', 10);
            box(ax, 'on');
            if finalDay > 50
                xline(ax, 50, ':', 'HandleVisibility', 'off');
            end
            if finalDay > 200
                xline(ax, 200, ':', 'HandleVisibility', 'off');
            end
        end
    end
end

function exportResults(figures, time, data, contributions, folder)
    if isempty(folder)
        return
    end
    if ~isfolder(folder)
        mkdir(folder);
    end
    % Settle tiled layouts and colorbars before export captures their bounds.
    drawnow;
    files = {'phreeqc_validation_full_cycle', 'phreeqc_geochemistry_full_cycle', ...
        'phreeqc_reaction_loss_full_cycle'};
    for j = 1:numel(figures)
        exportgraphics(figures(j), fullfile(folder, [files{j}, '.png']), 'Resolution', 200);
        exportgraphics(figures(j), fullfile(folder, [files{j}, '.pdf']), 'ContentType', 'vector');
    end
    values = [time, data{1}.lossPercent(:)];
    names = {'Time_days', 'H2sim_total_percent'};
    if numel(data) == 2
        values = [values, data{2}.lossPercent(:)];
        names{end + 1} = 'Reference_total_percent';
    end
    values = [values, contributions{1}];
    names = [names, {'H2sim_MET_percent', 'H2sim_ACE_percent', 'H2sim_SRB_percent'}];
    if numel(data) == 2
        values = [values, contributions{2}];
        names = [names, {'Reference_MET_percent', 'Reference_ACE_percent', ...
            'Reference_SRB_percent'}];
    end
    writetable(array2table(values, 'VariableNames', names), ...
        fullfile(folder, 'phreeqc_loss_history.csv'));
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
