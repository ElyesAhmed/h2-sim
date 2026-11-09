Discretization and coupling
===========================

H2sim builds on MRST's finite-volume and automatic-differentiation
frameworks. The main flow models discretize the
:doc:`compositional-model` and :doc:`black-oil-model` in space and time,
while the PHREEQC
workflows introduce explicit flow-reaction splitting.

Finite-volume balances
-----------------------

Integrating a component balance over cell :math:`c` gives the
backward-Euler residual

.. math::
   :label: finite-volume-residual

   R_{i,c}
   =\frac{\mathcal M_{i,c}^{n+1}-\mathcal M_{i,c}^{n}}{\Delta t}
     +\sum_{f\in\partial c}F_{i,cf}^{n+1}
     -Q_{i,c}^{n+1}-\mathcal R_{i,c}^{n+1}=0 .

:math:`\mathcal M` is cell component mass, :math:`F` is an
outward-oriented face mass rate and :math:`Q,\mathcal R` are cell
external/reaction mass rates. Boundary faces use the prescribed boundary
conditions; each internal face contributes equal and opposite rates to
its two neighboring cells.

For the standard two-point flux approximation (TPFA), a phase volume
rate from cell :math:`c` to neighboring cell :math:`d` has the form

.. math::
   :label: tpfa-phase-flux

   v_{\alpha,cd}
   =T_{cd}\lambda_{\alpha,\mathrm{up}}
      \left[p_{\alpha,c}-p_{\alpha,d}
      -\rho_{\alpha,f}\mathbf g\cdot
       (\mathbf x_c-\mathbf x_d)\right].

:math:`T_{cd}` incorporates permeability and grid geometry;
phase-potential upwinding selects mobility and transported composition.
Component advective mass rates are assembled from phase rates,
densities and mass fractions. Diffusive conductances use the effective
coefficients and harmonic half-face construction; component diffusion
also applies the zero-net-phase-mass correction.

TPFA is most accurate on grids compatible with the permeability tensor.
Using a PEBI grid does not establish accuracy for arbitrary anisotropy
or distorted cells. Grid refinement and timestep refinement remain
separate checks from nonlinear convergence.

Nonlinear solution
-------------------

For the fully implicit base biochemistry model, component, population,
enabled tracer and facility residuals are assembled into one nonlinear
system. Automatic differentiation forms the Jacobian:

.. math::
   :label: newton-update

   \mathbf J(\mathbf U^{(k)})\,\delta\mathbf U^{(k)}
      =-\mathbf R(\mathbf U^{(k)}),\qquad
   \mathbf U^{(k+1)}=\mathbf U^{(k)}+\delta\mathbf U^{(k)} .

The compositional primary variables include pressure, independent
overall component fractions, enabled populations/tracers and facility
unknowns. Flash calculations supply phase compositions and amounts.
Update limits, composition floors, population bounds, timestep cuts and
convergence tolerances are model/solver settings; the expression above
does not imply an unconstrained Newton update.

``setupOptimizedLinearSolver`` can select the optional AMGCL path.
Its block treatment retains the compositional, bacterial and
aqueous-tracer cell unknowns together. A serial solver path remains
available. See :doc:`installation` for dependencies and configuration.

Wells and operating schedules
-----------------------------

For a simple well connection :math:`k`, MRST's pressure drawdown is

.. math::
   :label: well-drawdown

   \Delta p_k=p_k-(p_{\mathrm{bh}}+\Delta p_k^{\mathrm{well}}).

Here :math:`p_{\mathrm{bh}}` is bottom-hole pressure and
:math:`\Delta p_k^{\mathrm{well}}` is the connection pressure correction
stored as ``wellSol.cdp``. For a producing connection, a phase-rate
contribution has the form

.. math::

   q_{\alpha,k}=-WI_k\lambda_{\alpha,k}\Delta p_k .

The sign convention is positive into the reservoir. Injecting connections
use total mobility with the configured injection/crossflow phase mixture;
conversion to surface or component rates depends on the fluid model.
The well index :math:`WI_k` comes from completion geometry and rock
properties. Rate or BHP controls, limits and connection status complete
the well equations.

Storage schedules change controls between injection, shut-in and
withdrawal. A rate target is not a guarantee of achieved flow when a
pressure limit is active.

.. note::

   An inactive saved well record may retain an earlier BHP. The storage
   gallery renderers do not treat that retained value as a new pressure
   solution. The aquifer's single-completion, zero-correction diagnostic
   uses the saved completion pressure. The depleted-reservoir renderer
   uses a local zero-net-reservoir-volume balance over its eight
   completions. That diagnostic is not a coupled zero-surface-rate rerun;
   potential completion crossflow is not fed back into saved states.
   The supported configurations and residual checks are recorded in the
   corresponding gallery provenance files.

