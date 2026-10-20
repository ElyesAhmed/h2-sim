function figures = plotCompositionalPhreeqcValidation(result, varargin)
%Plot storage-cycle chemistry with an optional external reference
%
% SYNOPSIS:
%   figures = plotCompositionalPhreeqcValidation(result)
%   figures = plotCompositionalPhreeqcValidation(result, 'outputDirectory', folder)
%
% DESCRIPTION:
%   Plot hydrogen consumption, aqueous hydrogen, pH, DIC, and reaction
%   contributions for the standalone H2sim result. Include reference curves
%   and maps when the result contains optional reference data.

    opt = merge_options(struct('outputDirectory', ''), varargin{:});
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
        data{end+1} = diagnostics.reference;
        labels{end+1} = 'Reference';
    end
    time = double(data{1}.timeDays(:));
    distance = data{1}.coordinates(:, 1);
    validateComparisonCoordinates(data, time, distance);
    nCases = numel(data);
    styles = {'-', '--'};

    %% Hydrogen consumption and aqueous profiles
    figures = gobjects(1, 3);
    figures(1) = figure('Color', 'w', 'Units', 'centimeters', ...
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

    %% pH and dissolved inorganic carbon
    figures(2) = figure('Color', 'w', 'Units', 'centimeters', ...
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

    %% Reaction-specific hydrogen consumption
    figures(3) = figure('Color', 'w', 'Units', 'centimeters', ...
        'Position', [2, 2, 29, 11]);
    tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    reactions = {'MET', 'ACE', 'SRB'};
    contributions = cell(1, nCases);
    for j = 1:nCases
        contributions{j} = 100*reshape(sum(data{j}.consumption, 1), ...
            numel(time), 3)/data{j}.injectedMoles;
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
    styleFigures(figures, time(end));
    exportResults(figures, time, data, contributions, opt.outputDirectory);
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
        names{end+1} = 'Reference_total_percent';
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
Copyright 2026 H2sim contributors.

This file is part of H2sim.

H2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

H2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with H2sim. If not, see <https://www.gnu.org/licenses/>.
%}
