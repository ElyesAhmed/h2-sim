# Reviewed MATLAB Code Analyzer findings

Snapshot from MATLAB R2026a Update 5 for the consolidated repository cleanup.
All 230 owned MATLAB files were checked; findings fell from 85 to 37.
Pinned submodules are excluded. No new suppressions were added.

These are analyzer findings, not a list of confirmed bugs. Local model regressions
and unit tests provide separate evidence; full paper simulations were not rerun.

## Review decisions

| ID | Count | Decision |
| --- | ---: | --- |
| `AGROW` | 5 | Small assembly and research loops retain their allocation behavior. EOS assembly can contain AD values; allocation changes need targeted numerical checks. |
| `CAXIS` | 5 | Existing color-limit calls are retained for compatibility, including Octave workflows. |
| `FILEATTRIB` | 1 | The existing filesystem-permission API is retained for older MATLAB installations. |
| `GVMIS` | 1 | The global registry is part of the existing MRST module integration. |
| `INUSD` | 4 | These four arguments are consumed through an evalc expression in a warning-capture test. Their names must be retained. |
| `ISCL` | 4 | Scalar predicates on model/derivative inputs are retained in this formatting pass. |
| `LAXES` | 4 | MRST plotting calls use the current axes. Axes selection is retained with that plotting interface. |
| `NASGU` | 5 | Two assignments sit beside a commented scientific audit; the other three are in a retained 3D research script. Revisiting the audit or research outputs requires a numerical review. |
| `PRTPT` | 2 | Existing vector-export flags are retained for compatibility with supported installations. |
| `SAGROW` | 1 | A diagnostic plotting script grows its result structure. It is retained for a separate performance review. |
| `UNRCH` | 5 | Editable example flags select branches at script scope. Alternative configurations are retained. |

## Locations

Paths and line numbers refer to this cleanup snapshot. Regenerate the audit after
later source changes rather than treating these counts as permanent thresholds.