PHREEQC coupling
-----------------

The following operator notation makes the ordering explicit.
:math:`\mathcal F_{\Delta t}` advances flow/transport,
:math:`\mathcal K_{\Delta t}` advances H2sim local kinetics, and
:math:`\mathcal C_{\Delta t}` applies the configured PHREEQC kinetic and
equilibrium calculation. :math:`\mathcal E` is aqueous/mineral
equilibrium without PHREEQC microbial kinetics.

Compositional PHREEQC
~~~~~~~~~~~~~~~~~~~~~

The compositional backend first obtains a converged MRST transport
state, then advances cell-local PHREEQC chemistry:

.. math::
   :label: compositional-phreeqc-split

   \mathbf U^*=\mathcal F_{\Delta t}(\mathbf U^n),\qquad
   \mathbf U^{n+1}=\mathcal C_{\Delta t}(\mathbf U^*).

Overlapping in-step MRST microbial conversion/growth/decay sources are
disabled, avoiding double counting. PHREEQC kinetic substeps, input
normalization and configured mineral/speciation calculations belong to
:math:`\mathcal C`. The coupling converts between EOS inventories and
aqueous molalities, maps outputs back to cells and restores an EOS-consistent
state. This local chemistry call includes a fixed-volume PHREEQC gas
phase; it is not the aqueous-only handoff used below.

The chemistry is cell-local; PHREEQC does not discretize the reservoir's
spatial transport. Selected-output and element-audit diagnostics must
be inspected separately from the converged MRST flow report.

Multirate aqueous equilibrium
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``SequentialBiochemistryPhreeqcModel`` solves one coarse flow/transport
stage with biological reactions disabled, then partitions that duration:

.. math::
   :label: multirate-substeps

   N=\left\lceil\frac{\Delta t}{\Delta t_{\mathrm{react,max}}}\right\rceil,
   \qquad \delta t=\frac{\Delta t}{N}.

Starting from :math:`\mathbf U^{(0)}=\mathcal F_{\Delta t}(\mathbf U^n)`,
the local substeps are

.. math::
   :label: multirate-split

   \mathbf U^{(m+1)}
      =\mathcal E\!\left(
          \mathcal K_{\delta t}(\mathbf U^{(m)})\right),
   \quad m=0,\ldots,N-1,\qquad
   \mathbf U^{n+1}=\mathbf U^{(N)} .

The local integrator freezes kinetic coefficients over a substep,
integrates candidate growth/decay analytically and limits reaction
extents against available hydrogen, carbon and sulfate before updating
inventories. It is a bounded local update, **not** the global implicit
Newton solve used by the base model. Wells, boundary sources and spatial
fluxes are absent from this reaction stage.

PHREEQC then updates aqueous/mineral equilibrium and refreshes the
chemistry feedback. This path supplies no PHREEQC ``RATES`` or
``KINETICS`` blocks: microbial kinetics remain H2sim-owned.
There is no outer Picard iteration in this multirate model. The separate
``simulateSequentialH2BiochemPhreeqc`` driver is an outer Picard workflow,
not the same algorithm.

Splitting error and conservation checks
----------------------------------------

The sequential order above introduces splitting error. Reducing
:math:`\delta t` refines local reaction integration, but does not by
itself remove the coarse flow-reaction splitting error associated with
:math:`\Delta t`. Comparing backend results also changes kinetic
ownership, biomass conventions and sometimes reaction parameters.
Such a comparison is not a temporal-convergence study.

For a non-reactive closed domain, component totals should remain
constant. For an open or reactive domain, compare inventory changes
with integrated well/boundary exchanges and reaction sources.
Phase transfer must not be counted as destruction of a component.
For reactive chemistry, audit elemental totals across gas, liquid,
aqueous tracers and minerals; individual molecular species need not
be conserved.

Saved nonlinear convergence does not establish a successful chemistry
element audit. The measured discrepancies and audit failures on
:doc:`phreeqc` and :doc:`verification` remain limitations of those
recorded runs, not exceptions to the conservation equations.

Implementation
---------------

* `BiochemistryModel <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/models/BiochemistryModel.m>`_:
  fully implicit residual assembly.
* `SequentialBiochemistryPhreeqcModel <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/models/SequentialBiochemistryPhreeqcModel.m>`_:
  coarse-flow/local-reaction stage construction and ordering.
* `advanceSequentialBiochemistryLocalReaction <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/utils/advanceSequentialBiochemistryLocalReaction.m>`_:
  resource-bounded reaction extents.
* :doc:`reference`: coupling configuration, source units and output contracts.
* :doc:`phreeqc`: executable backend comparisons and interpretation.

MRST discretization and AD background is available in
:cite:`lie2019introduction,moyner2021compositional`.
