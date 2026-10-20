classdef PhreeqcPublicationFiguresTest < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function hiddenFigures(test)
            visible=get(groot,'DefaultFigureVisible');
            set(groot,'DefaultFigureVisible','off');
            test.addTeardown(@() set(groot,'DefaultFigureVisible',visible));
            test.addTeardown(@() close(findall(groot,'Type','figure')));
        end
    end
    methods (Test)
        function distanceUsesDomainEdges(test)
            G.nodes.coords=[0,0;10,0]; G.cells.centroids=[9,0;1,0;4,0];
            test.verifyEqual(dimensionlessCellDistance(G),[0.9;0.1;0.4], ...
                'AbsTol',1e-14);
        end
        function mineralDetailPanelsKeepBaselineAndCaseScalesSeparate(test)
            item=struct('name',"Original",'rock',"Original", ...
                'h2ConsumedByReactionMoles',[2,3,37], ...
                'timeDays',[2;4],'h2LossPercent',[5;4], ...
                'finalPH',[]);
            data=repmat(item,4,1);
            rocks=["Bentheimer sandstone","Berea sandstone","Grey Berea sandstone"];
            for k=2:4
                data(k).name=string(char('A'+k-2)); data(k).rock=rocks(k-1);
                data(k).h2ConsumedByReactionMoles=[0.7,0.01,0.03];
                data(k).h2LossPercent=[0.04;0.07]; data(k).finalPH=[6.2;6.3];
            end
            figures=plotPhreeqcMineralComparison(data,'dimension',2,'outputDirectory','');
            ax=findall(figures(1),'Type','axes');
            original=ax(arrayfun(@(a) a.Layout.Tile==1,ax));
            detail=ax(arrayfun(@(a) a.Layout.Tile==2,ax));
            ph=ax(arrayfun(@(a) a.Layout.Tile==3,ax));
            test.verifyGreaterThan(original.YLim(2),42);
            test.verifyLessThan(detail.YLim(2),1);
            test.verifyEqual(numel(findall(original,'Type','bar')),3);
            test.verifyEqual(numel(findall(detail,'Type','bar')),3);
            test.verifyFalse(any(strcmp(ph.XAxis.Categories,'Original')));
            test.verifyEqual(numel(findall(figures(2),'Type','axes')),2);
        end
        function backendFiguresPreserveDataAndUseMatchedScales(test)
            s=struct('name',"Compositional PHREEQC",'timeDays',[2;4;6], ...
                'snapshotIndices',[1,2,3], ...
                'snapshotLabels',["End injection","End storage","End production"], ...
                'xDimensionless',[0.75;0.25], ...
                'aqueousH2',[0.1,0.2,0.3;0.4,0.5,0.6], ...
                'aqueousDIC',[0.001,0.002,0.003;0.004,0.005,0.006], ...
                'lossPercent',[1;2;3],'finalSpatialConsumptionMoles',[2;5]);
            figs=plotPhreeqcBackendComparison(s,'outputDirectory','');
            ax=findall(figs(1),'Type','axes');
            tiles=arrayfun(@(a) a.Layout.Tile,ax);
            for row=1:2
                selected=ax(tiles>(row-1)*3 & tiles<=row*3);
                limits=vertcat(selected.YLim);
                test.verifyEqual(limits,repmat(limits(1,:),3,1));
            end
            % Every profile line retains its corresponding values when x is sorted.
            lines=findall(figs(1),'Type','line');
            test.verifyEqual(numel(lines),6);
            for k=1:numel(lines)
                test.verifyEqual(lines(k).XData,[0.25,0.75]);
                test.verifyTrue(any(arrayfun(@(j) isequal(lines(k).YData, ...
                    s.aqueousH2([2,1],j).'),1:3)) || ...
                    any(arrayfun(@(j) isequal(lines(k).YData, ...
                    s.aqueousDIC([2,1],j).'),1:3)));
            end
            consumption=findall(figs(2),'Type','line');
            test.verifyEqual(consumption.YData,[0,1,2,3]);
            test.verifyEqual(consumption.XData,[0,2,4,6]);
            spatial=findall(figs(3),'Type','line');
            test.verifyEqual(spatial.YData,[5,2]);
            % Injection/storage boundaries are derived from supplied times.
            boundaries=findall(figs(2),'Type','constantline');
            test.verifyEqual(sort([boundaries.Value]),[2,4]);
        end
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
