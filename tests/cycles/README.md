# Local storage-cycle regressions

**Known failing check:** fresh-engine PHREEQC restarts expose a `tracerHS`
difference during production in both pre-cleanup `9794f27` and merged cleanup
`72f9e4b`. In the final 2.4-day reactive cycle, the measured difference is
`7.170710469e-8 mol/m^3` in one cell at the final step (about 0.025%). The strict
runner below reports this failure; it has not been waived or accepted as a
passing regression. Black-oil cycle/restart checks pass. The reactive case
consumes hydrogen throughout the cycle, reaching approximately `0.0833 mol`.
This test addition records an existing restart issue; it does not fix it.

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
was generated using pre-cleanup source `9794f27`, then checked against the merged
cleanup source, independently of restart comparisons. It contains no model
objects or dependency code.

The runner never writes or updates the reference. Any future reference change
must explain the numerical change, review the affected quantities and retain a
before/after comparison. Do not refresh it merely to make a failed test pass.

The checks establish reproducibility and preservation of these small cases.
They do not establish full elemental conservation for reactive chemistry, cover
all phase-appearance regimes, or replace full paper-cycle validation. Existing
H2-store phase-transfer tests separately cover dissolution-only and
vaporization-only configurations and closed-system component inventories.

## Inspecting a failing restart

After initialization by the runner, the lower-level routine can return both
completed-cycle outputs and explicit restart statuses without raising at the
first comparison failure:

```matlab
[cases, restartChecks] = runStorageCycleCases();
disp(restartChecks);
```

Requesting only `cases` still raises when a restart fails. The standard
`runStorageCycleRegressions` command always requires every restart to pass,
even if the saved uninterrupted-cycle reference matches. Do not interpret
successful completion of the diagnostic routine as an all-tests-passed result.
