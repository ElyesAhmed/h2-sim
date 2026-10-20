function figures=plotCompositionalBacterial2DThreeReactions(results,varargin)
%PLOTCOMPOSITIONALBACTERIAL2DTHREEREACTIONS Redraw the existing 2D storage case.
% Maps show gas-phase mole fractions, masked where gas saturation < 0.001.
% Well logs use signed component mass rates: injection positive, production negative.
opt=merge_options(struct('outputDirectory',''),varargin{:});
assert(all([results.complete]),'Cycle figures require completed simulations.');
labels={'H_2','CO_2','CH_4'};components=[2,3,4];
colors=[.04,.5,.51;.85,.5,.2;.35,.35,.7];styles={'-','--',':'};
n=numel(results);f=figure('Color','w','Units','centimeters','Position',[2,2,27,9*n]);
tiledlayout(n,3,'TileSpacing','compact','Padding','compact');
for j=1:n
 r=results(j);ends=getCyclesLastSteps(r.schedule);index=ends.charge(end);
 t=sum(r.schedule.step.val(1:index))/day;s=r.states{index};
 for c=1:3
  ax=nexttile;data=s.y(:,components(c));data(s.s(:,2)<1e-3)=nan;
  plotCellData(r.model.G,data,'EdgeColor','none');hold(ax,'on');
  wc=r.schedule.control(1).W.cells;
  plot(ax,r.model.G.cells.centroids(wc,1),r.model.G.cells.centroids(wc,2),'ko','MarkerFaceColor','w','MarkerSize',3);
  view(ax,2);axis(ax,'equal');axis(ax,[0,50,0,50]);caxis(ax,[0,1]);colormap(ax,parula(256));
  xlabel(ax,'Horizontal distance (m)');ylabel(ax,'Elevation (m)');
  title(ax,sprintf('%s · %s · injection %d, day %g',labels{c},r.name,numel(ends.charge),t));
  cb=colorbar(ax);ylabel(cb,'Gas-phase mole fraction (-)');
  set(ax,'FontName','Arial','FontSize',9);box(ax,'on');
 end
