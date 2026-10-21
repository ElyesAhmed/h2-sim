Code reference
==============

Browse the `source repository <https://github.com/sintefmath/h2-sim>`_, or use
MATLAB's ``help`` and ``edit`` commands for local function documentation.

Entry points
------------

.. list-table::
   :header-rows: 1
   :widths: 60 40

   * - Function
     - Purpose
   * - ``startupH2sim``
     - Initialize code and dependencies
   * - ``exampleBlackOilAquifer2D``
     - 2D structural trapping and five storage cycles
   * - ``simple1DBacterialExampleMetacet``
     - MRST compositional microbial example
   * - ``setupH2StorageExampleWithSRB_benchmark``
     - Configure a multi-reaction benchmark
   * - ``exampleCompositionalBacterial1DPhreeqcMinerals``
     - Original MRST and three PHREEQC mineral configurations
   * - ``exampleSequentialBiochemistryPhreeqc1D``
     - Coarse-flow / local-reaction multirate example
   * - ``exampleCompositionalBacterial2DThreeReactions``
     - Existing 2D reservoir case with MET, ACE, SRB, packed cycles, and selectable scenarios
   * - ``runPhreeqcValidation``
     - Compositional PHREEQC injection benchmark against an external reference
   * - ``exampleH2BrineSolubilityStudy``
     - Phase-partition and salting-out comparisons
   * - ``setupOptimizedLinearSolver``
     - AMGCL CPR including bacterial and tracer unknowns; configurable native threads
   * - ``loadH2simResults``
     - Load result MAT files; optionally stage network files locally for HDF5
   * - ``activateH2simAMGCL``
     - Activate an optional locally compiled MRST gateway
   * - ``plotCompositionalPhreeqcValidation``
     - Redraw validation maps and reaction loss with optional saved reference data
   * - ``plotSequentialBiochemistryPhreeqc``
     - Redraw saved multirate flow/chemistry and consumption; return two figures
   * - ``plotPhreeqcMineralComparison``
     - Redraw saved mineral-case consumption and pH; return two figures
   * - ``plotPhreeqcBackendComparison``
     - Redraw saved backend metrics; return profile, time-series and spatial figures
   * - ``profilePhreeqcWorkflows``
     - Paired profiling and state comparisons

Saved backend figures
---------------------

``plotPhreeqcBackendComparison(scenarios)`` redraws the metrics returned by
``runThreeBackendComparison`` without running simulations. Its three returned
figure handles contain aqueous profiles, cumulative consumption over time and
final spatial consumption, respectively. The caller may inspect or close them.

Pass ``'outputDirectory', ''`` to create figures without export. Otherwise,
three vector PDF and three 300-dpi PNG files are written under the selected
folder (default ``build/phreeqc-figures`` under the current directory).
The base names are ``backends_aqueous_profiles``, ``backends_H2_consumption_time``
and ``backends_H2_consumption_space``. Labels, units and normalization are
preserved from the scenario metrics; corresponding snapshot times must match.
See :doc:`phreeqc` for the save/reload workflow and backend interpretation.

Saved mineral figures
---------------------

``plotPhreeqcMineralComparison(comparison)`` redraws the mineral examples'
metrics without running simulations. It returns two open figures: reaction-wise
consumption with final cellwise pH, then consumption histories with optional
spatial contributions. Empty pH values are omitted; removing the spatial fields
omits the spatial panels.

Time histories use consumed H2 divided by injected H2 to date. Spatial values
are per-cell contributions divided by total injected H2. These normalizations
are supplied by the example metrics and are preserved by plotting.

``'dimension', 2`` changes titles and filenames, not the data or grid mapping.
The default label is 1. PDF/PNG base names are
``minerals_<dimension>D_consumption_pH`` and
``minerals_<dimension>D_H2_consumption``. Pass ``'outputDirectory', ''`` to create
figures without writing files; otherwise vector PDF and 300-dpi PNG exports go
to the selected folder, defaulting to ``build/phreeqc-figures`` under pwd.

Saved multirate figures
-----------------------

``plotSequentialBiochemistryPhreeqc(summary)`` redraws a saved multirate summary
without running simulations. It needs ``model``, ``states``, ``schedule`` and
``injectedH2Moles``. The final state provides pressure, saturation, pH and biomass;
reaction-wise consumption is computed from the saved state history.

The two returned figures show final profiles (pressure in MPa, gas saturation,
pH and biomass N/N0) and cumulative consumption (mol and percent of total
scheduled injected H2). Time is in days and distance is x/L. The injection
denominator is fixed over the selected schedule, including during injection.

Exports use vector PDF and 300-dpi PNG with base names
``multirate_final_profiles`` and ``multirate_H2_consumption``. The default folder
is ``build/phreeqc-figures`` under pwd; pass ``'outputDirectory', ''`` to disable
export. Returned figures remain open for the caller to inspect or close.
See :doc:`phreeqc` for saving and reloading the multirate summary.

