Choose a model
==============

Start with the physical processes your question needs. All simulation families
use MATLAB and the pinned MRST checkout. Initialize H2sim from the repository
root with ``startupH2sim``; PHREEQC is an additional, explicit setup.
See :doc:`installation` before running the :doc:`quickstart` commands.
On a narrow screen, scroll the comparison table sideways to see every column.

.. list-table:: Model families and first examples
   :header-rows: 1
   :widths: 20 34 22 24

   * - Family
     - Choose it for
     - Additional dependencies
     - Start here
   * - Black-oil storage
     - Hydrogen–brine injection, withdrawal, trapping and dissolution using PVT tables
     - None for the bundled aquifer and anticline cases
     - :ref:`Small aquifer run <quickstart-aquifer>`; then :doc:`store` or :doc:`hydrogen-anticline`
   * - Compositional biochemistry
     - Gas composition, residual methane and microbial hydrogen consumption
     - None for serial execution; PHREEQC is unnecessary
     - :ref:`Two-step comparison <quickstart-biochemistry>`; then :doc:`biochem`
   * - PHREEQC coupling
     - Aqueous speciation, pH and mineral feedback alongside compositional flow
     - PhreeqcMatlab, a working IPhreeqc engine and a chemistry database
     - :ref:`Four-cell setup check <quickstart-chemistry>`; then :doc:`phreeqc`
   * - Thermodynamics
     - Compare gas–liquid partitioning and salinity effects, or prepare PVT tables
     - None for the supplied study; internet access for new NIST downloads
     - :ref:`Property study <example-thermodynamics>`; then :doc:`thermodynamics`

For gas mixing without water or reactions, start with :doc:`hydrogen-mixing`.
That small compositional example needs only core startup.

What changes between families?
------------------------------

Black-oil models use supplied phase-property tables; they do not resolve a
multicomponent gas composition. Compositional models use an equation of state
and track components. Biochemistry adds microbial kinetics to that transport.
PHREEQC adds aqueous chemistry, with two different assignments of microbial
kinetics: compositional PHREEQC uses cell-local PHREEQC kinetics; multirate
PHREEQC retains MRST kinetics and calls equilibrium chemistry after reaction
substeps. Read :doc:`phreeqc` before attributing differences between these
workflows to a single physical process.

The example name does not select every process automatically. Check its
transport switches, initial composition, mineral inventory and schedule.
A short prefix checks setup; a complete cycle is needed to inspect recovery.
Neither establishes agreement with published results or grid convergence.

Time and run size
-----------------

Start with the coarse aquifer or a limited-step example in :doc:`quickstart`.
The :ref:`example-runtime-guide` distinguishes measured wall-clock times from
cases without a recorded timing. Simulated days and animation length are not
execution times. Full 2D reactive cases are intended for subsequent study,
not as installation checks.

PHREEQC has platform-specific setup: native IPhreeqc on Linux, IPhreeqcCOM on
Windows. See :ref:`optional-phreeqc-setup` and the tested-platform limits in
:doc:`verification`. Parallel Computing Toolbox and AMGCL are optional; no
example on this selection path requires them.
