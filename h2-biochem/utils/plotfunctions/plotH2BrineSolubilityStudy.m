function figures=plotH2BrineSolubilityStudy(result,varargin)
%PLOTH2BRINESOLUBILITYSTUDY Redraw saved phase-partition and salinity results.
opt=merge_options(struct('outputDirectory',''),varargin{:});
p=result.partition;temps=unique(p.temperatureK);target=temps(round(numel(temps)/2));
mask=abs(p.temperatureK-target)<1e-8;[pressure,order]=sort(p.pressurePa(mask));
x=p.xH2(mask,:);x=x(order,:);y=p.yWater(mask,:);y=y(order,:);
colors=[0.04,.5,.51;.85,.5,.2;.22,.32,.57;.48,.3,.58;.25,.25,.25];
f=figure('Color','w','Units','centimeters','Position',[2,2,25,11]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
for panel=1:2
 ax=nexttile;hold(ax,'on');
 for j=1:numel(p.modelNames)
  values=x(:,j);if panel==2,values=y(:,j);end
  if all(isnan(values)),continue;end
  if j==5
   plot(ax,pressure/1e6,values,'o','Color',colors(j,:),'MarkerSize',5,'DisplayName',p.modelNames{j});
  else
   plot(ax,pressure/1e6,values,'LineWidth',1.8,'Color',colors(j,:),'DisplayName',p.modelNames{j});
  end
 end
 xlabel(ax,'Pressure (MPa)');
 if panel==1,ylabel(ax,'Dissolved H_2 mole fraction (-)');title(ax,'Hydrogen in liquid water');
 else,ylabel(ax,'Gas-phase H_2O mole fraction (-)');title(ax,'Water in hydrogen gas');end
 legend(ax,'Location','best','FontSize',9);formatAxes(ax);
end
sgtitle(sprintf('Phase partitioning at %.0f °C · zero added salt',target-273.15));
exportPlot(f,opt.outputDirectory,'phase_partitioning');
s=result.salting;g=figure('Color','w','Units','centimeters','Position',[2,2,23,10]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
for panel=1:2
 ax=nexttile;hold(ax,'on');
 for j=1:3
  values=s.xH2(:,j);if panel==2,values=values/s.xH2(1,j);end
  plot(ax,s.saltMolality,values,'LineWidth',1.8,'Color',colors(j,:),'DisplayName',s.modelNames{j});
 end
 xlabel(ax,'NaCl molality (mol/kg water)');
 if panel==1,ylabel(ax,'Dissolved H_2 mole fraction (-)');title(ax,'Absolute solubility');
 else,ylabel(ax,'Solubility relative to zero salt (-)');title(ax,'Salting-out response');end
 legend(ax,'Location','best','FontSize',9);formatAxes(ax);
end
sgtitle('Salinity effect at 40 °C and 15 MPa');exportPlot(g,opt.outputDirectory,'salting_out');figures=[f,g];
% Temperature slice at a pressure already present in the saved study.
pressures=unique(p.pressurePa);[~,nearest]=min(abs(pressures-15e6));
targetPressure=pressures(nearest);mask=abs(p.pressurePa-targetPressure)<1e-6;
[temperature,order]=sort(p.temperatureK(mask));
x=p.xH2(mask,:);x=x(order,:);y=p.yWater(mask,:);y=y(order,:);
h=figure('Color','w','Units','centimeters','Position',[2,2,25,11]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
for panel=1:2
 ax=nexttile;hold(ax,'on');
 for j=1:numel(p.modelNames)
  values=x(:,j);if panel==2,values=y(:,j);end
  if all(isnan(values)),continue;end
  if j==5
   plot(ax,temperature-273.15,values,'o','Color',colors(j,:),'MarkerSize',5,'DisplayName',p.modelNames{j});
  else
   plot(ax,temperature-273.15,values,'LineWidth',1.8,'Color',colors(j,:),'DisplayName',p.modelNames{j});
  end
 end
 xlabel(ax,'Temperature (°C)');xlim(ax,[min(temperature),max(temperature)]-273.15);
 if panel==1,ylabel(ax,'Dissolved H_2 mole fraction (-)');title(ax,'Hydrogen in liquid water');
 else,ylabel(ax,'Gas-phase H_2O mole fraction (-)');title(ax,'Water in hydrogen gas');end
 legend(ax,'Location','best','FontSize',9);formatAxes(ax);
end
sgtitle(sprintf('Temperature-dependent partitioning at %.0f MPa · zero added salt',targetPressure/1e6));
exportPlot(h,opt.outputDirectory,'temperature_partitioning');figures=[figures,h];
if ~isempty(opt.outputDirectory)
 names={'TemperatureC','RK_xH2','SW_xH2','PR_xH2','Henry_xH2','ePCSAFT_xH2','RK_yWater','SW_yWater','PR_yWater','Henry_yWater','ePCSAFT_yWater'};
 writetable(array2table([temperature-273.15,x,y],'VariableNames',names),fullfile(opt.outputDirectory,'temperature_partitioning.csv'));
end
end
function formatAxes(ax)
set(ax,'FontName','Arial','FontSize',10);grid(ax,'on');box(ax,'on');
end
function exportPlot(f,folder,name)
if isempty(folder),return;end
if ~isfolder(folder),mkdir(folder);end
exportgraphics(f,fullfile(folder,[name,'.png']),'Resolution',200);
exportgraphics(f,fullfile(folder,[name,'.pdf']),'ContentType','vector');
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).

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
