function style = h2simStoragePlotStyle(ax)
    % H2SIMSTORAGEPLOTSTYLE Shared colours and axes for storage presentations.
    %
    % SYNOPSIS:
    %   style = h2simStoragePlotStyle()
    %   style = h2simStoragePlotStyle(ax)
    %
    % Returns background, injection, withdrawal, text and saturation colours.
    % With an axes handle, applies the dark animation style. Static figures
    % use a white background and the same operating and saturation colours.
    style.background = [0.025, 0.055, 0.1];
    style.injection = [0.4, 0.9, 0.9];
    style.withdrawal = [1, 0.65, 0.25];
    style.figureTeal = [0.02, 0.48, 0.49];
    style.figureOrange = [0.85, 0.36, 0.12];
    style.text = [0.7, 0.85, 0.95];
    anchors = [0.12, 0.22, 0.35; 0.08, 0.48, 0.65; ...
        0.15, 0.75, 0.62; 0.85, 0.88, 0.3; 1, 0.65, 0.18];
    style.saturation = interp1(linspace(0, 1, size(anchors, 1)), ...
        anchors, linspace(0, 1, 256));
    if nargin > 0
        set(ax, 'Color', style.background, 'XColor', 'w', 'YColor', 'w', ...
            'ZColor', 'w', 'FontSize', 10, 'Box', 'off');
        ax.Title.Color = 'w';
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
