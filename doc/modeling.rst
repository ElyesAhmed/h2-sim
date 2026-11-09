Mathematical models
===================

H2sim models hydrogen storage by combining multiphase flow, component
transport, phase equilibrium and, when selected, microbial or geochemical
reactions. These pages describe the equations and their connection to the
implementation. For runnable cases and dependencies, start with
:doc:`model-selection`.

The formulation is organized into four model sections: **black-oil**,
**compositional flow**, **biochemistry** and **geochemistry**. The first
two describe alternative fluid-flow formulations; biochemistry and
geochemistry add reaction processes to compositional transport.

The storage examples use a porous-medium, Darcy-scale description with
prescribed temperature. They do **not** solve a thermal-energy balance or
rock-mechanics equations. Adding PHREEQC changes the chemical closure and
reaction integration; it does not replace MRST's flow equations.

.. list-table:: Formulations at a glance
   :header-rows: 1
   :widths: 23 43 34

   * - Formulation
     - Conserved quantities
     - Closure / reaction ownership
   * - Black-oil storage
     - Brine and hydrogen pseudo-components, including dissolved hydrogen
     - Supplied PVT and saturation-function tables
   * - Compositional flow
     - Individual EOS components, such as H2, CO2 and CH4
     - Gas-liquid flash with the selected equation of state
   * - Compositional biochemistry
     - EOS components, population variables and enabled aqueous tracers
     - MRST-assembled Monod growth, decay and conversion sources
   * - Compositional PHREEQC
     - MRST transport inventories followed by cell-local chemical updates
     - PHREEQC kinetics, speciation and configured minerals
   * - Multirate PHREEQC
     - Coarse flow/transport followed by local reaction substeps
     - H2sim kinetics; aqueous/mineral PHREEQC equilibrium after each substep

.. toctree::
   :maxdepth: 1

   black-oil-model
   compositional-model
   biochemistry-model
   geochemistry-model

Shared details are collected in :doc:`phase-behavior` and
:doc:`numerical-methods`.

Reading the equations
----------------------

The notation is shared across these pages. Sources are positive when they
add material to the reservoir. Unless stated otherwise, densities and
fractions refer to the **fluid phase**, while accumulation and reaction
sources are expressed per bulk reservoir volume.

.. list-table:: Main symbols and SI units
   :header-rows: 1
   :widths: 22 53 25

   * - Symbol
     - Meaning
     - Unit
   * - :math:`\phi`, :math:`S_\alpha`
     - Porosity; fraction of pore volume occupied by phase :math:`\alpha`
     - Dimensionless
   * - :math:`\mathbf K`
     - Absolute-permeability tensor
     - :math:`\mathrm{m^2}`
   * - :math:`p_\alpha`, :math:`T`
     - Phase pressure; prescribed temperature
     - Pa; K
   * - :math:`\rho_\alpha`, :math:`\mu_\alpha`
     - Phase mass density; dynamic viscosity
     - :math:`\mathrm{kg/m^3}`; :math:`\mathrm{Pa\,s}`
   * - :math:`\mathbf u_\alpha`
     - Darcy velocity, per bulk cross-sectional area
     - :math:`\mathrm{m/s}`
   * - :math:`w_{i\alpha}`, :math:`x_i`, :math:`y_i`, :math:`z_i`
     - Phase mass fraction; liquid, gas and overall mole fractions
     - Dimensionless
   * - :math:`q_i`, :math:`r_i`
     - External and reaction mass sources for component :math:`i`
     - :math:`\mathrm{kg/(m^3\,s)}`
   * - :math:`c_a`
     - Non-EOS aqueous tracer concentration
     - :math:`\mathrm{mol/m^3}` of liquid
   * - :math:`n_j`
     - Microbial population variable stored as ``nbact``
     - Model-normalized; see :doc:`biochemistry-model`

In MATLAB, ``oil`` or ``O`` can identify the **aqueous liquid phase** in a
two-phase compositional or black-oil setup. This software label does not
mean that the example contains petroleum. Use the model's liquid/vapor
indices rather than assuming a phase-column order.

Scope and interpretation
------------------------

Transport switches, capillary pressure, boundary conditions, mineral
inventories and well controls belong to the individual setup. A model's
capability is not evidence that a process is enabled in a displayed example.
The equations below explain the formulations; they are not a claim of
parameter calibration, grid convergence or site-scale predictive accuracy.
Recorded checks and limitations are collected in :doc:`verification`.

Background on the MRST flow and compositional frameworks is given in
:cite:`lie2019introduction,moyner2021compositional`. The hydrogen-brine
black-oil formulation is discussed in :cite:`AHMED2024104772`, and the
coupled compositional/biochemical formulation in :cite:`AHMED2025150947`.
The model sections use those papers as the starting point and identify
current code conventions where a direct transcription would be misleading.