Storage-cycle validation example
--------------------------------

``exampleCompositionalPhreeqcValidation`` (also available through
``runPhreeqcValidation``) runs the bundled compositional PHREEQC case without
an external checkout. The default uses 20 cells over 50 m and 125 two-day
steps: injection to day 50, storage to day 200, then production to day 250.

For a short injection-only run, use::

   result = runPhreeqcValidation('gridCells', 4, 'totalDays', 2, ...
       'plotResults', false, 'outputDirectory', fullfile(pwd, 'validation'));

Each call saves ``validation_results.mat`` with the setup, accepted states,
reports and diagnostics. ``plotResults`` controls plotting only. The output
folder does not select the packed simulation cache. Identical setups can reuse
cached states; changing the duration changes the hashed schedule and selects a
separate cache. Reported elapsed time includes cache lookup and output loading.
Short runs exercise injection, rather than the complete storage cycle.

``referenceRoot`` explicitly enables the optional external comparison. Its
adapter requires Windows MATLAB with COM; standalone H2sim also supports Linux.
Reference sources are adapted in a temporary copy, retaining the reference
kinetic equations. This comparison is not a claim of identical reaction models.

PHREEQC model configuration
---------------------------

``BiochemistryPhreeqcModel`` requires grid, rock, fluid, compositional mixture,
biochemical mixture, water-phase flag and MRST AD backend as positional inputs.
The AD backend is separate from ``phreeqcBackend``, which selects chemistry.
Coupling is disabled by default and does not activate the PHREEQC engine during
construction. Backend names are trimmed and normalized to lower case.

With ``phreeqcTimestepCoupling`` enabled, provide an absolute existing path to
``h2_biogeochemistry.dat`` through ``phreeqcDatabaseFile`` or, when that property
is empty, ``phreeqcCouplingOptions.databaseFile``. Both backends also require
bacterial transport, the carbonate buffer and sulfate reduction. Compositional
PHREEQC owns the reaction kinetics; hybrid PHREEQC retains H2sim kinetics and
requires its Picard driver or the multirate split. Internal driver activation
flags cannot be enabled through constructor options.

Linux uses native IPhreeqc through PhreeqcMatlab; Windows defaults to COM.
The ProgID properties remain configuration metadata on Linux. Constructor
validation does not establish runtime engine availability. Backend-specific
coupling options are documented in the corresponding coupling utility.

Accepted-step PHREEQC coupling
------------------------------

``BiochemistryPhreeqcModel.updateAfterConvergence`` finalizes each accepted
nonlinear ministep, rather than each Newton iteration. It first calls the
parent flow update, records H2sim reaction consumption when applicable, then
dispatches the configured chemistry backend. Lagged dissolved H2S is cached
after chemistry and reflash for the following EOS evaluation.

Compositional PHREEQC owns reaction kinetics and consumption; the H2sim
consumption-rate path is skipped. Hybrid PHREEQC records the converged H2sim
source rate before chemistry changes the state and accumulates accepted
reaction extents. Reaction-disabled flow stages record zero rate and carry
existing cumulative hybrid consumption forward unchanged.

Reaction-disabled stages do not assemble a timestep carbon budget, so the
post-convergence hook omits ``CarbonLimitedGrowthRate`` from diagnostic output.
Other requested diagnostics, including the raw ``PsiGrowthRate`` kinetic
coefficient, remain available. The caller's output requests are preserved,
so re-enabling reactions restores the carbon-limited diagnostic with its
normal timestep and inventory checks. No unlimited-growth fallback is used.

The hybrid hook checks that the Picard or multirate driver is active; it does
not perform a separate chemistry update. Direct ``simulateScheduleAD`` with
an undriven hybrid model is rejected to prevent a lagged one-pass split.
Coupling-disabled models skip chemistry dispatch. Existing consumption fields
remain in accepted states and are carried through packed restarts.

Reaction-specific H2 accounting
-------------------------------

``[rate, cumulative] = computeH2Consumption(states, schedule, model, reaction)``
returns cell-by-time consumption in mol/s and mol. Standard reaction indices
are MET (1), ACE (2), SRB (3). Supply one accepted state per schedule step,
excluding the initial state, with timestep lengths in seconds.

The collector prefers compositional PHREEQC step increments, then multirate
PHREEQC cumulative values, then generic cumulative values, then converged
source rates. Backend-specific fields require the matching model backend.
Cumulative histories take precedence over saved rates; their differences give
step-average rates. The first cumulative value is treated as the first step's
increment, so a truncated history with a nonzero initial consumption offset
cannot provide the correct first step rate. Stored values are not clipped.

Validation diagnostics
----------------------

``collectPhreeqcValidationDiagnostics(result)`` collects saved model, schedule
and accepted states; it does not run PHREEQC. Each run must contain one state
per schedule step, excluding the initial state. Its outputs are cell-by-time
H2 mole fraction, pH and DIC (mol/kg water), plus cell-by-time-by-reaction
cumulative H2 consumption in mol, ordered MET, ACE, SRB. Times are in days and
cell coordinates in metres.

