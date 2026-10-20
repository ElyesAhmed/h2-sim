function speed = faceFlux2cellSpeed(G, faceFlux)
% Compute cell-centered speed from face fluxes without forming an AD matrix.

if ~isfield(G.cells, 'centroids')
    G = computeGeometry(G);
end

[cellNo, cellFaces] = getCellNoFaces(G);
neighbors = getNeighbourship(G, 'Topological', true);
signs = 2*(neighbors(cellFaces(:, 1), 1) == cellNo) - 1;
cellFlux = signs.*faceFlux(cellFaces);

offsets = G.faces.centroids(cellFaces, :) - G.cells.centroids(cellNo, :);
faceToCell = sparse(cellNo, 1:numel(cellNo), 1, ...
    G.cells.num, numel(cellNo));

speedSquared = 0;
for d = 1:size(offsets, 2)
    velocity = faceToCell*(cellFlux.*offsets(:, d));
    velocity = velocity./G.cells.volumes;
    speedSquared = speedSquared + velocity.^2;
end
speed = speedSquared.^0.5;
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
