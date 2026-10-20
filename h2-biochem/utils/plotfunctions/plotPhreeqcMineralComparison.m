function figures = plotPhreeqcMineralComparison(comparison, varargin)
% Redraw mineral-case results without rerunning simulations.
% Works with the name/rock/timeDays/finalPH metrics returned by the 1D case.
opt=merge_options(struct('dimension',1,'outputDirectory', ...
    fullfile(pwd,'build','phreeqc-figures')),varargin{:});
colors=paperColors(numel(comparison)); styles={'-','--',':','-.'};
names=vertcat(comparison.name);
labels=names;
for k=2:numel(comparison)
    labels(k)=names(k)+": "+erase(string(comparison(k).rock)," sandstone");
end
h2=vertcat(comparison.h2ConsumedByReactionMoles);
figures=gobjects(2,1);
figures(1)=paperFigure([32,14],sprintf('%dD mineral comparison',opt.dimension));
layout=tiledlayout(figures(1),1,3,'TileSpacing','compact','Padding','compact');
reactionColors=paperColors(4); reactionColors=reactionColors(2:4,:);
for panel=1:2
    ax=nexttile(layout);
    if panel==1, indices=1; else, indices=2:numel(comparison); end
    category=categorical(labels(indices),labels(indices),'Ordinal',true);
    bars=bar(ax,category,h2(indices,:),'stacked','BarWidth',0.65);
    for k=1:numel(bars), bars(k).FaceColor=reactionColors(k,:); end
    xlabel(ax,'Model / mineral case'); ylabel(ax,'H_2 consumed (mol)');
    if panel==1, title(ax,'(a) Original kinetics');
    else, title(ax,'(b) PHREEQC kinetics'); end
    totals=sum(h2(indices,:),2); upper=max(totals)*1.18+eps;
    ylim(ax,[0,upper]); styleAxes(ax,11); ax.XTickLabelRotation=20;
    text(ax,category,totals+0.035*upper, ...
        cellstr(compose('%.3g',totals)),'HorizontalAlignment','center', ...
        'FontName','Times New Roman','FontSize',10);
    if panel==1
        lg=legend(ax,bars,{'Methanogenesis (MET)','Acetogenesis (ACE)', ...
            'Sulfate reduction (SRB)'},'Orientation','horizontal');
        lg.Layout.Tile='south'; lg.FontSize=11; lg.Box='off';
    end
end
ax=nexttile(layout); hold(ax,'on');
pHMask=arrayfun(@(s) ~isempty(s.finalPH),comparison);
pHLabels=labels(pHMask);
for k=1:numel(comparison)
    if isempty(comparison(k).finalPH), continue; end
    boxchart(ax,repmat(categorical(labels(k),pHLabels,'Ordinal',true),numel(comparison(k).finalPH),1), ...
        comparison(k).finalPH(:),'BoxFaceColor',colors(k,:), ...
        'MarkerStyle','.','HandleVisibility','off');
end
xlabel(ax,'PHREEQC mineral case'); ylabel(ax,'pH (-)');
title(ax,'(c) Final cellwise pH'); styleAxes(ax,11); ax.XTickLabelRotation=20;
lastTime=comparison(1).timeDays(end);
title(layout,sprintf('%dD mineral comparison at t = %.4g d',opt.dimension,lastTime));
layout.Title.FontName='Times New Roman';
layout.Title.FontSize=12;
exportFigure(figures(1),'consumption_pH',opt);

hasSpatial=isfield(comparison,'spatialH2LossPercent');
if hasSpatial, sizeCm=[28,20]; else, sizeCm=[28,13]; end
figures(2)=paperFigure(sizeCm,sprintf('%dD hydrogen consumption',opt.dimension));
layout=tiledlayout(figures(2),1+hasSpatial,2,'TileSpacing','compact','Padding','compact');
for panel=1:2+2*hasSpatial
    ax=nexttile(layout); hold(ax,'on');
    if mod(panel,2)==1, indices=1:numel(comparison);
    else, indices=2:numel(comparison); end
    handles=gobjects(numel(indices),1);
    for i=1:numel(indices)
        k=indices(i);
        if panel<=2
            x=[0;comparison(k).timeDays(:)]; y=[0;comparison(k).h2LossPercent(:)];
        else
            [x,order]=sort(comparison(k).xDimensionless);
            y=comparison(k).spatialH2LossPercent(order);
        end
        handles(i)=plot(ax,x,y,'LineWidth',1.8,'Color',colors(k,:), ...
            'LineStyle',styles{1+mod(k-1,4)});
    end
    if panel<=2
        xlabel(ax,'Time (d)'); ylabel(ax,'H_2 consumed / H_2 injected to date (%)');
        xlim(ax,[0,lastTime]);
    else
        xlabel(ax,'Distance from inlet, x/L (-)');
        ylabel(ax,'Cell H_2 consumed / total H_2 injected (%)'); xlim(ax,[0,1]);
    end
    titles={'(a) Consumed fraction: all cases','(b) PHREEQC detail', ...
        '(c) Spatial contribution: all cases','(d) PHREEQC detail'};
    title(ax,titles{panel}); styleAxes(ax,11);
    if panel==1
        lg=legend(ax,handles,cellstr(labels),'Orientation','horizontal');
        lg.Layout.Tile='south'; lg.FontSize=11; lg.Box='off';
    end
end
title(layout,sprintf('%dD biological H_2 consumption at t = %.4g d',opt.dimension,lastTime));
layout.Title.FontName='Times New Roman';
layout.Title.FontSize=12;
exportFigure(figures(2),'H2_consumption',opt);
end
function exportFigure(fig,name,opt)
if ~isempty(opt.outputDirectory)
    paperExport(fig,sprintf('minerals_%dD_%s',opt.dimension,name), ...
        'dir',opt.outputDirectory,'formats',{'pdf','png'});
end
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
