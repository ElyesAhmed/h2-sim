Hydrogen–methane mixing
=======================

Watch hydrogen and methane redistribute in a small sealed reservoir section.
This example adapts **Problem 2 of Okoroafor et al. (2023)**, a published
cross-simulator hydrogen-storage benchmark. Hydrogen initially occupies the
right half; methane occupies the left. Gravity and molecular diffusion act
without injection, withdrawal, water, microbial reactions or PHREEQC.

.. raw:: html

   <video controls loop muted playsinline preload="metadata" style="width:100%;max-width:1000px" poster="_static/examples/hydrogen_mixing.png" aria-label="Simulation of hydrogen and methane mixing in a sealed vertical reservoir section">
     <source src="_static/examples/hydrogen_mixing.mp4" type="video/mp4">
     <a href="_static/examples/hydrogen_mixing.gif">View the animated GIF</a>.
   </video>

Colors show **hydrogen mole fraction**, with a fixed scale from zero to one.
Depth increases downward. Frames are actual initial and accepted simulation
states. The simulated time intervals are unequal and labelled on every frame;
playback speed is not proportional to physical time. This is a mixing example,
not an injection–withdrawal cycle or a prediction for a real storage site.

Download the :download:`MP4 <_static/examples/hydrogen_mixing.mp4>` or
:download:`GIF <_static/examples/hydrogen_mixing.gif>`.
The :download:`provenance record <_static/examples/hydrogen_mixing_provenance.json>`
records parameters, component inventories and source/asset checksums.

Run and redraw
--------------

This example was added after ``v0.1.0``. Use a development checkout containing
``exampleHydrogenMixing2D``; the original ``v0.1.0`` tag does not include it.

From the repository root in MATLAB:

.. code-block:: matlab

   startupH2sim
   result = exampleHydrogenMixing2D();
   files = animateHydrogenMixing2D(result, fullfile('build', 'mixing'));

The solver creates no plots or output files. The renderer writes MP4, GIF and a
PNG poster separately, so saved results can be rendered again:

.. code-block:: matlab

   save('mixingResults.mat', 'result', '-v7');
   load('mixingResults.mat', 'result');
   animateHydrogenMixing2D(result, fullfile('build', 'mixing'));

For a smaller setup check, use ``'gridSize', [8, 8]``, ``'durationDays', 30``
and ``'outputCount', 12``. This does not reproduce the displayed 40-by-40 run.
MP4 writing requires MATLAB's MPEG-4 VideoWriter profile. On platforms without
that profile, pass ``'writeVideo', false`` to export the GIF and poster.

Model and provenance
--------------------

.. list-table:: Displayed demonstration configuration
   :header-rows: 1
   :widths: 40 60

   * - Parameter
     - Value
   * - Section / depth
     - 100 m wide, 100 m high; depth 400–500 m; 1 m extrusion
   * - Grid
     - 40 by 40 cells
   * - Porosity / permeability
     - 0.1 / 1e-14 m²
   * - Temperature / top reference pressure
     - 323.15 K / 4 MPa
   * - Binary molecular diffusivity / tortuosity
     - 7.26e-5 m²/s / 1
   * - Duration / saved steps
     - 1825 days / 80 logarithmically spaced steps
   * - Thermodynamics
     - Peng–Robinson, MRST tabulated H₂/CH₄ properties; zero binary interaction
   * - Transport
     - H2sim mass-fraction Fickian diffusion and TPFA Darcy flux

Component convergence uses a ``1e-8`` normalized mass-residual tolerance.
The displayed run completed all 80 steps; maximum relative component mass
errors were ``4.28e-10`` (H₂) and ``6.45e-10`` (CH₄) on Windows MATLAB
R2026a Update 5. This is a local run record, not a cross-platform guarantee.

Each starting gas column is initialized to an approximate hydrostatic profile
with a shared top reference pressure. Pure end members use the EOS numerical
composition floor. The example-specific diffusivity state function supplies the
published constant coefficient; it does not change the default H2sim diffusion
correlation used by other models.

This is an independently implemented **coarse-grid adaptation**, not a claim
of exact reproduction of the paper's EOS choices, viscosity treatment, mesh or
reference profiles. The public benchmark repository contains comparison data;
those data are not bundled or plotted as H2sim output here. An external profile
comparison is still needed before describing this example as benchmark-validated.

Source: `Okoroafor et al., Intercomparison of numerical simulation models for
hydrogen storage in porous media using different codes (2023)
<https://doi.org/10.1016/j.enconman.2023.117409>`_.
Public data: `Stanford/SUETRI-A Underground Hydrogen Storage
<https://github.com/suetri-a/Underground_Hydrogen_Storage>`_ (MIT license).
New H2sim implementation files retain the project's GPL-3.0-or-later notice.

Checks and limits
-----------------

The example checks finite positive pressures, bounded normalized component
fractions and saturations, and conservation of both component masses to
``1e-5`` relative over the closed simulation. Diagnostics retain component
masses in kilograms and the mass-weighted hydrogen depth.

``HydrogenMixing2DTest`` checks the geometry and sealed controls, a stationary
zero-diffusion/zero-gravity limit, mixing with diffusion alone, upward hydrogen
movement with gravity, independent gas-EOS inventory accounting, invalid inputs,
and GIF/poster export. These checks establish behavior and conservation for
small cases; they do not establish grid convergence or agreement with external
simulators. See :doc:`verification` for the broader dated verification record.
