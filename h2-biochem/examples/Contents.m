% H2sim biochemistry examples.
%
% Run startupH2sim from the toolbox root before using these examples. All
% selected examples run serially by default. PHREEQC cases additionally need
% native IPhreeqc on Linux or registered IPhreeqcCOM on Windows.
%
% Introductory and no-PHREEQC examples
%   simple1DBacterialExampleMetacet        - 1D microbial growth and bio-clogging.
%   exampleCompositionalBacterial2DThreeReactions - Five-cycle microbial/abiotic comparison.
%   exampleH2BrineSolubilityStudy          - Hydrogen-brine thermodynamics; bundled data.
%
% PHREEQC examples
%   exampleCompositionalBacterial1DPhreeqcMinerals - Four rock/chemistry configurations.
%   exampleSequentialBiochemistryPhreeqc1D - Full 250-day multirate storage cycle.
%   runPhreeqcValidation                  - 20-cell storage cycle; optional reference.
%   runThreeBackendComparison             - Three included chemistry formulations.
%   exampleCompositionalBacterial2DPhreeqcMinerals - Advanced 2D setup; one cycle by default.
%
% For a short dependency check use maximumFlowSteps in the mineral or
% multirate example, or totalDays=2 in runPhreeqcValidation. A short run does
% not reproduce the full-cycle figures or establish numerical convergence.
%
% Advanced studies
%   runMolecularDiffusionDemonstration     - Molecular diffusion on/off comparison.
%   runOneDTransportRegimeStudy            - Transport and microbial motility regimes.
%   runTransportEffectsSensitivity        - Transport and clogging sensitivity.
%
% Developer tools (not introductory examples)
%   benchmarkSequentialPhreeqcVolumeFlash - Pressure-root timing comparison.
%   profilePhreeqcWorkflows               - Chemistry batching and reflash profiling.
%   reportMultirateDiagnostics            - Saved-result diagnostics with coverage status.
%   printSeqDiag                          - Compatibility script; requires summary.
%
% Local paper_2026 drivers reproduce specific publication configurations;
% the folder also contains experiments and verification tools. Directory
% membership alone does not mean a case was included in the manuscript.
% Archived and older 3D cases are under research/biochemistry, outside the
% runtime module. Add the selected study folder explicitly to inspect them.
% Early PVT/black-oil comparison prototypes are in research/h2store.
% Website notebooks distinguish setup checks, tutorials and saved-result plots.

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
