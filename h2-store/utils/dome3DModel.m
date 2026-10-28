%DOME3DMODEL Build and display the dome aquifer geological layers.
% Leaves G and the five layer masks in the caller workspace.

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}
mrstModule add deckformat vemmech;
[G, layers] = makeDomeAquiferGrid();
underrock = layers.underrock;
bedrock = layers.bedrock;
toprock = layers.toprock;
caprock = layers.caprock;
aquifer = layers.aquifer;

%% Visualize geological layers with color coding
yd = 2500;
plotGrid(G, caprock & G.cells.centroids(:,2) < yd, 'FaceColor', 'b');
plotGrid(G, bedrock & G.cells.centroids(:,2) < yd, 'FaceColor', 'r');
plotGrid(G, underrock & G.cells.centroids(:,2) < yd, 'FaceColor', 'g');
plotGrid(G, toprock & G.cells.centroids(:,2) < yd, 'FaceColor', 'm');
plotGrid(G, aquifer & G.cells.centroids(:,2) < yd);
title('Geological Layers of the Dome Aquifer');
view(0, 180);
