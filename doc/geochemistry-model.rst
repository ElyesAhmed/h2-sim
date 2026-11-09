Geochemistry
=============

Geochemistry adds aqueous speciation, acid-base reactions and configured
mineral dissolution/precipitation to the compositional and microbial
models. It is a **cell-local chemical calculation**, coupled to MRST's
reservoir transport. It is not a replacement for the
:doc:`compositional-model` or an additional copy of its reaction sources.

H2sim uses PHREEQC with the bundled ``h2_biogeochemistry.dat`` database.
The selected inventory, redox bookkeeping and activity model define the
chemical problem. The storage examples and backend comparisons are on
:doc:`phreeqc`. The published compositional/biochemical starting point is
:cite:`AHMED2025150947`; the PHREEQC framework and a related UHS
coupling approach are described in :cite:`parkhurst1999user,shojaee2025new`.

Aqueous mass action and activities
----------------------------------

For an equilibrium reaction :math:`r` written with signed species
coefficients :math:`\nu_{sr}`, mass action requires

.. math::
   :label: aqueous-mass-action

   K_r(T,p)=\prod_s a_s^{\nu_{sr}},
   \qquad a_s=\gamma_s\frac{m_s}{m^\circ}.

:math:`m_s` is aqueous molality in mol/kg water,
:math:`m^\circ=1\ \mathrm{mol/kgw}` is the standard molality,
and :math:`\gamma_s` is the activity coefficient from the selected
database/activity formulation. Activity is dimensionless.
Water activity is treated according to that formulation, rather than
being identified with a solute molality.

Representative equilibria are

.. math::
   :label: aqueous-speciation

   \begin{aligned}
   \mathrm{H_2O}
     &\rightleftharpoons \mathrm{H^+}+\mathrm{OH^-},\\
   \mathrm{CO_2(aq)}+\mathrm{H_2O}
     &\rightleftharpoons \mathrm{H^+}+\mathrm{HCO_3^-},\\
   \mathrm{HCO_3^-}
     &\rightleftharpoons \mathrm{H^+}+\mathrm{CO_3^{2-}},\\
   \mathrm{H_2S(aq)}
     &\rightleftharpoons \mathrm{H^+}+\mathrm{HS^-}.
   \end{aligned}

These reactions redistribute an analytical total among species.
For example, dissolved inorganic carbon is not just free CO2:

.. math::

   m_{\mathrm{DIC}}
     =m_{\mathrm{CO_2(aq)}}+m_{\mathrm{HCO_3^-}}
      +m_{\mathrm{CO_3^{2-}}}
      +\text{carbon in aqueous complexes}.

The hydrogen-ion activity defines :math:`\mathrm{pH}=-\log_{10}a_{\mathrm{H^+}}`.
Changing pH changes substrate availability and sulfide speciation, even
when the corresponding analytical total is unchanged.

Element and charge bookkeeping
-------------------------------

Let :math:`W` be the cell's liquid-water mass in kg, :math:`A_{es}`
the amount of element :math:`e` in species :math:`s`, and
:math:`n_m,n_g` mineral and gas amounts in mol. A closed local
equilibrium calculation redistributes a fixed elemental inventory:

.. math::
   :label: geochemical-element-balance

   N_e^{\mathrm{tot}}
     =W\sum_s A_{es}m_s
      +\sum_m A_{em}n_m
      +\sum_g A_{eg}n_g.

Gas terms apply only when that local chemistry workflow exchanges gas;
prescribed open reservoirs or kinetic transfers need their corresponding
inventory terms. Ionic charge is

.. math::

   q_{\mathrm{aq}}=\sum_s z_s^{\mathrm{ion}}m_s,

where :math:`z_s^{\mathrm{ion}}` is ionic charge, not overall
composition. Electroneutral input has :math:`q_{\mathrm{aq}}=0`;
the PHREEQC input determines whether a component or pH is adjusted to
enforce that condition. The current coupling builders write a prescribed
initial pH with ``#charge`` commented out. They must not be interpreted
as automatically charge-balancing the initial solution by adjusting pH.
The transported analytical totals and PHREEQC's selected outputs provide
the basis for element/charge diagnostics.

Mineral equilibrium
--------------------

For mineral :math:`m`, the saturation index is

.. math::
   :label: mineral-saturation

   SI_m=\log_{10}
       \left(\frac{\mathrm{IAP}_m}{K_m}\right).

:math:`\mathrm{IAP}_m` is the ion-activity product of the dissolution
reaction and :math:`K_m` its equilibrium constant.
A present equilibrium mineral at a zero target saturation index has
:math:`SI_m=0`. A finite mineral inventory can be exhausted; equilibrium
does not provide an unlimited source of carbon, sulfate or cations.
Whether precipitation is permitted is controlled by the phase
definition and coupling input.

Examples of dissolution reactions are

