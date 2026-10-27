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

Base microbial balances
-----------------------

``BiochemistryModel`` is the base class for the microbial compositional
models. It assembles EOS component balances first, then bacterial population
balances and, when sulfate reduction is enabled, the SO4/HS tracer balances.
Facility equations are appended last. The class does not call PHREEQC.

``BiochemicalFlowDiscretization`` returns accumulation rates and internal-face
fluxes separately. ``BiochemistryModel`` adds flux divergence, prescribed
bacterial diffusion boundary fluxes, and reaction sources. Bacterial mass is
``pv * sL * rhoL * nbact`` in kg: ``nbact`` is a liquid mass fraction.
``AqueousTracerMass`` instead returns ``pv * sL * concentration`` in mol,
with tracer concentrations in mol/m3 of liquid. Both mass state functions
retain their existing liquid-saturation floor of ``1e-8``.

Microbial diffusion follows decreasing bacterial mass fraction; chemotaxis
follows increasing dissolved-H2 mole fraction. When both mechanisms are
active, their face fluxes are added. Prescribed bacterial boundary values
contribute only when bacterial diffusion is active; ``NaN`` retains the
natural no-flux condition. See ``addBacterialBC`` for boundary setup.

In the base class, ``reactionsEnabled = false`` omits component-conversion
sources and the bacterial/SRB facility source calls. Those facility calls
combine reaction and well-advection sources, so the flag also omits their
well contributions; internal-face transport remains active.
``localReactionMode = true`` omits spatial flux divergence and bacterial
diffusion boundary contributions while retaining accumulation and enabled
sources. The flag alone does not remove wells or component boundary sources.
These switches support the multirate model's separate flow and local-reaction
stages, whose setup supplies the corresponding controls. Equation ordering
and convergence tolerances are preserved.

In ``BiochemistryPhreeqcModel`` the aqueous tracer source terms are split:
well transport remains active when ``reactionsEnabled = false``, while SRB
reaction sources and the biological bicarbonate sink are disabled. This
allows the multirate flow stage to remove the cell's dissolved tracers with
liquid well outflow before advancing cell-local reactions. The existing
zero tracer concentration assigned to injected liquid is unchanged.
The shared ``BiochemistryModel`` behavior described above is unchanged.

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

Compositional PHREEQC coupling inputs
-------------------------------------

``runSequentialCompositionalPhreeqcCoupling(model, state, dt)`` accepts an
already converged state and a positive duration in seconds. It validates
configuration and positive liquid water mass before constructing chemistry
inputs. Recognized ``phreeqcCouplingOptions`` fields override utility defaults,
including the database/ProgID values seeded from model properties.

Water mass is in kg per cell, input concentrations in mol/kg water and gas
volume in litres/kg water. The first call retains the historical biomass
normalization for reference compatibility and equilibrates all wet cells
(liquid saturation at least 1e-3). A stored state flag prevents repeating that
normalization. Subsequent calls can skip inactive cells; this defaults to true
only above 1000 grid cells. The normal state update restores inactive chemistry.

Each coupling invocation creates one engine session and loads its database
once; all batches in that invocation share it. Sessions do not persist between
timesteps. Batch size defaults to 50 and chemistry substeps to five, unless
configured. Selected-output row counts and kinetic-step sequences are checked
before mapping results back to cells. Linux uses native IPhreeqc; Windows uses
COM. Engine creation is deferred until at least one cell needs execution.

Compositional PHREEQC batch output
----------------------------------

The coupling function retains ownership of its engine session through element
auditing and state reconstruction. Its batch executor builds independent cell
blocks, calls the engine and assigns parsed output back to the original grid
indices. ``sequentialCompositionalPhreeqcInputCell1String`` contains the first
executed batch, despite the historical field name; it is empty if no cells run.

Selected-output validation requires one initial row and the configured number
of kinetics rows per cell, a ``step`` column, and matching unique kinetics-step
sequences across cells. Initial rows have negative step values; kinetics rows
have nonnegative values. Rows can be grouped or interleaved, provided execution
order is retained within each group. Mapping does not rely on PHREEQC's ``sim``
or ``soln`` identifiers. A batch size of one still validates the output layout.
Malformed multi-cell output retains the existing
``H2Biochem:SequentialCompositionalPhreeqcBatchOutputMismatch`` error.

