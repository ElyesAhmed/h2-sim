classdef H2StoreWellPlacementTest < matlab.unittest.TestCase
    % H2STOREWELLPLACEMENTTEST Aquifer completion window and coarse-grid fallback.
    methods (Test)

        function geometricMatches(test)
            [G, rock] = makeInputs([25, 28; 25.05, 26; 24.5, 28.5; 25, 30]);
            test.verifyEqual(findAquifer2DWellCells(G, rock), [1; 2]);
        end

        function completionWindow(test)
            [G, rock] = makeInputs([25, 25; 25, 29.5; 25, -28; 25.2, 28]);
            test.verifyEqual(findAquifer2DWellCells(G, rock), 3);
        end

        function geometricMatchesTakePriority(test)
            [G, rock] = makeInputs([25, 28; 24.5, 28.5]);
            rock.poro(1) = 0.1;
            test.verifyEqual(findAquifer2DWellCells(G, rock), 1);
        end

        function nearestReservoirCell(test)
            [G, rock] = makeInputs([25.2, 28.5; 26, 28.5; 24, 27]);
            rock.poro = [0.1; 0.25; 0.25];
            test.verifyEqual(findAquifer2DWellCells(G, rock), 2);
        end

        function distanceTie(test)
            [G, rock] = makeInputs([24, 28.5; 26, 28.5]);
            test.verifyEqual(findAquifer2DWellCells(G, rock), 1);
        end

        function noEligibleReservoir(test)
            [G, rock] = makeInputs([24, 28; 26, 28]);
            rock.poro = [0.05; 0.1];
            test.verifyError(@() findAquifer2DWellCells(G, rock), ...
                'h2sim:h2store:NoWellCells');
        end

        function emptyGrid(test)
            [G, rock] = makeInputs(zeros(0, 2));
            test.verifyError(@() findAquifer2DWellCells(G, rock), ...
                'h2sim:h2store:NoWellCells');
        end

    end
end

function [G, rock] = makeInputs(coordinates)
    G.cells.centroids = coordinates;
    rock.poro = repmat(0.25, size(coordinates, 1), 1);
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