| File | Line | ID |
| --- | ---: | --- |
| [h2-biochem/examples/1D_validation/exampleCompositionalPhreeqcValidation.m](../h2-biochem/examples/1D_validation/exampleCompositionalPhreeqcValidation.m#L156) | 156 | `FILEATTRIB` |
| [h2-biochem/examples/1D_validation/testAllDiffusionEffects.m](../h2-biochem/examples/1D_validation/testAllDiffusionEffects.m#L220) | 220 | `AGROW` |
| [h2-biochem/examples/2D_experiments/exampleCompositionalBacterial2D.m](../h2-biochem/examples/2D_experiments/exampleCompositionalBacterial2D.m#L75) | 75 | `UNRCH` |
| [h2-biochem/examples/Sensitivity_analysis/runTransportEffectsSensitivity.m](../h2-biochem/examples/Sensitivity_analysis/runTransportEffectsSensitivity.m#L392) | 392 | `LAXES` |
| [h2-biochem/examples/Sensitivity_analysis/runTransportEffectsSensitivity.m](../h2-biochem/examples/Sensitivity_analysis/runTransportEffectsSensitivity.m#L413) | 413 | `LAXES` |
| [h2-biochem/examples/Sensitivity_analysis/runTransportEffectsSensitivity.m](../h2-biochem/examples/Sensitivity_analysis/runTransportEffectsSensitivity.m#L430) | 430 | `LAXES` |
| [h2-biochem/models/BiochemistryModel.m](../h2-biochem/models/BiochemistryModel.m#L499) | 499 | `ISCL` |
| [h2-biochem/models/BiochemistryPhreeqcModel.m](../h2-biochem/models/BiochemistryPhreeqcModel.m#L585) | 585 | `ISCL` |
| [h2-biochem/models/eos/SoreideWhitsonEos.m](../h2-biochem/models/eos/SoreideWhitsonEos.m#L209) | 209 | `AGROW` |
| [h2-biochem/statefunctions/flowprops/BacterialMass.m](../h2-biochem/statefunctions/flowprops/BacterialMass.m#L117) | 117 | `ISCL` |
| [h2-biochem/utils/plotfunctions/H2consumptionTest.m](../h2-biochem/utils/plotfunctions/H2consumptionTest.m#L59) | 59 | `SAGROW` |
| [h2-biochem/utils/plotfunctions/paperExport.m](../h2-biochem/utils/plotfunctions/paperExport.m#L69) | 69 | `PRTPT` |
| [h2-biochem/utils/plotfunctions/paperExport.m](../h2-biochem/utils/plotfunctions/paperExport.m#L76) | 76 | `PRTPT` |
| [h2-biochem/utils/plotfunctions/plotCompositionalBacterial2DThreeReactions.m](../h2-biochem/utils/plotfunctions/plotCompositionalBacterial2DThreeReactions.m#L31) | 31 | `CAXIS` |
| [h2-biochem/utils/plotfunctions/plotCompositionalBacterial2DThreeReactions.m](../h2-biochem/utils/plotfunctions/plotCompositionalBacterial2DThreeReactions.m#L131) | 131 | `CAXIS` |
| [h2-biochem/utils/plotfunctions/plotCompositionalBacterial2DThreeReactions.m](../h2-biochem/utils/plotfunctions/plotCompositionalBacterial2DThreeReactions.m#L159) | 159 | `LAXES` |
| [h2-biochem/utils/plotfunctions/plotCompositionalPhreeqcValidation.m](../h2-biochem/utils/plotfunctions/plotCompositionalPhreeqcValidation.m#L183) | 183 | `CAXIS` |
| [h2-biochem/utils/runSequentialH2BiochemPhreeqcEquilibrium.m](../h2-biochem/utils/runSequentialH2BiochemPhreeqcEquilibrium.m#L493) | 493 | `NASGU` |
| [h2-biochem/utils/runSequentialH2BiochemPhreeqcEquilibrium.m](../h2-biochem/utils/runSequentialH2BiochemPhreeqcEquilibrium.m#L494) | 494 | `NASGU` |
| [h2-biochem/utils/setupBioCloggingModel.m](../h2-biochem/utils/setupBioCloggingModel.m#L32) | 32 | `ISCL` |
| [h2-store/examples/exampleH2BrineSolubility.m](../h2-store/examples/exampleH2BrineSolubility.m#L320) | 320 | `UNRCH` |
| [h2-store/examples/examplePVTGenerationH2Brine.m](../h2-store/examples/examplePVTGenerationH2Brine.m#L84) | 84 | `UNRCH` |
| [h2-store/examples/examplePVTGenerationH2Brine.m](../h2-store/examples/examplePVTGenerationH2Brine.m#L118) | 118 | `UNRCH` |
| [h2-store/utils/plotBlackOilAquifer2D.m](../h2-store/utils/plotBlackOilAquifer2D.m#L26) | 26 | `CAXIS` |
| [research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m](../research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m#L220) | 220 | `NASGU` |
| [research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m](../research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m#L221) | 221 | `NASGU` |
| [research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m](../research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m#L231) | 231 | `NASGU` |
| [research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m](../research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m#L236) | 236 | `AGROW` |
| [research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m](../research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m#L239) | 239 | `AGROW` |
| [research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m](../research/biochemistry/3d/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m#L242) | 242 | `AGROW` |
| [research/biochemistry/archive/legacy-examples/simple1DBacterialExample_test_bact_diff.m](../research/biochemistry/archive/legacy-examples/simple1DBacterialExample_test_bact_diff.m#L145) | 145 | `UNRCH` |
| [research/h2store/prototypes/eggUHSExample.m](../research/h2store/prototypes/eggUHSExample.m#L81) | 81 | `CAXIS` |
| [tests/biochemistry/PhreeqcElementBalanceWarningTest.m](../tests/biochemistry/PhreeqcElementBalanceWarningTest.m#L129) | 129 | `INUSD` |
| [tests/biochemistry/PhreeqcElementBalanceWarningTest.m](../tests/biochemistry/PhreeqcElementBalanceWarningTest.m#L129) | 129 | `INUSD` |
| [tests/biochemistry/PhreeqcElementBalanceWarningTest.m](../tests/biochemistry/PhreeqcElementBalanceWarningTest.m#L129) | 129 | `INUSD` |
| [tests/biochemistry/PhreeqcElementBalanceWarningTest.m](../tests/biochemistry/PhreeqcElementBalanceWarningTest.m#L129) | 129 | `INUSD` |
| [utils/activateH2simAMGCL.m](../utils/activateH2simAMGCL.m#L13) | 13 | `GVMIS` |