Compositional PHREEQC chemical results
--------------------------------------

The chemical-result parser normalizes header case and punctuation and accepts
the existing molality aliases used by native IPhreeqc and COM output. If more
than one accepted alias is present, the first matching column in output-header
order is selected. Numeric scalars and numeric text are decoded; nonscalar,
nonnumeric and non-finite entries retain their existing rejection behavior.

Aqueous concentrations, gas/mineral inventories and biomass use the final
selected-output row. Reactive hydrogen retains separate initial and final
inventories for the element audit. Reaction rates and diagnostic TDS exclude
the initial audit row and use interval-ending values weighted by reported
time increments, divided by the final reported kinetic time. The existing
last-value fallback applies when that final time is nonpositive. Parsing does
not convert the stored units or change kinetics, mineral correction or reflash.

Hybrid and multirate chemistry stages
-------------------------------------

``SequentialBiochemistryPhreeqcModel`` advances one flow/transport stage, then
``ceil(dt/reactionSubstepMaxDt)`` equal local reaction substeps of duration
``dt/nSub`` seconds. The flow stage includes wells, boundary conditions and
transport, with biological reaction sources disabled. The reaction stage
has no external forcing and uses the bounded local integrator; the retained
``reactionNonLinearSolver`` property is for API compatibility.

Before local reactions, the flow well solution is cleared so the well-free
reaction facility can initialize its own state. Chemistry feedback is loaded
into both the reaction model and its facility's reservoir-model reference.
Each successful local reaction update is followed by aqueous/mineral PHREEQC
equilibrium and a feedback refresh, including the final substep. The flow
well solution is restored on the accepted state for reporting.

Normal runs should use ``simulateScheduleAD``. A direct ``stepFunction``
call must follow the scheduler's preparation sequence: validate the model,
validate the schedule, validate the state, and apply
``updateForChangedControls`` to the outer model/state. Schedule validation
also applies the Soreide–Whitson injection phase-fraction and surface-density
conversion. Run the report-step/timestep preparation hooks before invoking
the step method. The resulting state supplies the inner flow solver's initial
guess, including initialized well controls. State validation alone does not
perform this sequence.

The hybrid equilibrium entry point validates the request, snapshots its
post-reaction water/aqueous/mineral basis, and processes cells in order using
the existing persistent IPhreeqc session. It supplies no gas phase or PHREEQC
kinetics: MRST owns reaction kinetics and the EOS owns gas/liquid partitioning.
``refreshOutputs=false`` skips requested output-state-function evaluation;
chemistry reconstruction and the volume-constrained reflash still occur.
The independent hybrid element audit remains unavailable.

Feedback uses PHREEQC molalities when present, with the existing tracer/EOS
fallbacks otherwise. Aqueous feedback concentrations use mol/kg water; tracer
fallbacks are converted from mol per liquid volume using EOS water density.
pH and carbonate pKa1 are dimensionless. Existing defaults, validation,
resource limits, reaction accounting and convergence policies are retained.

Hybrid PE and restart reproducibility
-------------------------------------

The hybrid backend currently initializes each PHREEQC ``SOLUTION`` with
``pe 4``. Returned ``state.phreeqcPE`` is a diagnostic; its value does not
replace that initial setting and is not part of the kinetic-feedback snapshot.
The returned equilibrium PE can differ from the initial value: PHREEQC uses
hydrogen and oxygen mole balances in batch-reaction equilibrium calculations
(`USGS PHREEQC introduction <https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-2.htm>`_).

Local Windows COM benchmark replays showed PE sensitivity both to tiny input
roundoff and to engine history. Identical input was reproducible in fresh
engines but could return a different PE in a reused engine. ``DELETE -all``
did not remove that effect; database reload did for identical input, while
the sensitivity to different rounded inputs remained. A nonzero
iron/pyrite/goethite probe was much less sensitive. These observations are
consistent with a weakly constrained redox diagnostic in the tested cases;
they do not establish the behavior of all redox-sensitive configurations.

