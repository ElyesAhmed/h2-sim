# H2sim biochemistry and reactive hydrogen storage

H2sim couples MRST compositional flow with microbial reactions and optional
PHREEQC aqueous/mineral chemistry for hydrogen storage in porous reservoirs.

Initialize this standalone toolbox with `startupH2sim` from the H2sim root.
Do not initialize it with `mrstModule add h2-biochem`: MRST ships a separate
module under that name. H2sim registers its implementation as
`h2sim-biochem` and removes the upstream name and paths from the current
session to prevent mixed implementations.

[File-by-file comparison with upstream MRST](MRST_COMPARISON.md) records new,
modified, and relocated files, source attribution, and the exact baseline
revision. Existing MRST notices are retained on inherited files; new H2sim
source files use H2sim 2026 notices with GPL terms preserved.

## Example catalogue

Open [Contents.m](Contents.m) for model entry points and
[examples/Contents.m](examples/Contents.m) for the example index. Existing
public function names remain available.

| Purpose | Entry point | Dependencies and scope |
|---|---|---|
| Introductory microbial storage | `simple1DBacterialExampleMetacet` | MRST; no PHREEQC |
| Three-reaction 2D storage | `exampleCompositionalBacterial2DThreeReactions` | Larger cyclic case; no PHREEQC |
| Phase partitioning and salting-out | `exampleH2BrineSolubilityStudy` | MRST and bundled reference data; no live PC-SAFT solver |
| Mineral-coupling setup check | `exampleCompositionalBacterial1DPhreeqcMinerals` | PHREEQC; use `gridCells=4`, `maximumFlowSteps=2` for a short check |
| Multirate reactions | `exampleSequentialBiochemistryPhreeqc1D` | PHREEQC; `maximumFlowSteps` limits the full 250-day default |
| Storage-cycle numerical comparison | `runPhreeqcValidation` | PHREEQC; H2sim-only by default, external reference opt-in |
| Three chemistry formulations | `runThreeBackendComparison` | Advanced included-model comparison; PHREEQC required |

A setup check verifies basic operation. A tutorial explains a chosen workflow.
Exact reproduction requires the displayed result's grid, schedule, kinetics,
backend, solver options and source dataset; a short or default example may use
another configuration. Saved-result plots use identified archived data without
rerunning the simulation. See the website notebooks and provenance records for
these distinctions, including normalization and conservation-audit limitations.

`benchmarkSequentialPhreeqcVolumeFlash` and `profilePhreeqcWorkflows` are
developer performance tools. Local `paper_2026` includes publication drivers,
tests and exploratory studies; not every file there is a manuscript case.
The older transport and 3D examples remain available while their configuration
and documentation are reviewed. They are not deleted solely because a current
website or manuscript does not use them.

## Overview

This module extends MRST's capabilities by integrating a bio-chemistry model with the compositional simulator, specifically designed for hydrogen storage applications. It implements the Soreide-Whitson (SW) equation of state fitted to experimental data and enables simulation of microbial activity affecting hydrogen storage operations.

### Key Features

- **Compositional Modeling**: Full compositional simulation for H₂O-H₂-CO₂-CH₄-N₂ mixtures
- **Bio-Chemistry Integration**: Microbial growth and methanogenesis reactions
- **Equation of State**: Soreide-Whitson EoS fitted to experimental data
- **Bacterial Effects**: Simulation of hydrogen loss due to microbial activity

### Optional PHREEQC backends

