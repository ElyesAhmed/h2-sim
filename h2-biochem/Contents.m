% H2sim biochemistry and reactive hydrogen storage.
%
% Initialization
%   startupH2sim                          - Initialize this toolbox and dependencies.
%
% Models
%   BiochemistryModel                     - Compositional flow and microbial reactions.
%   BiochemistryPhreeqcModel              - Optional sequential geochemical coupling.
%   SequentialBiochemistryPhreeqcModel     - Coarse flow with local reaction substeps.
%
% Examples
%   simple1DBacterialExampleMetacet        - Introductory 1D microbial storage.
%   exampleCompositionalBacterial2DThreeReactions - 2D storage with MET, ACE and SRB.
%   exampleCompositionalBacterial1DPhreeqcMinerals - Short mineral-coupling check.
%   exampleSequentialBiochemistryPhreeqc1D - Multirate storage-cycle example.
%   runPhreeqcValidation                  - Numerical comparison; external reference optional.
%   exampleH2BrineSolubilityStudy          - Phase partitioning and salting-out.
%
% Diagnostics and verification
%   collectPhreeqcValidationDiagnostics   - Consumption and chemistry diagnostics.
%   checkPhreeqcElementBalance            - Record and warn on elemental audit failures.
%
% See examples/Contents.m for dependencies and developer/research classifications.
% Initialize with startupH2sim; MRST's separate h2-biochem is not this module.

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