Assess restart consistency using aqueous and mineral inventories, chemistry
feedback and reaction consumption alongside PE. In the tested short hybrid
cases, those physical differences were near floating-point roundoff despite
a larger PE difference. Replacing returned PE with a constant, passing it back
as a different initial condition, or changing redox constraints would alter
the scientific interpretation. No such change or tolerance relaxation is
applied here. Engine reload alone is not a complete restart-reproducibility
fix when the generated input also differs by roundoff.

PHREEQC selected-output definitions
-----------------------------------

Custom ``USER_PUNCH`` calculations precede the standard ``SELECTED_OUTPUT``
requests. The custom rate columns retain MET/ACE/SRB ordering, reading
``GET`` slots 1/3/2. They report H2-consumption rates on the unit-water basis;
the coupling later converts these to per-cell rates and integrated moles.
Species molalities and aqueous totals use mol/kg water; activities and pH
are dimensionless. Gas and mineral outputs are inventories for the unit-water
calculation and are rescaled by the coupling.

The custom carbonate and gas diagnostic headings retain their existing
expressions. In particular, ``TOT_CO2`` combines the reported gas CO2 amount
with aqueous ``MOL("CarbonateO2")``; ``Dissolved_CO2`` retains the carbonate
speciation subtraction; ``Z_Factor`` retains
``GAS_P*GAS_VM/TK/0.082057366080960``. Grouping the definitions introduces no
header renaming, formula changes or unit conversion.

``REACTIVE_SYSTEM_H`` counts hydrogen outside aqueous solvent H2O, then adds
the net water change relative to the initial one kg and three implicit H
atoms per acetate pseudo-element. These corrections apply to initial and
final audit rows. Existing acetate and added-water tests check this accounting.

Simulation and solution identifiers remain diagnostic metadata. Batch row
association uses initial-row step signs and repeated kinetic-step sequences;
kinetic time is retained for interval integration. Requested species, mineral
phases, biomass names and column ordering remain part of the parser contract.

PHREEQC shared rate definitions
-------------------------------

The shared ``RATES`` preamble defines methanogenesis (MET), sulfate reduction
(SRB) and acetogenesis (ACE), followed by their biomass rates. Each chemistry
builder keeps its own substrate limitation, temperature and pH response.
All three retain the existing TDS suppression curve, using either PHREEQC's
solution-density estimate or the pinned brine TDS parameter.

Chemistry rates write ``PUT`` slots 1, 2 and 3 for MET, SRB and ACE,
respectively. The corresponding biomass definitions read those same slots
through ``GET``. Selected-output diagnostic columns retain the separate
MET/ACE/SRB order. Growth and decay parameters supplied per day are converted
to per second in the generated BASIC code.

The biomass definitions share one template with explicit reaction name,
slot, yield and decay parameters. Their existing ``SAVE`` sign convention,
minimum biomass, carrying-capacity limit and numeric formatting are retained.

PHREEQC cell input blocks
-------------------------

Each cell contributes a solution, gas phase, kinetics and equilibrium-mineral
block, followed by explicit ``USE`` commands. Entity numbers are local to the
batch (1 through its cell count). The shared selected-output and rate
preamble is prepended once per batch.

The solution uses one kg water, concentrations in mol/kg water, pressure in
atm and temperature in degrees Celsius. Gas volume and inventories use the
same water basis. ``GAS_PHASE_MODIFY`` supplies the full EOS volatile
inventory, including its dissolved portion, for PHREEQC to repartition.
Mineral inventories are converted from mol per cell to mol/kg water before
input construction.

Kinetics retain the existing biomass caps, reaction stoichiometry, seconds-based
coupling duration and configured substep count. Inactive cells receive zero
available H2. When brine TDS is pinned, its value is passed through the kinetic
``PARM`` entry. Block ordering, numeric formatting and reaction boundaries are
preserved by the individual builders.

PHREEQC result writeback
------------------------