`setupH2StorageExampleWithSRB_benchmark` supports exactly two PHREEQC backends. Both use native PhreeqcMatlab IPhreeqc on Linux, or a registered
`IPhreeqcCOM.Object` (configured with `phreeqcComProgId`) on Windows, and require an explicit absolute `phreeqcDatabaseFile` path to
`h2_biogeochemistry.dat`. The database is bundled at
[`h2-biochem/database/h2_biogeochemistry.dat`](database/h2_biogeochemistry.dat).
The database is a renamed, unmodified copy from [UGFACT](https://github.com/ahmadrezashojaee/UGFACT); [source revision and checksum](database/README.md) are recorded alongside it.
After running `startupH2sim`, `which('h2_biogeochemistry.dat')` resolves it automatically.

Set `phreeqcBackend='sequential-compositional-phreeqc'` with `phreeqcTimestepCoupling=true` to run the post-convergence
compositional kinetics/chemistry split.

The COM split carries separate PHREEQC MET/ACE/SRB biomass (`N0=1e9`, `Nmax=1e13` cells/kg water) and disables MRST's
implicit microbial reaction sources to avoid double counting; aqueous tracer transport (SO4, HS, HCO3, Ca, Mg) remains
active. `bactDiffusion` and `chemotaxisEffect` are rejected for this backend: PHREEQC integrates only local per-cell
kinetics with no notion of spatial bacterial transport, so `nbact` cannot be diffused or chemotaxis-moved independently
of the biomass PHREEQC is actually growing.  Since its reaction source is also zero here, MRST does not assemble
`nbact`'s mass-balance equation at all for this backend (it would be a pure no-op every step); `nbact` is still carried
as a state field, and `PsiGrowthRate`/`CarbonLimitedGrowthRate`/`BacterialMass` remain available as diagnostic-only
outputs. It maps the prescribed selected-output schema back to tracers, minerals, and EOS inventories before
reflashing. This sequential coupling is not claimed to exactly reproduce any paper or external benchmark.

The compositional backend records per-cell H, C, S, Ca, Mg, and Fe
conservation diagnostics and warns when its configured tolerances are exceeded.
Its returned state records the
`nc`-by-6 diagnostics `phreeqcElementBalanceInput`,
`phreeqcElementBalanceOutput`, `phreeqcElementBalanceAbsoluteResidual`,
`phreeqcElementBalanceNormalizedResidual`, and
`phreeqcElementBalancePass`; column names are in
`phreeqcElementBalanceElements`. Configure scalar or six-element tolerances
with `phreeqcElementBalanceAbsoluteTolerance` (default `1e-7` mol) and
`phreeqcElementBalanceRelativeTolerance` (default `1e-8`) in
`phreeqcCouplingOptions`.

The current multirate working implementation has its elemental audit disabled;
its post-PHREEQC EOS component-inventory audit remains active. Consequently,
a passing EOS inventory audit alone does not establish elemental conservation
through the chemistry handoff.

The audit covers aqueous analytical totals (including the separate acetate
element), EOS H2/CO2/CH4/H2S, and all configured equilibrium minerals. Hydrogen
uses PHREEQC's system inventory with the fixed initial 1 kg solvent-water
baseline removed, avoiding subtraction of cell-scale solvent hydrogen while
retaining reaction- and hydrate-water changes. The compositional backend's
kinetic biomass is outside the reactive-element inventory because its PHREEQC
definition has `-formula H 0` and defines no C, S, Ca, Mg, or Fe storage;
MET/ACE/SRB kinetic amounts are reaction extents rather than stored products.
MRST `nbact` is likewise outside the equilibrium-only boundary.

`phreeqcBackend='sequential-h2biochem-phreeqc'` retains MRST's biochemical
sources and adds sequential PHREEQC equilibrium feedback.
It requires native IPhreeqc on Linux or a registered IPhreeqcCOM server on Windows, and an absolute
`h2_biogeochemistry.dat` path, but contains **no** PHREEQC `RATES` or
`KINETICS`. MRST's existing `state.nbact` Monod model remains the sole
reaction owner: bacterial growth, `BactConvertionRate`, and tracer reaction
sources remain active.

```matlab
[~, model, schedule, state0] = setupH2StorageExampleWithSRB_benchmark( ...
    'phreeqcBackend', 'sequential-h2biochem-phreeqc', ...
    'phreeqcTimestepCoupling', true, ...
    'phreeqcDatabaseFile', which('h2_biogeochemistry.dat'));
[wellSols, states, report] = simulateSequentialH2BiochemPhreeqc( ...
    state0, model, schedule);
```

Run this backend with `simulateSequentialH2BiochemPhreeqc`, rather than
directly with `simulateScheduleAD`. For every nominal schedule timestep, the
wrapper repeats the MRST solve from the fixed timestep-start state, then
equilibrates the already-reacted full component, tracer, gas, and mineral
inventories in PHREEQC. The relaxed preceding PHREEQC pH, DIC/CO2, and sulfate
snapshot is supplied only to MRST's Monod kinetic substrate evaluation; it is
not an MRST nonlinear initial guess or an accumulation state. Iteration stops
only when that chemistry feedback and the MRST-reported reaction extent
(`h2ConsumptionRate * dt`) meet configured tolerances, otherwise it raises a
nonconvergence error. It is therefore a same-timestep outer Picard scheme, not
a lagged post-step chemistry split.

### Standalone comparisons and validation

`runThreeBackendComparison()` compares three models included in H2sim and
uses the bundled chemistry database. It does not run an external driver.
`runPhreeqcValidation()` also runs standalone by default. For a short check:

```matlab
result = runPhreeqcValidation('gridCells', 2, 'totalDays', 2);
```

An external reference is optional: pass its checkout explicitly using
`'referenceRoot', referenceRoot`. Its files and platform are checked before
simulations start. New results store external outputs as `result.reference`.
Previously saved reference datasets remain readable by the plotting helpers.

### Biochemical Reaction Model

The module simulates the methanogenesis reaction:
\[
4\text{H}_2 + \text{CO}_2 \longrightarrow \text{CH}_4 + 2\text{H}_2\text{O} + \text{energy}
\]

For detailed methodology and validation, see our publication:
[**Numerical Modeling of Bio-Reactive Transport During Underground Hydrogen Storage**](https://www.sciencedirect.com/science/article/pii/S0360319925039473)

## Installation

### Prerequisites

- **MATLAB**: Version R2021a or newer
- **MRST**: MATLAB Reservoir Simulation Toolbox (2023b or newer)
- **Required MRST Modules**:
  - `compositional`
  - `ad-blackoil`
  - `ad-core`
  - `ad-props`
  - `h2store`
  -`biochemistry`

### Terminal profiling

From the H2sim repository root under WSL, run:

```bash
bash run_matlab_h2sim.sh "results = profilePhreeqcWorkflows;"
```

The launcher prefers Linux MATLAB on PATH and falls back to Windows MATLAB R2026a under WSL. It initializes this checkout from the
standard MATLAB path, and propagates MATLAB's batch exit status. Set
`MATLAB_BIN` to the desired Linux executable or Windows executable's WSL path.
The Windows COM backends require access to your MATLAB license server.

`profilePhreeqcWorkflows` profiles each baseline and compares three alternating
unprofiled baseline/candidate pairs. The candidates are the multirate local
pressure bracket and compositional cell batching. The default benchmark uses
50 cells and two 2-day flow steps, with 0.4-day multirate reaction substeps.
Simulation tolerances are unchanged. State comparisons combine field-specific
absolute tolerances with a relative tolerance of `1e-6`. Multirate EOS inventory
audits must pass; compositional elemental audit warnings are retained in the
saved states and reported without changing their existing warning policy. Profiles, paired states, comparisons and
timings are saved in `build/phreeqc-performance`, using local temporary files
before copying to the WSL filesystem.

Select a backend or reuse a completed profile with:

```matlab
results = profilePhreeqcWorkflows('backends', {'multirate'}, ...
    'collectProfiles', false, 'trials', 3);
```

Validated defaults use batches of up to 50 compositional cells and the local
multirate pressure bracket with the original fzero fallback. Set
`sequentialCompositionalPhreeqcBatchSize` to `1` or
`phreeqcReflashLocalBracket` to `false` to reproduce the respective baselines.
Three serial alternating trials at the benchmark settings gave median
simulation times of 30.10 -> 24.11 seconds for compositional and
168.35 -> 90.91 seconds for multirate. All compared compositional fields
matched exactly; multirate differences passed the stated inventory-based
absolute/relative tolerances. These short-case timings exclude startup and
model construction and do not establish full-schedule speedups.

### Saved multirate diagnostics

```matlab
diagnostics = reportMultirateDiagnostics(summary);
% Collect without printing:
diagnostics = reportMultirateDiagnostics(summary, 'verbose', false);
```

The result reports reaction-specific H2 consumption, maximum population ratios,
bicarbonate concentrations, and limiter coverage. Limiter minima include all
recorded accepted ministeps; rejected attempts are excluded. Missing diagnostics
are marked unavailable, partial coverage is identified, and malformed reports
raise an error. These diagnostics do not establish elemental conservation.

`printSeqDiag` remains a script reading the existing `summary` variable and
printing through the new function. It no longer creates incidental loop/helper
variables in the caller workspace; existing caller variables are preserved.

### Publication figures

The PHREEQC examples share labeled panels, consistent case colors and line
styles, and vector PDF / 300-dpi PNG export to `build/phreeqc-figures`.
Distance is measured at cell centers using the actual domain edges, so the
first and last cells lie inside the interval `0 < x/L < 1`. Percentage labels
state whether injection is cumulative to date or the total scheduled amount.

```matlab
% Short injection-only mineral comparison (the full default is 50 days):
comparison = exampleCompositionalBacterial1DPhreeqcMinerals( ...
    'gridCells', 4, 'maximumFlowSteps', 2);
% Short multirate case with publication figures:
summary = exampleSequentialBiochemistryPhreeqc1D( ...
    'maximumFlowSteps', 2, 'plotResults', true);
% Redraw completed runs without solving again:
plotPhreeqcMineralComparison(comparison);
plotSequentialBiochemistryPhreeqc(summary);
% For results returned by runThreeBackendComparison:
% plotPhreeqcBackendComparison(scenarios);
```

Pass `outputDirectory` to choose the export location; an empty string disables
export. Set `plotResults` to false to run a case without plotting. Mineral
case labels include rock names, and pH is shown only for PHREEQC cases that
provide it. Backend profile panels share a y scale for each plotted quantity;
phase boundaries and snapshot times come from the result schedules. Mineral
consumption uses separate labeled scales for the original and PHREEQC kinetics,
with printed totals; detail panels preserve the smaller mineral-case differences.
