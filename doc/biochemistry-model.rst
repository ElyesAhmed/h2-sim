Biochemistry
=============

The base ``BiochemistryModel`` adds one population balance per configured
metabolic reaction to compositional flow. Hydrogen is the shared electron
donor. Reaction parameters, optional transport and biomass normalization
come from the setup; they are not universal properties of a storage site.
The selected storage comparison is on :doc:`biochem`.
The mobile-population formulation builds on
:cite:`AHMED2025150947`; the current implementation extends the
published methanogenesis model to selectable MET, ACE and SRB populations.

Reaction pathways
------------------

The supported MET, ACE and SRB pathways can be written as

.. math::
   :label: microbial-reactions

   \begin{aligned}
   \mathrm{MET:}\quad&
     4\,\mathrm{H_2}+\mathrm{CO_2}
       \longrightarrow \mathrm{CH_4}+2\,\mathrm{H_2O},\\
   \mathrm{ACE:}\quad&
     4\,\mathrm{H_2}+2\,\mathrm{CO_2}
       \longrightarrow \mathrm{CH_3COOH}+2\,\mathrm{H_2O},\\
   \mathrm{SRB:}\quad&
     4\,\mathrm{H_2}+\mathrm{SO_4^{2-}}+2\,\mathrm{H^+}
       \longrightarrow \mathrm{H_2S}+4\,\mathrm{H_2O}.
   \end{aligned}

These are net pathway stoichiometries. The base SRB model transports
sulfate and a non-volatile sulfide pool separately from the EOS.
It does **not** solve the full proton/charge/speciation system represented
by the balanced SRB reaction above. A configured volatile fraction enters
the EOS H2S component; the complementary fraction enters the aqueous
tracer. Detailed pH and mineral equilibria require the corresponding
chemistry formulation.

Background on microbial hydrogen conversion and transport is provided in
:cite:`hagemann2017-thesis,THAYSEN2021111481`. The executable parameter
database is ``bioChemFluidsStructs``; examples can override its defaults.

Population storage and normalization
------------------------------------

For population :math:`j`, the stored cell quantity is

.. math::
   :label: bacterial-storage

   M_{B,j}=PV\,\max(S_l,10^{-8})\,\rho_l n_j .

Here :math:`PV` is cell pore volume and :math:`n_j` is ``nbact``.
In the paper's normalized-population notation,
:math:`n_j=N_j/N_{\mathrm{ref},j}`. The code stores this variable as
``nbact`` and applies the density-weighted storage expression above.
Thus :math:`M_{B,j}` is a **scaled inventory**, not a direct measurement
of physical biomass. If :math:`N_j` is cells per liquid volume, physical
biomass per bulk volume would instead be
:math:`\phi S_l m_{\mathrm{cell}}N_{\mathrm{ref},j}n_j`.
Neither the plotted ``nbact`` values nor their density-weighted inventory
are calibrated cell counts without the associated reference conversion.
Changing between these conventions requires changing the associated
yield, population scale, bounds and decay parameters consistently.

Away from the numerical saturation floor, the population equation is

.. math::
   :label: bacterial-balance

   \frac{\partial}{\partial t}(\phi S_l\rho_l n_j)
   +\nabla\cdot\mathbf J_{B,j}
   =r_{B,j}+q_{B,j}.

The base internal-face population transport consists of optional
diffusion and chemotaxis, not a general liquid-advection term.
Liquid **well outflow** can nevertheless remove populations, using local
liquid density and ``nbact``; injected liquid carries no bacteria in the
current facility implementation. The PHREEQC-owned kinetic populations
are cell-local rather than spatially transported organisms.

Monod growth and decay
----------------------

For the base model, a double-Monod coefficient is

.. math::
   :label: monod-growth

   \mu_j=\mu_{\max,j}
      \frac{x_{\mathrm{H_2}}}{K_{\mathrm{H_2},j}+x_{\mathrm{H_2}}}
      \frac{\chi_j}{K_{s,j}+\chi_j}.

:math:`x_{\mathrm{H_2}}` is the liquid EOS mole fraction.
For MET and ACE, :math:`\chi_j` is the liquid CO2 mole fraction.
For SRB, it is the sulfate concentration divided by the liquid molar
density, a mole-fraction proxy. The half-saturation parameters must use
the same concentration convention. ``GrowthBactRateSRC`` returns
:math:`\mu_j` in :math:`\mathrm{s^{-1}}`, not a mass source.

Carbonate-buffered and active hybrid-chemistry configurations can replace
the CO2/sulfate proxies with their chemistry feedback and apply an
environmental response. ``CarbonLimitedGrowthRate`` additionally limits
carbon-consuming growth by the available aqueous carbon budget.
These modifications are setup/backend dependent; the simple Monod
expression alone does not include them.

The facility's unconstrained population reaction rate per cell is

.. math::
   :label: bacterial-source

   Q_{B,j}
   =(\mu_j-d_j-\varepsilon)M_{B,j},\qquad
   \varepsilon=10^{-10}\ \mathrm{s^{-1}}.

The specific decay coefficient is :math:`d_j=b_j` for first-order
decay, or :math:`d_j=b_j\max(n_j,0)` for the legacy quadratic
formulation. At the configured lower population bound, negative net
reaction sources are suppressed. This active-bound treatment and the
small regularization sink are part of the implementation, not additional
metabolic pathways.

