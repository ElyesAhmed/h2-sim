# Local storage-cycle regressions

These checks cover black-oil and reactive PHREEQC cycles, including serialized
restarts with freshly reconstructed models and PHREEQC engine sessions.

Run from the repository root in MATLAB:

```matlab
addpath(fullfile(pwd, 'tests', 'cycles'));
cases = runStorageCycleRegressions();
```

If dependencies are installed elsewhere, pass the MRST and PhreeqcMatlab root
folders as the two arguments. A working PHREEQC engine is required. Missing
backends and incomplete simulations fail the runner rather than skipping cases.
These checks run locally; no MATLAB GitHub Actions job is added.

Each four-cell case has six steps: two injection, two shut-in and two production
steps. The black-oil case uses synthetic fluid data with both dissolution and
vaporization enabled and runs for 600 seconds. The sequential biochemistry case
uses the bundled PHREEQC database, runs for 2.4 days and limits reaction substeps
to 0.2 days. Its producer withdraws at 20% of the injection surface rate;
this ensures withdrawal despite reaction-induced pressure changes. These compressed cycles exercise control transitions; they do not
reproduce the durations or results of the paper cases.

For each case, the runner solves the complete schedule, independently solves its
first three steps, writes that state to a temporary MAT file, rebuilds the model
and solver, reloads the checkpoint and resumes at step four. This checks a
serialized-state restart within shut-in followed by a transition to production.
Model reconstruction occurs within the same MATLAB process. The persistent
PHREEQC equilibrium function is cleared before independent runs and before
resuming the checkpoint, so restart checks use a fresh engine session. Checkpoints contain
the complete state, including chemistry history; they are removed afterward.

Checks cover:

- Convergence and completion of every requested step.
- Finite positive pressure, bounded/normalized saturation and overall composition.
- Positive injection, zero active exchange during shut-in and negative total fluid production (gas plus liquid surface rates).
- Black-oil hydrogen inventory balanced against integrated surface well exchange,
  with maximum residual below `1e-5` of initial hydrogen inventory.
- Positive, nondecreasing cumulative PHREEQC hydrogen consumption.
- Restart and saved-reference agreement for states, aqueous tracers, reaction
  history, well outputs, timesteps and control indices.

MRST may retain a previous reported well rate while the well is inactive. Raw
well rates are retained for comparison, but physical exchange is multiplied by
the schedule's active-well flag. Using an inactive well's raw rate would count
exchange that did not occur.

Pressure and BHP comparisons allow `0.01 Pa + 1e-9*abs(reference)`; other numeric
outputs allow `1e-10 + 1e-7*abs(reference)`. All recorded values must be finite,
and field names and array dimensions must match. These are comparison bounds;
the runner does not change production-model solver tolerances.

## PHREEQC PE diagnostic

The hybrid equilibrium path has documented engine-history sensitivity in the
returned `phreeqcPE` diagnostic; the engine session is not serialized in the
MATLAB state. See the hybrid PHREEQC discussion in
[the reference documentation](../../doc/reference.rst). This diagnostic is not
used for kinetic feedback. The restart comparison checks its dimensions and
finiteness and prints its maximum absolute difference separately. It does not
require PE restart equality. All other captured quantities retain the stated
comparison bounds. PE remains included in the saved uninterrupted-run reference
comparison. This is an explicit scope limitation, not a claim of identical
chemistry diagnostics on restart.

## Reference ownership

`storage-cycle-reference.mat` contains numeric snapshots in a `cases` struct.
Its provenance is recorded in `reference-provenance.json`. The initial reference
was generated using pre-cleanup source `9794f27` and checked against the merged
cleanup source. It was then reviewed and updated for the EOS trace-floor fix
`d3dbf3f`; see the numerical changes below and the provenance JSON. It contains no model
objects or dependency code.

The runner never writes or updates the reference. Any future reference change
must explain the numerical change, review the affected quantities and retain a
before/after comparison. Do not refresh it merely to make a failed test pass.

The checks establish reproducibility and preservation of these small cases.
They do not establish full elemental conservation for reactive chemistry, cover
all phase-appearance regimes, or replace full paper-cycle validation. Existing
H2-store phase-transfer tests separately cover dissolution-only and
vaporization-only configurations and closed-system component inventories.

## Trace-component restart regression

The original cycle reproduced a final-step HS tracer difference of
`7.170710469e-8 mol/m^3`. Its first material difference entered PHREEQC in the
input sulfur total. In the EOS successive-substitution flash, a trace composition
of exactly `minimumComposition` froze its K-value, while the adjacent
floating-point value above that floor updated it. Restart roundoff could select
different branches, changing the dissolved H2S share handed to PHREEQC.

`SoreideWhitsonEos` now maps feeds within four floating-point increments of the
composition floor to that floor before calling the inherited SSI update. The
floor, equilibrium tolerances, database and kinetic parameters are unchanged.
The focused `SoreideWhitsonTraceFloorTest` checks both identical phase updates
for neighboring floor values and normal K-value updates above that tiny band.

The corrected branch classification changes the uninterrupted reference as well
as stabilizing restarts. Reviewed maximum changes in this four-cell case are:

| Quantity | Maximum absolute change |
| --- | ---: |
| Pressure | 3.5041 Pa |
| Saturation | 8.1845e-8 |
| Overall component fraction | 2.1348e-8 |
| pH | 7.0651e-5 |
| HS tracer | 4.1646e-4 mol/m^3 |
| HCO3 tracer | 1.6414e-4 mol/m^3 |

Total final H2 consumption changed from `0.083275857282247928` to
`0.083275622213297762 mol`, about 2.8 parts per million. The black-oil reference
is unchanged. PE diagnostic values may change substantially, as discussed above.
The fixed fresh-engine restart has a maximum HS tracer difference of
`1.394717675e-14 mol/m^3`, compared with `7.170710469e-8 mol/m^3` before the
fix. Comparison bounds were not widened. These values describe this fixture, not a
bound on changes in every possible simulation.

## Inspecting a failing restart

After initialization by the runner, request both outputs from the lower-level
routine to inspect completed cycles and explicit statuses without raising at
the first comparison failure:

```matlab
[cases, restartChecks] = runStorageCycleCases();
disp(restartChecks);
```

Requesting only `cases` still raises when a check fails. The standard
`runStorageCycleRegressions` command always requires every restart to pass,
even if the saved uninterrupted-cycle reference matches.
