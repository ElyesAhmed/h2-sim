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