.. math::

   \begin{aligned}
   \mathrm{CaCO_3(s)}
     &\rightleftharpoons\mathrm{Ca^{2+}}+\mathrm{CO_3^{2-}},\\
   \mathrm{CaMg(CO_3)_2(s)}
     &\rightleftharpoons\mathrm{Ca^{2+}}+\mathrm{Mg^{2+}}
                       +2\,\mathrm{CO_3^{2-}},\\
   \mathrm{CaSO_4(s)}
     &\rightleftharpoons\mathrm{Ca^{2+}}+\mathrm{SO_4^{2-}}.
   \end{aligned}

Calcite and dolomite can buffer inorganic carbon and pH. Anhydrite can
replenish sulfate used by SRB. The mineral assemblage and initial
amounts are case inputs, not a universal sandstone composition.
Equilibrium phases are distinct from the optional kinetic anhydrite
source in the reduced microbial model.

Cell-local PHREEQC kinetics
----------------------------

The compositional PHREEQC backend expresses microbial rates on a
water-mass basis. With kinetic biomass amount :math:`B_j`, a
double-Monod form is

.. math::
   :label: phreeqc-monod

   \mu_j=\mu_{\max,j}
     \frac{m_{\mathrm{H_2}}}{K_{\mathrm{H_2},j}+m_{\mathrm{H_2}}}
     \frac{\widehat m_{s,j}}{K_{s,j}+\widehat m_{s,j}}
     f_{T,j}f_{\mathrm{pH},j}f_{\mathrm{TDS},j},

.. math::
   :label: phreeqc-kinetics

   r_{\mathrm{H_2},j}^{w}
      =\frac{\mu_j B_j}{Y_j},\qquad
   \frac{\mathrm d B_j}{\mathrm dt}
      =Y_j r_{\mathrm{H_2},j}^{w}-b_j B_j .

:math:`B_j` is mol of kinetic biomass per kg water,
:math:`Y_j` is mol biomass per mol consumed H2 and
:math:`r_{\mathrm{H_2},j}^{w}` is
:math:`\mathrm{mol\ H_2/(kgw\,s)}`.
The implemented kinetic blocks use dissolved H2 molality and total
carbonate(4) for MET/ACE; the SRB co-substrate factor uses the free
sulfate-species molality. Temperature, pH and total dissolved solids
modify growth through population-specific response functions.
Biomass caps and substrate inventories also constrain the update.

These concentration and biomass bases differ from the
:doc:`biochemistry-model`. Substituting a mole-fraction half-saturation
constant into a molality law, or transferring a yield without its
population conversion, changes the model.

What each coupling workflow exchanges
--------------------------------------

.. list-table:: Chemical ownership and gas handoff
   :header-rows: 1
   :widths: 24 36 40

   * - Workflow
     - Microbial reactions
     - Local gas-liquid treatment
   * - Compositional PHREEQC
     - PHREEQC ``RATES`` / ``KINETICS``; overlapping MRST sources disabled
     - Fixed-volume PHREEQC gas phase repartitions passed volatile totals;
       the reservoir state is subsequently reconstructed with the EOS
   * - Multirate PHREEQC
     - H2sim bounded local kinetics between coarse flow steps
     - Aqueous/mineral equilibrium only, without ``GAS_PHASE``;
       gas-liquid partitioning stays with the EOS

In the compositional kinetic call, volatile inventories include the
passed gas and dissolved shares, normalized per kg water. It is
incorrect to describe that local calculation as aqueous-only.
In the multirate equilibrium call, only the **dissolved** CO2 and H2S
shares contribute to the aqueous carbon and sulfide handoff. H2, CH4
and N2 are not exchanged with PHREEQC in that equilibrium call.
Keeping the multirate call aqueous-only avoids repeatedly repartitioning
gas with two competing phase models and spuriously driving mineral
dissolution.

The update is a local map of transported/ reacted fluid state, aqueous
totals and mineral amounts:

.. math::
   :label: geochemical-map

   (\mathbf U^+,\mathbf C^+,\mathbf n_m^+)
      =\mathcal E_{\mathrm{ph}}
          (\mathbf U^*,\mathbf C^*,\mathbf n_m^*).

The map adds no second microbial source when it is an equilibrium-only
call. :doc:`numerical-methods` specifies the ordering of flow,
kinetics, equilibrium and multirate substeps.

Implementation and limits
--------------------------

* `runSequentialCompositionalPhreeqcCoupling <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/utils/runSequentialCompositionalPhreeqcCoupling.m>`_:
  kinetic blocks, unit-water basis, volatile gas handoff and selected outputs.
* `runSequentialH2BiochemPhreeqcEquilibrium <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/utils/runSequentialH2BiochemPhreeqcEquilibrium.m>`_:
  aqueous-only equilibrium, mineral inventory and feedback.
* `h2_biogeochemistry.dat <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/database/h2_biogeochemistry.dat>`_:
  species, equilibrium constants and activity parameters.

Local element audits and reservoir inventory checks are necessary:
nonlinear convergence of flow is not evidence that the chemical handoff
conserves every element. The recorded :doc:`phreeqc` comparisons retain
their measured audit failures and splitting limitations.
Neither mineral speciation nor a porosity modifier alone constitutes a
coupled geomechanical model.

.. toctree::
   :hidden:

   numerical-methods
