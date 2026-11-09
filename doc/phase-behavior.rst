Phase behavior and fluid properties
===================================

The flow equations need phase amounts, compositions, densities,
viscosities and mobilities. H2sim supplies these through an EOS flash or
precomputed black-oil tables. These are different closures of the
:doc:`compositional-model` and :doc:`black-oil-model`, not
interchangeable property settings.
The comparison plots and tabulation commands are in :doc:`thermodynamics`.

Gas-liquid equilibrium
----------------------

For a two-phase compositional mixture, local equilibrium equates component
fugacities:

.. math::
   :label: fugacity-equilibrium

   f_i^l(p,T,\mathbf x)=f_i^g(p,T,\mathbf y),\qquad
   f_i^l=x_i\widehat\varphi_i^l p,\qquad
   f_i^g=y_i\widehat\varphi_i^g p .

Here :math:`\widehat\varphi_i^\alpha` is a fugacity coefficient, not
porosity. The flash uses the thermodynamic pressure :math:`p` supplied to
the EOS. A capillary correction to the phase-equilibrium fugacities is
not implied by this expression; phase-pressure differences used in Darcy
flow are handled separately by the flow model.

With vapor mole fraction :math:`\beta`, material balance and
normalization require

.. math::
   :label: flash-material-balance

   z_i=(1-\beta)x_i+\beta y_i,\qquad
   \sum_i x_i=\sum_i y_i=\sum_i z_i=1.

For a two-phase flash, define :math:`K_i=y_i/x_i`. The associated
Rachford-Rice relation is

.. math::
   :label: rachford-rice

   \sum_i\frac{z_i(K_i-1)}{1+\beta(K_i-1)}=0.

MRST's EOS framework also performs phase-stability checks and handles
single-phase states. The vapor mole fraction is **not** gas saturation:
if :math:`\bar v_l,\bar v_g` are phase molar volumes, then

.. math::
   :label: mole-fraction-to-saturation

   S_g=\frac{\beta\bar v_g}
   {(1-\beta)\bar v_l+\beta\bar v_g}.

Component mass fractions in the conservation and diffusion equations are
obtained from the phase mole fractions. For example,

.. math::

   w_{il}=\frac{x_i M_i}{\sum_k x_k M_k},
   \qquad
   w_{ig}=\frac{y_i M_i}{\sum_k y_k M_k},

where :math:`M_i` is component molar mass.

Soreide-Whitson and Peng-Robinson
-------------------------------------------

``SoreideWhitsonEos`` extends MRST's Peng-Robinson EOS. The underlying
cubic pressure-volume relation has the form

.. math::
   :label: peng-robinson

   p=\frac{RT}{\bar v-b}
     -\frac{a}{\bar v(\bar v+b)+b(\bar v-b)} .

The mixture parameters use component properties and binary interactions:

.. math::

   a_\alpha=\sum_i\sum_k
       \xi_{i\alpha}\xi_{k\alpha}
       \sqrt{a_i a_k}(1-k_{ik}^{\alpha}),\qquad
   b_\alpha=\sum_i\xi_{i\alpha}b_i ,

with :math:`\boldsymbol\xi_l=\mathbf x` and
:math:`\boldsymbol\xi_g=\mathbf y`.
The Soreide-Whitson implementation modifies the liquid-water attraction
parameter and liquid interaction coefficients to account for salt
molality. Vapor properties use the vapor mixing path. Inspect the
configured mixture and interactions before comparing an SW calculation
with a generic PR calculation.

The resulting compressibility factor :math:`Z_\alpha` gives

.. math::

   \rho_\alpha
   =\frac{p\,\overline M_\alpha}{Z_\alpha RT},\qquad
   \overline M_\alpha=\sum_i \xi_{i\alpha}M_i .

Density, viscosity and relative permeability are distinct closures:
choosing an EOS does not by itself specify the viscosity correlation or
the rock's saturation functions. The selected examples provide those
through their MRST fluid models.

The SW formulation and hydrogen-water applications are described in
:cite:`soreide1992peng,chabab2020measurements,AHMED2024104772`.
H2sim also exposes MRST's PR model for suitable compositional mixtures.
Neither model is automatically calibrated for every gas/brine composition.

Hydrogen solubility and salinity
--------------------------------

The ``HenrySetschenowH2BrineEos`` property utility evaluates a
hydrogen-solubility correlation:

.. math::
   :label: henry-setschenow

   x_{\mathrm{H_2}}=
   \frac{p_{\mathrm{H_2}}}{k_H(T)}
   \exp\left(0.0185\,m_{\mathrm{NaCl}}^2
                  -0.3019\,m_{\mathrm{NaCl}}\right).

Here :math:`p_{\mathrm{H_2}}` is **hydrogen partial pressure** in Pa,
:math:`m_{\mathrm{NaCl}}` is NaCl molality in mol/kg water, and
:math:`k_H(T)` is the temperature-dependent coefficient used in the
implementation, with matching pressure units. The numerical coefficients
assume those molality units. This utility supplies dissolved-hydrogen
mole fractions; it is not a multicomponent flash and does not predict
water content in the gas.

Other supported property calculations include the Redlich-Kwong
solubility-table route and bundled ePC-SAFT reference tables. The latter
are comparison data, **not an included live PC-SAFT solver**.
The ranges and assumptions of each correlation/reference must be checked
before extrapolation.

Black-oil PVT closure
---------------------

Black-oil flow reads tabulated formation-volume factors,
solution/vaporization ratios and viscosities:

.. math::

   B_\alpha=\frac{V_\alpha^{\mathrm{reservoir}}}
                  {V_\alpha^{\mathrm{surface}}},
   \qquad b_\alpha=B_\alpha^{-1}.

:math:`R_s` describes dissolved hydrogen and :math:`R_v` describes
vaporized water, using the corresponding surface-volume conventions.
The table-generation workflow obtains pure-component properties and
phase partitioning at matching temperature/pressure samples, then
exports the requested ``PVTO``, ``PVDO`` and ``PVTG`` data.
During the supplied aquifer run these tables are read from the deck;
the EOS is not rerun as a separate flash in every reservoir cell.

For inventories, free and dissolved hydrogen must use the **same
surface conditions**. A dissolved fraction of retained inventory is
not the same quantity as consumption divided by injected hydrogen.
See the dissolution definition on :doc:`store`.

EOS and aqueous chemistry have different roles
----------------------------------------------

In the reservoir solve, the EOS supplies the gas-liquid split.
The multirate equilibrium call is aqueous-only and leaves that split
to the EOS. The compositional PHREEQC kinetic call also supplies a
local gas phase and repartitions the passed volatile inventory before
reconstructing an EOS-consistent reservoir state.
PHREEQC supplies the selected aqueous speciation, acid-base equilibria,
mineral changes and, for one backend, microbial kinetics.
Aqueous analytical totals such as sulfate are not made EOS components
merely because their concentrations affect reaction rates.

Implementation
---------------

* `SoreideWhitsonEos <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/models/eos/SoreideWhitsonEos.m>`_:
  liquid-water mixing, salt corrections and inherited flash operations.
* `HenrySetschenowH2BrineEos <https://github.com/sintefmath/h2-sim/blob/master/h2-store/thermodynamics/HenrySetschenowH2BrineEos.m>`_:
  the partial-pressure solubility correlation.
* :doc:`thermodynamics`: RK/SW/PR comparisons and black-oil PVT generation.

See :doc:`geochemistry-model` for the different volatile-inventory handoffs.
Continue with :doc:`biochemistry-model` for reaction terms or
:doc:`numerical-methods` for coupling order.