end
exportPlot(f,opt.outputDirectory,'compositional_2d_gas_maps');
g=figure('Color','w','Units','centimeters','Position',[2,2,25,17]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
axesLogs=gobjects(1,4);for c=1:4,axesLogs(c)=nexttile;hold(axesLogs(c),'on');end
fields={'H2','CO2','C1'};
for j=1:n
 r=results(j);t=cumsum(r.schedule.step.val)/day;
 color=colors(mod(j-1,size(colors,1))+1,:);style=styles{mod(j-1,3)+1};
 logData=zeros(numel(t),4);
 for c=1:3
  logData(:,c)=cellfun(@(w) sum([w.(fields{c})]),r.wellSols)*day;
 end
 logData(:,4)=cellfun(@(w) w(1).bhp,r.wellSols)/barsa;
 for k=1:numel(t)
  W=r.schedule.control(r.schedule.step.control(k)).W;
  if ~isFlowing(W(1),r.wellSols{k}(1))
   logData(k,1:3)=0;logData(k,4)=nan;
  end
 end
 for c=1:4
  plot(axesLogs(c),t,logData(:,c),'Color',color,'LineStyle',style, ...
   'LineWidth',1.7,'DisplayName',r.name);
 end
 if ~isempty(opt.outputDirectory)
  writetable(array2table([t,logData],'VariableNames', ...
   {'Time_days','H2_kg_day','CO2_kg_day','CH4_kg_day','BHP_bar'}), ...
   fullfile(opt.outputDirectory,[r.name,'_well_logs.csv']));
 end
end
for c=1:4
 a=axesLogs(c);xlabel(a,'Time (days)');
 if c<=3
  ylabel(a,[labels{c},' component rate (kg/day)']);title(a,[labels{c},' well log']);
  yline(a,0,':','HandleVisibility','off');
 else,ylabel(a,'Bottom-hole pressure (bar)');title(a,'Well pressure');end
 grid(a,'on');box(a,'on');legend(a,'Location','best');set(a,'FontName','Arial','FontSize',10);
end
exportPlot(g,opt.outputDirectory,'compositional_2d_cycle_logs');figures=[f,g];
for j=1:n
 r=results(j);if ~r.model.bacteriamodel,continue;end
 t=cumsum(r.schedule.step.val)/day;ends=getCyclesLastSteps(r.schedule);
 samples=[ends.cushion(1),ends.charge(end)];reactionNames={'MET','ACE','SRB'};
 h=figure('Color','w','Units','centimeters','Position',[2,2,32,17]);
 tiledlayout(2,4,'TileSpacing','compact','Padding','compact');
 for row=1:2
  state=r.states{samples(row)};
  for c=1:4
   a=nexttile;
   if c==1
    data=state.y(:,2);data(state.s(:,2)<1e-3)=nan;clim=[0,1];name='H_2';unit='Gas mole fraction (-)';
   else
    data=state.nbact(:,c-1);name=reactionNames{c-1};unit='nbact (model units)';
    clim=[min(cellfun(@(s) min(s.nbact(:,c-1)),r.states(samples))), ...
          max(cellfun(@(s) max(s.nbact(:,c-1)),r.states(samples)))];
    if clim(2)<=clim(1),clim(2)=clim(1)+1;end
   end
   plotCellData(r.model.G,data,'EdgeColor','none');view(a,2);axis(a,'equal');axis(a,[0,50,0,50]);
   caxis(a,clim);colormap(a,parula(256));cb=colorbar(a);ylabel(cb,unit);
   title(a,sprintf('%s · day %g',name,t(samples(row))));
   xlabel(a,'Horizontal distance (m)');ylabel(a,'Elevation (m)');set(a,'FontName','Arial','FontSize',9);
  end
 end
 exportPlot(h,opt.outputDirectory,'compositional_2d_bacterial_maps');
 cumulative=zeros(numel(t),3);
 for k=1:numel(t)
  assert(isfield(r.states{k},'cumulativeH2ConsumptionMoles'),'Saved cumulative reaction diagnostics required.');
  cumulative(k,:)=sum(r.states{k}.cumulativeH2ConsumptionMoles,1);
 end
 injected=zeros(numel(t),1);
 for k=1:numel(t)
  W=r.schedule.control(r.schedule.step.control(k)).W;
  for wi=1:numel(W)
   if isFlowing(W(wi),r.wellSols{k}(wi))
    injected(k)=injected(k)+max(r.wellSols{k}(wi).H2,0);
   end
  end
 end
 injectedMoles=cumsum(injected(:).*r.schedule.step.val(:))/r.model.compFluid.molarMass(2);
 pct=100*cumulative./max(injectedMoles,eps);
 q=figure('Color','w','Units','centimeters','Position',[2,2,23,11]);a=axes(q);hold(a,'on');
 for c=1:3,plot(a,t,pct(:,c),'LineWidth',1.8,'DisplayName',reactionNames{c});end
 plot(a,t,sum(pct,2),'k--','LineWidth',1.8,'DisplayName','Total');
 xlabel(a,'Time (days)');ylabel(a,'Consumed H_2 / cumulative injected H_2 (%)');
 title(a,'Hydrogen consumption by microbial reaction');legend(a,'Location','best');grid(a,'on');box(a,'on');
 exportPlot(q,opt.outputDirectory,'compositional_2d_h2_consumption');
 if ~isempty(opt.outputDirectory)
  writetable(array2table([t,pct,sum(pct,2)],'VariableNames', ...
   {'Time_days','MET_percent','ACE_percent','SRB_percent','Total_percent'}), ...
   fullfile(opt.outputDirectory,'compositional_2d_h2_consumption.csv'));
 end
 figures=[figures,h,q]; %#ok<AGROW>
end
end
function exportPlot(f,folder,name)
if isempty(folder),return;end
if ~isfolder(folder),mkdir(folder);end
exportgraphics(f,fullfile(folder,[name,'.png']),'Resolution',200);
exportgraphics(f,fullfile(folder,[name,'.pdf']),'ContentType','vector');
end

function active=isFlowing(W,well)
active=W.status && well.status && ~(~strcmp(W.type,'bhp') && W.val==0);
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