The compositional backend writes aqueous chemistry, mineral inventories and
MET/ACE/SRB reaction results before reconstructing EOS composition. Aqueous
molalities use mol/kg water; transported tracers use mol/m\ :sup:`3` liquid
with the configured water density. Mineral inventories use mol per cell.
Biomass remains separate from MRST's ``nbact``. Reaction rates retain the
MET/ACE/SRB column order and are integrated over the coupling duration for
per-cell H2 consumption.

Inactive cells retain their previous chemistry, biomass and EOS component
inventories; their reaction rates are zero. The EOS composition combines the
reported aqueous and gas component inventories with the net water change.
State-function caches are cleared before salinity feedback and EOS reflash;
requested output state functions are refreshed afterwards. The ordering,
nonnegative clipping and carbonate pKa fallback retain the existing behavior.

PHREEQC state initialization and restarts
-----------------------------------------

State validation supplies missing fields only for enabled model features.
It preserves existing biomass, tracer, pH and lagged sulfide values. Bacterial
``nbact`` is distinct from PHREEQC's MET/ACE/SRB biomass fields. The latter
use mol/kg water; mineral state inventories use mol per cell. Missing mineral
fields start at zero, while existing inventories are retained.

The compositional backend preserves its historical first-call biomass
normalization by cell water mass. The state flag
``sequentialCompositionalPhreeqcFirstStepBiomassConventionApplied`` records
that this conversion has occurred and controls first-call equilibration.
Keep this flag with the biomass, aqueous chemistry and mineral fields when
saving a restart. A state without the flag follows first-call behavior;
there is no inference from simulation time or from nonzero biomass.

Restart from the complete saved state, rather than copying pressure and
composition alone. This also retains cumulative reaction accounting and
element-audit warning history. Initialization does not reconstruct missing
history or migrate partial states from other chemistry backends.

PHREEQC audit reporting and failure files
-----------------------------------------

Element conservation is checked on every audited call using the existing
absolute and relative tolerances. By default, warning output is limited per
state history and backend: report newly failing elements, then repeat only
when the worst residual-to-limit ratio for a reported element grows tenfold.
All per-cell inventories, residuals and pass/fail flags remain stored on every
call, including calls without printed warnings. The history and reporting
counters travel with saved states; independent cases start fresh histories.

To retain the previous one-warning-per-failing-call behavior, set this before
packing or running the model::

   model.phreeqcCouplingOptions.phreeqcElementBalanceWarningMode = 'always';

The default is ``'once'``. This setting changes reporting only; a quiet console
does not turn a failed audit into a pass or establish that the residual is
harmless. Hybrid chemistry's unavailable independent element audit remains
unavailable; the reporting option does not create a new audit there.

Invalid output/mineral inventories still raise their original errors. The
compositional coupling saves the existing diagnostic variables to uniquely
named ``invalid_inventory_*.mat`` files under ``build/phreeqc-failures`` in the
working directory. Saving first uses a local temporary file for WSL shares.
If writing fails, the original inventory error is rethrown with the filesystem
failure attached as a cause, rather than being replaced by a save error.

PHREEQC model equation assembly
-------------------------------

``BiochemistryPhreeqcModel.getModelEquations`` assembles component conservation,
biomass, aqueous tracer and facility equations in that order. PHREEQC engine
calls occur after convergence, outside the Newton equation assembly.

When bacterial reactions and the carbonate buffer are enabled, the finite
carbon limiter uses the start-of-step aqueous CO2 plus bicarbonate inventory
in mol and the current timestep in seconds. The evolving Newton state does
not replace that initial budget. Bicarbonate supplies a bounded part of the
microbial CO2 demand through a shared cellwise sink in mol/s: its contribution
is added to the CO2 source with the existing molar-mass and density scaling,
and subtracted from the HCO3 tracer source. Signed sources are then subtracted
from their residuals; tracer residuals are in mol/s.

Reaction-disabled stages omit biological sources. Local reaction stages omit
spatial flux divergence. Compositional PHREEQC owns its microbial reactions and
omits the inactive H2sim biomass equations; the hybrid workflow retains H2sim
reaction and biomass equations. SO4/HS keep their existing sources, while Ca/Mg
have no H2sim reaction source and are updated by PHREEQC. This organization
does not change stoichiometry, source scaling or conservation tolerances.

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