Component conversion
---------------------

For positive molar hydrogen consumption
:math:`r_{\mathrm{H_2},j}` per bulk volume per second, the
stoichiometric mass source is

.. math::
   :label: microbial-stoichiometric-source

   r_i=M_i\sum_j
       \frac{\gamma_{ji}}{|\gamma_{j,\mathrm{H_2}}|}
       r_{\mathrm{H_2},j}.

Reactants have negative :math:`\gamma_{ji}` and products positive.
This relation connects the reaction pathways to component conservation;
the model's population/yield normalization determines the hydrogen
consumption rate.

Implementation convention
~~~~~~~~~~~~~~~~~~~~~~~~~~

Let :math:`\gamma_{ji}` be a stoichiometric coefficient, negative for
reactants, :math:`M_i` the component molar mass, :math:`Y_j` the
configured ``Y_H2`` scale, and :math:`N_j^{\mathrm{scale}}` the
configured ``nbactMax`` scale. The base conversion code constructs

.. math::
   :label: microbial-conversion

   A_j=\frac{\mu_j M_{B,j}}{Y_j},\qquad
   \widetilde Q_i
     =\sum_j
       \frac{N_j^{\mathrm{scale}}\gamma_{ji}M_i}
            {|\gamma_{j,\mathrm{H_2}}|}\,A_j .

``BactConvertionRate`` returns :math:`\widetilde Q_i`.
``BiochemistryModel`` inserts
:math:`Q_i^{\mathrm{bio}}=\widetilde Q_i/\rho_l` into the cell
component residual. Thus the corresponding bulk-volume source in the
continuum notation is
:math:`r_i=Q_i^{\mathrm{bio}}/V_{\mathrm{cell}}`.
The division by liquid density and the population/yield scales are
essential parts of the existing normalization. Raw
``BactConvertionRate`` values are **not** directly comparable with
mol/s tracer rates.

The sulfide source is partitioned between volatile EOS H2S and the
non-EOS aqueous pool. ``SRBTracerConvRate`` uses the compatible density
scaling for its molar sources. A configured anhydrite source can also
release sulfate; net sulfate production therefore does not imply a
reversal of the SRB pathway.

Optional spatial migration
---------------------------

With microbial diffusion coefficient :math:`D_{B,j}` and chemotaxis
coefficient :math:`\chi_{B,j}`, the continuum counterparts of the
implemented face fluxes are

.. math::
   :label: microbial-migration

   \mathbf J_{B,j}
   =-\rho_l\phi S_l D_{B,j}\nabla n_j
    +\rho_l\phi S_l\chi_{B,j}
       \theta_j(1-\theta_j)\nabla x_{\mathrm{H_2}},

.. math::

   \theta_j=
     \operatorname{clip}\left(\frac{n_j}{n_{\max}},0,1\right).

Diffusion follows decreasing population concentration; chemotaxis follows
increasing dissolved-H2 mole fraction. The two fluxes are added when
both switches are enabled. These terms describe a continuum migration
model, not trajectories of individual microbes. The selected five-cycle
2D bacterial/abiotic gallery disables both mechanisms.

Optional bioclogging
---------------------

``setupBioCloggingModel`` can reduce pore volume and permeability as
populations increase. Its default zero-biomass reference uses

.. math::
   :label: bioclogging

   \phi(\mathbf n)=
      \frac{\phi_0}
      {1+A\sum_j(n_j/n_{c,j})^2},\qquad
   A=1+\sum_j c_{p,j}(n_{j,0}/n_{c,j})^2,

.. math::

   \frac{K(\mathbf n)}{K_0}
     =\left(\frac{\phi(\mathbf n)}{\phi_0}\right)^3
      \left(\frac{1-\phi_0}{1-\phi(\mathbf n)}\right)^2 .

:math:`n_{c,j}` and :math:`c_{p,j}` are configured characteristic
concentrations and clogging strengths. The alternative
``reference='initial'`` multiplies the porosity numerator by
:math:`1+A\sum_j(n_{j,0}/n_{c,j})^2`, so that the initial effective
porosity equals :math:`\phi_0`.
The reference choice matters when comparing against an unclogged case.
This empirical feedback is not a resolved biofilm or geomechanics model.

Implementation and chemistry alternatives
------------------------------------------

* `GrowthBactRateSRC <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/statefunctions/flowprops/GrowthBactRateSRC.m>`_
  and `DecayBactRateSRC <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/statefunctions/flowprops/DecayBactRateSRC.m>`_:
  specific kinetic coefficients.
* `BactConvertionRate <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/statefunctions/flowprops/BactConvertionRate.m>`_
  and `BiochemistryGenericFacilityModel <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/models/BiochemistryGenericFacilityModel.m>`_:
  conversion, population and well sources.
* `setupBioCloggingModel <https://github.com/sintefmath/h2-sim/blob/master/h2-biochem/utils/setupBioCloggingModel.m>`_:
  porosity/permeability feedback and reference options.

These equations describe H2sim-owned kinetics. The compositional PHREEQC
backend instead integrates its configured kinetic laws locally and
disables the overlapping MRST reaction sources. The multirate backend
retains H2sim kinetics but uses a bounded local integrator.
See :doc:`numerical-methods` and :doc:`phreeqc` before comparing results
between these formulations.
