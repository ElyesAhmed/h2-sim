Black-oil model
================

The hydrogen-brine black-oil formulation follows
:cite:`AHMED2024104772`. It represents two phases and two
pseudo-components: an aqueous phase dominated by the heavy brine
component, and a gas phase dominated by the light hydrogen component.
The historical MRST ``oil`` phase label denotes brine here, not petroleum.

Unlike the :doc:`compositional-model`, this formulation uses tabulated
phase properties and mutual-solubility ratios rather than solving a
multicomponent EOS flash during flow. It is suitable for the supplied
hydrogen-brine :doc:`store` and :doc:`hydrogen-anticline` workflows,
but does not resolve a changing H2/CO2/CH4 gas mixture.

PVT variables and surface conditions
------------------------------------

The formulation assumes surface reference conditions at which the
aqueous and gas components can be represented separately. Let
:math:`\rho_b^s,\rho_h^s` be their surface mass densities. The inverse
formation-volume factors :math:`b_l,b_g`, solution ratio :math:`R_s`
and vaporization ratio :math:`R_v` give the reservoir phase densities:

.. math::
   :label: blackoil-densities

   \rho_l=b_l(\rho_b^s+R_s\rho_h^s),\qquad
   \rho_g=b_g(\rho_h^s+R_v\rho_b^s).

:math:`R_s` is the volume of liberated surface gas per volume of
remaining surface brine when reservoir liquid is brought to surface
conditions. :math:`R_v` is the condensed surface-liquid volume per
surface-gas volume from the reservoir gas. Both are volume ratios using
the **same reference conditions** as the component densities.

The corresponding component mass fractions are

.. math::
   :label: blackoil-mass-fractions

   w_{h,l}=\frac{R_s\rho_h^s}{\rho_b^s+R_s\rho_h^s},
   \qquad
   w_{h,g}=\frac{\rho_h^s}{\rho_h^s+R_v\rho_b^s}.

Brine mass fractions follow from :math:`w_{b,\alpha}=1-w_{h,\alpha}`.
Setting :math:`R_s=R_v=0` gives the immiscible limit.
The enabled dissolution/vaporization options and interpolation of
undersaturated properties must match the supplied tables.

Component balances
-------------------

Using surface-equivalent component volumes, the brine and hydrogen
balances are

.. math::
   :label: blackoil-brine

   \frac{\partial}{\partial t}
      \left[\phi(b_l S_l+R_v b_g S_g)\right]
   +\nabla\cdot
      \left(b_l\mathbf u_l+R_v b_g\mathbf u_g\right)
   =q_b^s,

.. math::
   :label: blackoil-hydrogen

   \frac{\partial}{\partial t}
      \left[\phi(b_g S_g+R_s b_l S_l)\right]
   +\nabla\cdot
      \left(b_g\mathbf u_g+R_s b_l\mathbf u_l\right)
   =q_h^s.

Here :math:`\phi=\phi_0 m_\phi` can include a pressure-dependent
pore-volume multiplier :math:`m_\phi`. The sources
:math:`q_b^s,q_h^s` are surface volume per bulk reservoir volume per
second. Multiplication by the respective surface density converts each
equation to a component mass balance. Sources are positive for
injection; this choice is equivalent to moving a positive sink term
from the left side of the paper's balance to the right.

The liquid and gas velocities obey

.. math::
   :label: blackoil-darcy

   \mathbf u_\alpha
     =-\mathbf K\frac{k_{r\alpha}}{\mu_\alpha}
        \left(\nabla p_\alpha-\rho_\alpha\mathbf g\right),
     \qquad \alpha\in\{l,g\},

with

.. math::

   S_l+S_g=1,\qquad p_g-p_l=p_c(S_l).

We use the gas-minus-liquid capillary-pressure convention on these
pages. A paper, deck or fluid function using liquid-minus-gas pressure
needs the corresponding sign conversion.
Relative permeability, capillary pressure, rock regions, initial state
and boundary/well controls complete the problem.

The selected aquifer case enables hydrogen dissolution and disables
vaporized water, so :math:`R_v=0` there. Dissolved hydrogen moves with
liquid and remains part of the total hydrogen inventory. During pressure
decline it can exsolve; dissolution is not an irreversible reaction.
MRST handles the appropriate saturated/undersaturated states and phase
appearance/disappearance.

Molecular diffusion
--------------------

The paper also considers component diffusion. A phase-wise Fickian
description uses

.. math::

   \mathbf j^{\mathrm{mass}}_{i\alpha}
      =-\rho_\alpha D^{\mathrm{eff}}_{i\alpha}
         \nabla w_{i\alpha}.

The effective coefficient includes the selected pore-space/tortuosity
factors. To add such a **mass** flux to a surface-volume balance, divide
it by the corresponding component surface density:

.. math::

   \mathbf j_i^s
      =\frac{\sum_\alpha\mathbf j^{\mathrm{mass}}_{i\alpha}}
             {\rho_i^s}.

The selected 2D aquifer gallery disables diffusion. Its PVT dissolution
therefore must not be interpreted as evidence that molecular diffusion
is active. The corrected compositional diffusion implementation is
described separately in :doc:`compositional-model`.

From phase behavior to flow tables
----------------------------------

The practical route is to evaluate gas-liquid partitioning with the
selected property model, combine it with component density/viscosity
data, and generate matching black-oil tables. :doc:`phase-behavior`
explains the thermodynamic closure; :doc:`thermodynamics` provides
the runnable tabulation example.

The available ePC-SAFT values are bundled reference data, not a live
solver shipped with H2sim. This distinction matters when reproducing
the paper's property comparisons.

Implementation and examples
----------------------------

* `modelForSimple2DAquifer <https://github.com/sintefmath/h2-sim/blob/master/h2-store/utils/modelForSimple2DAquifer.m>`_:
  ``GenericBlackOilModel``, aqueous/oil-slot mapping, dissolution and gravity.
* :doc:`store`: layered aquifer, operating schedule, inventories and
  surface-equivalent dissolved-hydrogen metric.
* :doc:`hydrogen-anticline`: anticlinal storage and dissolution options.
* :doc:`numerical-methods`: finite-volume residuals, upwinding, Newton
  iterations and well controls.