Loss percentages use each run's total prescribed injection over the selected
schedule as a fixed denominator. Active ``rate`` and ``grat`` injectors are
counted using H2 component index 2 and the facility ideal-gas conversion;
other control types are skipped. This is not a well-solution flux integral.
Reference rates use mol/kg water/day and water mass in grams. Reference states
must include ``Solution.TotalDIC``; legacy ``ugfact`` saved entries remain
readable. The collector does not interpolate or align reference coordinates.

Saved validation figures
------------------------

``plotCompositionalPhreeqcValidation(result)`` returns three figures for hydrogen
loss and aqueous H2, pH/DIC maps, and MET/ACE/SRB loss contributions. It uses cached
``result.diagnostics`` when supplied; otherwise it collects diagnostics from the
saved H2sim model, schedule and states. Optional reference data add comparison
curves and maps; no external checkout is needed to redraw saved data. Legacy
``ugfact`` fields remain readable without changing stored provenance.

Time is in days, distance uses the first cell coordinate in metres, aqueous H2
is a mole fraction and DIC is in mol/kg water. Loss uses total prescribed H2
injection as its denominator throughout the selected schedule. Reference times
and first coordinate columns must match exactly, and reaction contributions must sum to the
total loss within the existing tolerance.

Export is disabled by default. A nonempty ``outputDirectory`` receives three
200-dpi PNGs, three vector PDFs and ``phreeqc_loss_history.csv``. CSV reference
columns appear only when reference diagnostics are present. Historical export
base names end in ``full_cycle`` even for short datasets; filenames alone do
not establish full-cycle coverage. The caller owns the returned open figures.

Shared 1D storage setup
-----------------------

``setupH2StorageExampleWithSRB_benchmark`` constructs the model, initial state
and schedule without running a simulation. Its default reservoir is 50 m long,
with 50 cells, porosity 0.20 and permeability 100 mD. Initial pressure is 150 bar
and temperature is 333.15 K. The default ``highrate`` kinetics and 125 two-day
steps cover injection (50 days), storage (150 days) and production (50 days).
Use ``'scheduleMode', 'injection'`` for the injection period alone.

PHREEQC coupling is disabled by default. Selecting compositional PHREEQC adds
local PHREEQC kinetics and equilibrium; the hybrid backend instead retains MRST
microbial kinetics. For multirate execution, convert the hybrid model with
``convertToSequentialBiochemistryPhreeqcModel`` before simulation, as shown in
``exampleSequentialBiochemistryPhreeqc1D``. The alternative outer Picard runner
is ``simulateSequentialH2BiochemPhreeqc``. These are distinct coupling workflows.

The uncoupled ``initialHCO3`` default is ``1.1119e-3 mol/kgw``; coupled cases use
``sequentialCompositionalPhreeqcInitialC4`` (default ``1.370e-3 mol/kgw``).
See MATLAB ``help setupH2StorageExampleWithSRB_benchmark`` for option defaults,
biomass conventions and conservation tolerances.

Output and replotting
---------------------

The aquifer, compositional 2D, validation, and short chemistry examples save their setup and accepted states with MRST
packed simulation output. ``packed_setup.mat`` sits beside the saved states,
well solutions, and timestep reports. Changed inputs select a separate result
directory. Returned results contain the setup and state histories;
``packedProblem`` identifies the black-oil and multirate output locations.
The mineral comparison returns one result per model configuration.

.. code-block:: matlab

   plotBlackOilAquifer2D(result);
   plotH2BrineSolubilityStudy(study);
   plotCompositionalBacterial2DThreeReactions(results);
   plotCompositionalPhreeqcValidation(validation);
   plotPhreeqcMineralComparison(comparison);
   plotSequentialBiochemistryPhreeqc(summary);
   plotPhreeqcBackendComparison(scenarios);

The compositional 2D MAT results retain physical fields while omitting
transient derivative/state-function caches. Complete restart states remain
in the packed directory. A completed MAT result with matching packed setup
can be reused without rereading every restart cache. Use ``loadH2simResults``
when loading large result files through a network path; it
stages a temporary local copy for HDF5 and removes it after loading.

Plotting functions preserve values and export vector PDF and PNG figures.
``outputDirectory=''`` disables export. Dimensionless distance uses actual
domain edges, rather than stretching cell centers to zero and one.

Hydrogen-consumption percentages refer to microbial reaction consumption,
with the injection denominator stated by the figure. They are distinct from
unrecovered gas or a production recovery factor.

Tests
-----

.. code-block:: matlab

   checks = runtests('tests/biochemistry');
   assertSuccess(checks);

COM integration tests require the IPhreeqcCOM setup described in :doc:`installation`.
A skipped test does not validate a backend on that platform. The serial
fallback tests cover both available and missing optional toolbox checks.

See :doc:`phreeqc` for the current conservation-audit limitations.
