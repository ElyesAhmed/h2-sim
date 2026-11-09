Compositional model
====================

Hydrogen may occupy a gas phase, dissolve in brine, mix with residual gases
and undergo chemical conversion. The equations conserve components across
phases: **dissolution alone is not a sink of total hydrogen**.
Notation and model scope are defined in :doc:`modeling`.

The overall-composition formulation follows the compositional model in
:cite:`AHMED2025150947`, with pressure and independent overall **mole
fractions** as flow primary variables. The conserved quantities below
are **component masses**. Phase and overall mass fractions must therefore
be distinguished from the mole fractions used by the flash.

Component conservation
----------------------

For component :math:`i`, the mass balance is

.. math::
   :label: component-conservation

   \frac{\partial}{\partial t}
   \left(\phi\sum_\alpha S_\alpha\rho_\alpha w_{i\alpha}\right)
   + \nabla\cdot
   \left(\sum_\alpha
     \left[\rho_\alpha w_{i\alpha}\mathbf u_\alpha
           + \mathbf J_{i\alpha}\right]\right)
   = q_i + r_i .

The phases present in the selected model are indexed by :math:`\alpha`.
:math:`\mathbf J_{i\alpha}` is a non-advective mass flux
(:math:`\mathrm{kg/(m^2\,s)}`); it is zero when diffusion and dispersion
are disabled. Wells and imposed boundary/source terms contribute to
:math:`q_i`. Microbial conversion contributes to :math:`r_i`, using the
normalization described in :doc:`biochemistry-model`. An abiotic,
non-reactive case has :math:`r_i=0`.

Phase transfer changes :math:`S_\alpha` and :math:`w_{i\alpha}`, not the
total component inventory. Local gas-liquid equilibrium supplies the
partition between phases, as described in :doc:`phase-behavior`.

Overall composition
--------------------

Define mixture mass density and overall mass fraction by

.. math::
   :label: overall-mass-composition

   \rho_t=\sum_\alpha S_\alpha\rho_\alpha,\qquad
   W_i=\frac{\sum_\alpha S_\alpha\rho_\alpha w_{i\alpha}}{\rho_t}.

Then accumulation in :eq:`component-conservation` is
:math:`\partial_t(\phi\rho_t W_i)`.
The EOS instead uses the overall mole fraction

.. math::

   z_i=\frac{W_i/M_i}{\sum_k W_k/M_k},
   \qquad
   W_i=\frac{z_i M_i}{\sum_k z_k M_k},

where :math:`M_i` is component molar mass.
Using :math:`\rho_t z_i` as a component **mass** density without this
conversion would mix molar and mass bases.

Darcy flow and saturation closure
---------------------------------

Each mobile phase follows Darcy's law,

.. math::
   :label: darcy-flow

   \mathbf u_\alpha =
   -\mathbf K\lambda_\alpha
   \left(\nabla p_\alpha-\rho_\alpha\mathbf g\right),
   \qquad
   \lambda_\alpha=\frac{k_{r\alpha}}{\mu_\alpha}.

Here :math:`k_{r\alpha}` is relative permeability and :math:`\mathbf g`
is the gravity-acceleration vector. Writing gravity as a vector avoids
assuming that a particular grid coordinate is depth: the aquifer section
uses elevation increasing upward, whereas some other setups use depth.
Hydrostatic equilibrium satisfies
:math:`\nabla p_\alpha=\rho_\alpha\mathbf g`.

For a liquid-gas system,

.. math::
   :label: phase-closure

   S_l+S_g=1,\qquad
   p_g-p_l=p_c(S_l),\qquad
   \sum_i w_{i\alpha}=1.

Capillary pressure :math:`p_c` and relative-permeability curves come from
the configured fluid/saturation functions and rock regions. Setting
:math:`p_c=0` is a setup choice, not a universal H2sim assumption.
Likewise, residual saturations and any hysteresis treatment must be
established from the selected input; they are not implied by the balance law.

Compositional diffusion and dispersion
--------------------------------------

When enabled in ``BiochemistryModel``, component diffusion uses phase
**mass-fraction** gradients. In continuum notation, the implemented
flux construction is

.. math::
   :label: component-diffusion

   \mathbf j^*_{i\alpha}
     =-\rho_\alpha D^{\mathrm{eff}}_{i\alpha}
       \nabla w_{i\alpha},\qquad
   \mathbf J_{i\alpha}
     =\mathbf j^*_{i\alpha}
       -w_{i\alpha}\sum_k\mathbf j^*_{k\alpha}.

The correction enforces :math:`\sum_i\mathbf J_{i\alpha}=0` so that
diffusion redistributes components without creating a net phase mass
flux. This is a corrected Fickian approximation, not a full
Maxwell-Stefan diffusion model.

The effective coefficient includes porosity and phase saturation:

.. math::
   :label: effective-diffusivity

   D^{\mathrm{eff}}_{i\alpha}
   =\phi S_\alpha
      \left(D^{\mathrm{mol}}_{i\alpha}
            +D^{\mathrm{disp}}_\alpha\right),\qquad
   D^{\mathrm{disp}}_\alpha
   =\frac{\alpha_{L,\alpha}+2\alpha_{T,\alpha}}{3}
      \lVert\mathbf u_\alpha\rVert .

The dispersion term is the implementation's **isotropic approximation**,
using reconstructed Darcy speed and longitudinal/transverse
dispersivities :math:`\alpha_L,\alpha_T` in metres.
:math:`D^{\mathrm{mol}}` includes the configured molecular correlation
and tortuosity treatment. Numerical porosity, saturation and diffusivity
floors are detailed in :doc:`reference`.
The :doc:`hydrogen-mixing` example instead supplies its own constant
binary diffusivity; that coefficient is not the default correlation for
other models.

Aqueous tracers
----------------

Non-volatile species such as sulfate and the non-EOS sulfide pool are
carried as liquid-only tracers, rather than EOS components:

.. math::
   :label: aqueous-tracer

   \frac{\partial}{\partial t}(\phi S_l c_a)
   +\nabla\cdot\left(c_a\mathbf u_l+\mathbf J_a\right)
   =q_a+r_a,\qquad
   \mathbf J_a=-D_a^{\mathrm{eff}}\nabla c_a.

Tracer fluxes are molar, and have **no liquid-density multiplier** because
:math:`c_a` is already in mol per liquid volume. In the discrete
accumulation, the liquid saturation is floored at :math:`10^{-8}`.
Additional transported aqueous totals depend on the chemistry setup.
The diffusion/dispersion switches also control the non-advective tracer
fluxes where supported.

Initial and boundary conditions
-------------------------------

A simulation specifies initial pressure, saturations, composition and
any population/tracer fields. Boundaries may prescribe pressure with an
inflow composition, impose a flux, or remain closed. The selected aquifer
case has hydrostatic lateral pressure boundaries; the hydrogen-methane
mixing case is sealed. Boundary exchange must therefore be included when
checking an open-domain inventory.

Implementation
---------------

* `BiochemistryModel <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/models/BiochemistryModel.m>`_
  and `BiochemicalFlowDiscretization <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/statefunctions/BiochemicalFlowDiscretization.m>`_:
  component, population and tracer residual assembly.
* `ComponentPhaseDispFlux <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/statefunctions/flux/ComponentPhaseDispFlux.m>`_
  and `DispersiveDiffusivity <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/statefunctions/flux/DispersiveDiffusivity.m>`_:
  corrected component fluxes and effective coefficients.

Continue with :doc:`phase-behavior` for constitutive closure and
:doc:`numerical-methods` for the discrete fluxes and well equations.

.. toctree::
   :hidden:

   phase-behavior
