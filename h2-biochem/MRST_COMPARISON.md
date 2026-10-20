# H2sim biochemistry compared with MRST

Baseline: [MRST `fa4ff98c78a2`](https://github.com/SINTEF-AppliedCompSci/MRST/tree/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem).

This inventory covers tracked files under `h2-biochem`, excluding these
generated audit files. Relocated MATLAB examples
are matched by basename. Modified files include code and documentation changes;
line counts compare the files before this audit updates their notices.

New MATLAB files receive H2sim 2026 notices and retain GPL terms. Existing
MRST files keep their attribution with existing SINTEF end years updated to 2026.
For new files with substantial matching code elsewhere in MRST, the existing
notices are retained alongside the H2sim notice. Similarity candidates are
evidence of possible derivation, rather than proof of independent authorship.
Database, document and binary-asset provenance is unchanged.

## Summary

- modified: 20
- new: 142
- relocated-modified: 6
- unchanged: 4

## File inventory

| H2sim path (relative to this folder) | Classification | MRST counterpart / possible source | Lines added / removed | Notice |
| --- | --- | --- | --- | --- |
| [.gitignore](.gitignore) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [README.md](README.md) | modified (content) | [modules/h2-biochem/README.md](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/README.md) | +177 / -1 | Data, documentation or binary asset: preserve existing provenance |
| [database/README.md](database/README.md) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [database/h2_biogeochemistry.dat](database/h2_biogeochemistry.dat) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/1D_validation/benchmarkSequentialPhreeqcVolumeFlash.m](examples/1D_validation/benchmarkSequentialPhreeqcVolumeFlash.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/1D_validation/exampleCompositionalPhreeqcValidation.m](examples/1D_validation/exampleCompositionalPhreeqcValidation.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/1D_validation/exampleSequentialBiochemistryPhreeqc1D.m](examples/1D_validation/exampleSequentialBiochemistryPhreeqc1D.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/1D_validation/notebooks/simple1DBacterialExampleMetacet.ipynb](examples/1D_validation/notebooks/simple1DBacterialExampleMetacet.ipynb) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/1D_validation/notebooks/simple1DBacterialExampleMetacet.mlx](examples/1D_validation/notebooks/simple1DBacterialExampleMetacet.mlx) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/1D_validation/printSeqDiag.m](examples/1D_validation/printSeqDiag.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/1D_validation/profilePhreeqcWorkflows.m](examples/1D_validation/profilePhreeqcWorkflows.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/1D_validation/runPhreeqcValidation.m](examples/1D_validation/runPhreeqcValidation.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/1D_validation/runThreeBackendComparison.m](examples/1D_validation/runThreeBackendComparison.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/1D_validation/simple1DBacterialExample.m](examples/1D_validation/simple1DBacterialExample.m) | relocated-modified (content) | [modules/h2-biochem/examples/simple1DBacterialExample.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/examples/simple1DBacterialExample.m) | +10 / -7 | Retain original attribution; update existing SINTEF end year to 2026 |
| [examples/1D_validation/simple1DBacterialExampleMetacet.m](examples/1D_validation/simple1DBacterialExampleMetacet.m) | new (new) | [modules/h2-biochem/examples/simple1DBacterialExample.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/examples/simple1DBacterialExample.m) | — | Add H2sim 2026; retain existing notices (possible MRST-derived code) |
| [examples/1D_validation/testAllDiffusionEffects.m](examples/1D_validation/testAllDiffusionEffects.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/2D_experiments/TestCompositionalBacterial2DWithMolecularDiff.m](examples/2D_experiments/TestCompositionalBacterial2DWithMolecularDiff.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/2D_experiments/exampleBlackoilVsCompositional.m](examples/2D_experiments/exampleBlackoilVsCompositional.m) | relocated-modified (content) | [modules/h2-biochem/examples/exampleBlackoilVsCompositional.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/examples/exampleBlackoilVsCompositional.m) | +6 / -4 | Retain original attribution; update existing SINTEF end year to 2026 |
| [examples/2D_experiments/exampleCompositionalBacterial2D.m](examples/2D_experiments/exampleCompositionalBacterial2D.m) | relocated-modified (content) | [modules/h2-biochem/examples/exampleCompositionalBacterial2D.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/examples/exampleCompositionalBacterial2D.m) | +13 / -16 | Retain original attribution; update existing SINTEF end year to 2026 |
| [examples/2D_experiments/exampleCompositionalBacterial2DThreeReactions.m](examples/2D_experiments/exampleCompositionalBacterial2DThreeReactions.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/2D_experiments/figures/H2_cumulative_loss_spatial.eps](examples/2D_experiments/figures/H2_cumulative_loss_spatial.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/H2_cumulative_loss_spatial.fig](examples/2D_experiments/figures/H2_cumulative_loss_spatial.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/H2_cumulative_loss_spatial_WithClog.fig](examples/2D_experiments/figures/H2_cumulative_loss_spatial_WithClog.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/H2_cumulative_loss_three_bacteria.eps](examples/2D_experiments/figures/H2_cumulative_loss_three_bacteria.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/H2_loss_spatial_three_bacteria_WithClog.eps](examples/2D_experiments/figures/H2_loss_spatial_three_bacteria_WithClog.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/H2_loss_three_bacteria.fig](examples/2D_experiments/figures/H2_loss_three_bacteria.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/H2_loss_three_bacteria_WithClog.eps](examples/2D_experiments/figures/H2_loss_three_bacteria_WithClog.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/H2_loss_three_bacteria_WithClog.fig](examples/2D_experiments/figures/H2_loss_three_bacteria_WithClog.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/threeReactions_2D_rock_properties.eps](examples/2D_experiments/figures/threeReactions_2D_rock_properties.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/well_C1_three_bacteria.eps](examples/2D_experiments/figures/well_C1_three_bacteria.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/well_CO2_three_bacteria.eps](examples/2D_experiments/figures/well_CO2_three_bacteria.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/well_H2_three_bacteria.eps](examples/2D_experiments/figures/well_H2_three_bacteria.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/welll_C1_three_bacteria.fig](examples/2D_experiments/figures/welll_C1_three_bacteria.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/welll_CO2_three_bacteria.fig](examples/2D_experiments/figures/welll_CO2_three_bacteria.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/welll_H2_three_bacteria.fig](examples/2D_experiments/figures/welll_H2_three_bacteria.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/welll_bhp_three_bacteria.eps](examples/2D_experiments/figures/welll_bhp_three_bacteria.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/2D_experiments/figures/welll_bhp_three_bacteria.fig](examples/2D_experiments/figures/welll_bhp_three_bacteria.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/3D_experiments/exampleCompositionalBacterial3DbenchmarkEAGE2023.m](examples/3D_experiments/exampleCompositionalBacterial3DbenchmarkEAGE2023.m) | relocated-modified (content) | [modules/h2-biochem/examples/exampleCompositionalBacterial3DbenchmarkEAGE2023.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/examples/exampleCompositionalBacterial3DbenchmarkEAGE2023.m) | +19 / -12 | Retain original attribution; update existing SINTEF end year to 2026 |
| [examples/3D_experiments/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m](examples/3D_experiments/exampleCompositionalBacterial3DbenchmarkEAGE2023twobacts.m) | new (new) | [modules/h2-biochem/examples/exampleCompositionalBacterial3DbenchmarkEAGE2023.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/examples/exampleCompositionalBacterial3DbenchmarkEAGE2023.m) | — | Add H2sim 2026; retain existing notices (possible MRST-derived code) |
| [examples/3D_experiments/exampleCompositionalBacterial3DbenchmarkThreeReactions.m](examples/3D_experiments/exampleCompositionalBacterial3DbenchmarkThreeReactions.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/3D_experiments/figures/threeReactions_3D_rock_properties.eps](examples/3D_experiments/figures/threeReactions_3D_rock_properties.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/figures/.~lock.sensitivity_originalH2_biochem_delta_H2_loss.eps#](examples/Sensitivity_analysis/figures/.~lock.sensitivity_originalH2_biochem_delta_H2_loss.eps#) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/figures/regime_1D_H2_loss_over_time.eps](examples/Sensitivity_analysis/figures/regime_1D_H2_loss_over_time.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/figures/regime_1D_delta_H2_loss.eps](examples/Sensitivity_analysis/figures/regime_1D_delta_H2_loss.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/figures/regime_1D_dimensionless_numbers.eps](examples/Sensitivity_analysis/figures/regime_1D_dimensionless_numbers.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/figures/regime_1D_spatial_H2_consumption.eps](examples/Sensitivity_analysis/figures/regime_1D_spatial_H2_consumption.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/figures/sensitivity_originalH2_biochem_H2_loss_over_time.eps](examples/Sensitivity_analysis/figures/sensitivity_originalH2_biochem_H2_loss_over_time.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/figures/sensitivity_originalH2_biochem_delta_H2_loss.eps](examples/Sensitivity_analysis/figures/sensitivity_originalH2_biochem_delta_H2_loss.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/figures/sensitivity_originalH2_biochem_spatial_H2_consumption.eps](examples/Sensitivity_analysis/figures/sensitivity_originalH2_biochem_spatial_H2_consumption.eps) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [examples/Sensitivity_analysis/runMolecularDiffusionDemonstration.m](examples/Sensitivity_analysis/runMolecularDiffusionDemonstration.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/Sensitivity_analysis/runOneDTransportRegimeStudy.m](examples/Sensitivity_analysis/runOneDTransportRegimeStudy.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/Sensitivity_analysis/runTransportEffectsSensitivity.m](examples/Sensitivity_analysis/runTransportEffectsSensitivity.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/experimentals/exampleCompositionalBacterial1DPhreeqcMinerals.m](examples/experimentals/exampleCompositionalBacterial1DPhreeqcMinerals.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/experimentals/exampleCompositionalBacterial2DPhreeqcMinerals.m](examples/experimentals/exampleCompositionalBacterial2DPhreeqcMinerals.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/experimentals/exampleCompositionalBacterial3DBenchmarkFixedPH.m](examples/experimentals/exampleCompositionalBacterial3DBenchmarkFixedPH.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/thermo/exampleH2BrineSolubilityStudy.m](examples/thermo/exampleH2BrineSolubilityStudy.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/thermo/exampleVLECO2H2O.m](examples/thermo/exampleVLECO2H2O.m) | relocated-modified (content) | [modules/h2-biochem/examples/exampleVLECO2H2O.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/examples/exampleVLECO2H2O.m) | +1 / -1 | Retain original attribution; update existing SINTEF end year to 2026 |
| [examples/thermo/exampleVLEH2H2O.m](examples/thermo/exampleVLEH2H2O.m) | relocated-modified (content) | [modules/h2-biochem/examples/exampleVLEH2H2O.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/examples/exampleVLEH2H2O.m) | +1 / -1 | Retain original attribution; update existing SINTEF end year to 2026 |
| [examples/trash/exampleCompositionalBacterial2D_test_bact_diff.m](examples/trash/exampleCompositionalBacterial2D_test_bact_diff.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/trash/exampleCompositionalBacterial2D_test_disp_diff.m](examples/trash/exampleCompositionalBacterial2D_test_disp_diff.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/trash/simple1DBacterialExample_test_bact_diff.m](examples/trash/simple1DBacterialExample_test_bact_diff.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [examples/trash/simple1DBacterialExample_test_disp_diff.m](examples/trash/simple1DBacterialExample_test_disp_diff.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [models/BiochemistryGenericFacilityModel.m](models/BiochemistryGenericFacilityModel.m) | modified (content) | [modules/h2-biochem/models/BiochemistryGenericFacilityModel.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/models/BiochemistryGenericFacilityModel.m) | +184 / -15 | Retain original attribution; update existing SINTEF end year to 2026 |
| [models/BiochemistryModel.m](models/BiochemistryModel.m) | modified (content) | [modules/h2-biochem/models/BiochemistryModel.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/models/BiochemistryModel.m) | +655 / -151 | Retain original attribution; update existing SINTEF end year to 2026 |
| [models/BiochemistryPhreeqcModel.m](models/BiochemistryPhreeqcModel.m) | new (new) | [modules/h2-biochem/models/BiochemistryModel.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/models/BiochemistryModel.m) | — | Add H2sim 2026; retain existing notices (possible MRST-derived code) |
| [models/SequentialBiochemistryPhreeqcModel.m](models/SequentialBiochemistryPhreeqcModel.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [models/TableBioChemMixture.m](models/TableBioChemMixture.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [models/eos/SoreideWhitsonEos.m](models/eos/SoreideWhitsonEos.m) | modified (content) | [modules/h2-biochem/models/eos/SoreideWhitsonEos.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/models/eos/SoreideWhitsonEos.m) | +146 / -35 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/BiochemicalFlowDiscretization.m](statefunctions/BiochemicalFlowDiscretization.m) | modified (content) | [modules/h2-biochem/statefunctions/BiochemicalFlowDiscretization.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/BiochemicalFlowDiscretization.m) | +132 / -15 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flowprops/AqueousTracerMass.m](statefunctions/flowprops/AqueousTracerMass.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flowprops/BactConvertionRate.m](statefunctions/flowprops/BactConvertionRate.m) | modified (content) | [modules/h2-biochem/statefunctions/flowprops/BactConvertionRate.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/flowprops/BactConvertionRate.m) | +181 / -75 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flowprops/BacterialMass.m](statefunctions/flowprops/BacterialMass.m) | modified (content) | [modules/h2-biochem/statefunctions/flowprops/BacterialMass.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/flowprops/BacterialMass.m) | +32 / -16 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flowprops/CarbonLimitedGrowthRate.m](statefunctions/flowprops/CarbonLimitedGrowthRate.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flowprops/DecayBactRateSRC.m](statefunctions/flowprops/DecayBactRateSRC.m) | modified (content) | [modules/h2-biochem/statefunctions/flowprops/DecayBactRateSRC.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/flowprops/DecayBactRateSRC.m) | +45 / -41 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flowprops/GrowthBactRateSRC.m](statefunctions/flowprops/GrowthBactRateSRC.m) | modified (content) | [modules/h2-biochem/statefunctions/flowprops/GrowthBactRateSRC.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/flowprops/GrowthBactRateSRC.m) | +235 / -97 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flowprops/SRBTracerConvRate.m](statefunctions/flowprops/SRBTracerConvRate.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/BactPermeability.m](statefunctions/flux/BactPermeability.m) | modified (content) | [modules/h2-biochem/statefunctions/flux/BactPermeability.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/flux/BactPermeability.m) | +9 / -4 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flux/BactPorosity.m](statefunctions/flux/BactPorosity.m) | modified (content) | [modules/h2-biochem/statefunctions/flux/BactPorosity.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/flux/BactPorosity.m) | +8 / -3 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flux/ChemotaxisBactFlux.m](statefunctions/flux/ChemotaxisBactFlux.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/ChemotaxisTransmissibility.m](statefunctions/flux/ChemotaxisTransmissibility.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/ComponentPhaseDispFlux.m](statefunctions/flux/ComponentPhaseDispFlux.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/ComponentTotalDispFlux.m](statefunctions/flux/ComponentTotalDispFlux.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/ComponentTotalFluxForBio.m](statefunctions/flux/ComponentTotalFluxForBio.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/DiffusiveBactFlux.m](statefunctions/flux/DiffusiveBactFlux.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/DiffusiveTracerFlux.m](statefunctions/flux/DiffusiveTracerFlux.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/DispersiveDiffusivity.m](statefunctions/flux/DispersiveDiffusivity.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/DispersiveTransmissibility.m](statefunctions/flux/DispersiveTransmissibility.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/DynamicFlowPoreVolume.m](statefunctions/flux/DynamicFlowPoreVolume.m) | modified (content) | [modules/h2-biochem/statefunctions/flux/DynamicFlowPoreVolume.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/flux/DynamicFlowPoreVolume.m) | +2 / -1 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flux/DynamicFlowTransmissibility.m](statefunctions/flux/DynamicFlowTransmissibility.m) | modified (content) | [modules/h2-biochem/statefunctions/flux/DynamicFlowTransmissibility.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/statefunctions/flux/DynamicFlowTransmissibility.m) | +32 / -3 | Retain original attribution; update existing SINTEF end year to 2026 |
| [statefunctions/flux/MicrobialChemotaxis.m](statefunctions/flux/MicrobialChemotaxis.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/MicrobialDiffusivity.m](statefunctions/flux/MicrobialDiffusivity.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/MicrobialTransmissibility.m](statefunctions/flux/MicrobialTransmissibility.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/PorosityFromRock.m](statefunctions/flux/PorosityFromRock.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/TracerDiffusivity.m](statefunctions/flux/TracerDiffusivity.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [statefunctions/flux/TracerTransmissibility.m](statefunctions/flux/TracerTransmissibility.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/CompositionalPhreeqcBatchTest.m](tests/CompositionalPhreeqcBatchTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/H2BiochemMixtureTest.m](tests/H2BiochemMixtureTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/H2BiochemParallelTest.m](tests/H2BiochemParallelTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/H2BiochemVolumePressureTest.m](tests/H2BiochemVolumePressureTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/H2simBiochemistryPathTest.m](tests/H2simBiochemistryPathTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/H2simPackedSimulationTest.m](tests/H2simPackedSimulationTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/H2simPhysicalInputsTest.m](tests/H2simPhysicalInputsTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/NativeIPhreeqcTest.m](tests/NativeIPhreeqcTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/PhreeqcMineralRoundoffTest.m](tests/PhreeqcMineralRoundoffTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/PhreeqcPublicationFiguresTest.m](tests/PhreeqcPublicationFiguresTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/PhreeqcValidationDiagnosticsTest.m](tests/PhreeqcValidationDiagnosticsTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/SequentialBiochemistryPhreeqcModelConstructionTest.m](tests/SequentialBiochemistryPhreeqcModelConstructionTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/SequentialBiochemistryPhreeqcModelReferenceTest.m](tests/SequentialBiochemistryPhreeqcModelReferenceTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/SequentialBiochemistryPhreeqcModelStepTest.m](tests/SequentialBiochemistryPhreeqcModelStepTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [tests/SoreideWhitsonPhaseLabelTest.m](tests/SoreideWhitsonPhaseLabelTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/H2simNativeIPhreeqc.m](utils/H2simNativeIPhreeqc.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/addBacterialBC.m](utils/addBacterialBC.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/advanceSequentialBiochemistryLocalReaction.m](utils/advanceSequentialBiochemistryLocalReaction.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/bioChemFluidsStructs.m](utils/bioChemFluidsStructs.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/buildSequentialH2BiochemPhreeqcChemistryFeedback.m](utils/buildSequentialH2BiochemPhreeqcChemistryFeedback.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/checkPhreeqcElementBalance.m](utils/checkPhreeqcElementBalance.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/coarsenScheduleByControl.m](utils/coarsenScheduleByControl.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/computePhreeqcElementInventory.m](utils/computePhreeqcElementInventory.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/convertToSequentialBiochemistryPhreeqcModel.m](utils/convertToSequentialBiochemistryPhreeqcModel.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/copyBiochemistryModelProperties.m](utils/copyBiochemistryModelProperties.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/createCyclicScenario.m](utils/createCyclicScenario.m) | unchanged (unchanged) | [modules/h2-biochem/utils/createCyclicScenario.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/createCyclicScenario.m) | +0 / -0 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/createH2simIPhreeqc.m](utils/createH2simIPhreeqc.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/faceFlux2cellSpeed.m](utils/faceFlux2cellSpeed.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/getBiochemistryEOSComponentMoles.m](utils/getBiochemistryEOSComponentMoles.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/getH2StorageIPhreeqcCOMSelectedOutputValue.m](utils/getH2StorageIPhreeqcCOMSelectedOutputValue.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/h2BiochemCompositionalMixture.m](utils/h2BiochemCompositionalMixture.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/initCompositionalStateBacteria.m](utils/initCompositionalStateBacteria.m) | modified (content) | [modules/h2-biochem/utils/initCompositionalStateBacteria.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/initCompositionalStateBacteria.m) | +0 / -1 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/initializeH2StoragePhreeqcCouplingState.m](utils/initializeH2StoragePhreeqcCouplingState.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/modifyRelPermForResidualSaturations.m](utils/modifyRelPermForResidualSaturations.m) | unchanged (unchanged) | [modules/h2-biochem/utils/modifyRelPermForResidualSaturations.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/modifyRelPermForResidualSaturations.m) | +0 / -0 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/normalizePhreeqcMineralRoundoff.m](utils/normalizePhreeqcMineralRoundoff.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/parseH2StorageIPhreeqcCOMSelectedOutput.m](utils/parseH2StorageIPhreeqcCOMSelectedOutput.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/H2consumptionTest.m](utils/plotfunctions/H2consumptionTest.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/New folder/2D_test/H2_loss_over_dist_inj_3_Bact.fig](utils/plotfunctions/New folder/2D_test/H2_loss_over_dist_inj_3_Bact.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [utils/plotfunctions/New folder/2D_test/H2_loss_over_time_3_Bact.fig](utils/plotfunctions/New folder/2D_test/H2_loss_over_time_3_Bact.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [utils/plotfunctions/New folder/H2_loss_per_distance_inj.fig](utils/plotfunctions/New folder/H2_loss_per_distance_inj.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [utils/plotfunctions/New folder/H2_loss_per_distance_inj_bar_plot.fig](utils/plotfunctions/New folder/H2_loss_per_distance_inj_bar_plot.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [utils/plotfunctions/New folder/H2_loss_per_sandstone.fig](utils/plotfunctions/New folder/H2_loss_per_sandstone.fig) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [utils/plotfunctions/collectPhreeqcValidationDiagnostics.m](utils/plotfunctions/collectPhreeqcValidationDiagnostics.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/computeH2Consumption.m](utils/plotfunctions/computeH2Consumption.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/dimensionlessCellDistance.m](utils/plotfunctions/dimensionlessCellDistance.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/error.inp](utils/plotfunctions/error.inp) | new (new) | — | — | Data, documentation or binary asset: preserve existing provenance |
| [utils/plotfunctions/paperColors.m](utils/plotfunctions/paperColors.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/paperExport.m](utils/plotfunctions/paperExport.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/paperFigure.m](utils/plotfunctions/paperFigure.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/plotBacterialEffects.m](utils/plotfunctions/plotBacterialEffects.m) | modified (content) | [modules/h2-biochem/utils/plotfunctions/plotBacterialEffects.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/plotfunctions/plotBacterialEffects.m) | +39 / -16 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/plotfunctions/plotBenchmarckAEGE2023.m](utils/plotfunctions/plotBenchmarckAEGE2023.m) | unchanged (unchanged) | [modules/h2-biochem/utils/plotfunctions/plotBenchmarckAEGE2023.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/plotfunctions/plotBenchmarckAEGE2023.m) | +0 / -0 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/plotfunctions/plotBenchmarckAEGE2023MetAcet.m](utils/plotfunctions/plotBenchmarckAEGE2023MetAcet.m) | new (new) | [modules/h2-biochem/utils/plotfunctions/plotBenchmarckAEGE2023.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/plotfunctions/plotBenchmarckAEGE2023.m) | — | Add H2sim 2026; retain existing notices (possible MRST-derived code) |
| [utils/plotfunctions/plotComponentComparison.m](utils/plotfunctions/plotComponentComparison.m) | modified (content) | [modules/h2-biochem/utils/plotfunctions/plotComponentComparison.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/plotfunctions/plotComponentComparison.m) | +10 / -7 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/plotfunctions/plotComponentProfiles.m](utils/plotfunctions/plotComponentProfiles.m) | modified (content) | [modules/h2-biochem/utils/plotfunctions/plotComponentProfiles.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/plotfunctions/plotComponentProfiles.m) | +4 / -4 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/plotfunctions/plotCompositionalBacterial2DThreeReactions.m](utils/plotfunctions/plotCompositionalBacterial2DThreeReactions.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/plotCompositionalPhreeqcValidation.m](utils/plotfunctions/plotCompositionalPhreeqcValidation.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/plotEosPRSW.m](utils/plotfunctions/plotEosPRSW.m) | unchanged (unchanged) | [modules/h2-biochem/utils/plotfunctions/plotEosPRSW.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/plotfunctions/plotEosPRSW.m) | +0 / -0 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/plotfunctions/plotH2BrineSolubilityStudy.m](utils/plotfunctions/plotH2BrineSolubilityStudy.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/plotH2Loss.m](utils/plotfunctions/plotH2Loss.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/plotH2LossVsBaseline.m](utils/plotfunctions/plotH2LossVsBaseline.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/plotPhreeqcBackendComparison.m](utils/plotfunctions/plotPhreeqcBackendComparison.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/plotPhreeqcMineralComparison.m](utils/plotfunctions/plotPhreeqcMineralComparison.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/plotPressureAndSaturation.m](utils/plotfunctions/plotPressureAndSaturation.m) | modified (content) | [modules/h2-biochem/utils/plotfunctions/plotPressureAndSaturation.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/plotfunctions/plotPressureAndSaturation.m) | +6 / -6 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/plotfunctions/plotSequentialBiochemistryPhreeqc.m](utils/plotfunctions/plotSequentialBiochemistryPhreeqc.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/plotfunctions/styleAxes.m](utils/plotfunctions/styleAxes.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/resolveH2BiochemParallel.m](utils/resolveH2BiochemParallel.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/runSequentialCompositionalPhreeqcCoupling.m](utils/runSequentialCompositionalPhreeqcCoupling.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/runSequentialH2BiochemPhreeqcEquilibrium.m](utils/runSequentialH2BiochemPhreeqcEquilibrium.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/setupBioCloggingModel.m](utils/setupBioCloggingModel.m) | modified (content) | [modules/h2-biochem/utils/setupBioCloggingModel.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/setupBioCloggingModel.m) | +93 / -51 | Retain original attribution; update existing SINTEF end year to 2026 |
| [utils/setupBioCloggingModel2bacts.m](utils/setupBioCloggingModel2bacts.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/setupH2StorageExample.m](utils/setupH2StorageExample.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/setupH2StorageExampleWithSRB.m](utils/setupH2StorageExampleWithSRB.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/setupH2StorageExampleWithSRB_benchmark.m](utils/setupH2StorageExampleWithSRB_benchmark.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/setupOptimizedLinearSolver.m](utils/setupOptimizedLinearSolver.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/simulateSequentialH2BiochemPhreeqc.m](utils/simulateSequentialH2BiochemPhreeqc.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/solveH2BiochemVolumePressure.m](utils/solveH2BiochemVolumePressure.m) | new (new) | — | — | H2sim 2026; GPL terms retained |
| [utils/validateCompositionalForcesSW.m](utils/validateCompositionalForcesSW.m) | modified (content) | [modules/h2-biochem/utils/validateCompositionalForcesSW.m](https://github.com/SINTEF-AppliedCompSci/MRST/blob/fa4ff98c78a217d527ae0ec08ecd90c56f66809b/modules/h2-biochem/utils/validateCompositionalForcesSW.m) | +19 / -0 | Retain original attribution; update existing SINTEF end year to 2026 |

## Files present only in the upstream module

- `modules/h2-biochem/statefunctions/flux/BactTransmissibility.m`

## Reproduce

```bash
python3 tools/audit_mrst_biochemistry.py --mrst-root /path/to/MRST \
    --report h2-biochem/MRST_COMPARISON.md --json h2-biochem/mrst_comparison.json
```

Check out the baseline revision in that MRST checkout first. Add
`--update-copyright` only when applying the audited notice policy.
