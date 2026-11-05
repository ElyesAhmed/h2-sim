Quick start
===========

Run these commands from the repository root after :doc:`installation`.
Use :doc:`model-selection` if you are unsure which family to choose.
All examples below use serial execution and explicit, small configurations.
They check setup and show the returned data; they do not reproduce the full
website galleries. See :ref:`example-runtime-guide` before running larger cases.

.. _quickstart-aquifer:

Hydrogen storage in saline aquifers
-----------------------------------

.. code-block:: matlab

   startupH2sim
   result = exampleBlackOilAquifer2D( ...
       'gridSpacing', [10, 10], 'numCycles', 1, 'plotResults', false);
   lastState = result.states{end};
   gasSaturation = lastState.s(:, 2);
   plotBlackOilAquifer2D(result);

This introductory configuration uses a coarse 2D structural trap with hydrogen
build-up and one storage cycle. Run ``exampleBlackOilAquifer2D()`` for the
default grid and five cycles; that command plots automatically. The coarse
introductory configuration is not the configuration of the archived figures.
Gravity, capillarity and dissolved hydrogen use the existing aquifer model
and input tables. Expect accepted states and well outputs; the plotting call
shows plume snapshots, dissolution and well response. See :doc:`store` and
:doc:`thermodynamics`.

.. _quickstart-biochemistry:

Hydrogen storage in depleted gas reservoirs
-------------------------------------------

.. code-block:: matlab

   startupH2sim
   results = exampleCompositionalBacterial2DThreeReactions( ...
       'gridSpacing', [10, 10], 'numCycles', 1, ...
       'scenarios', {'bacterial', 'abiotic'}, 'maximumFlowSteps', 2, ...
       'molecularDiffusion', false, 'molecularDispersion', false, ...
       'plotResults', false, ...
       'outputDirectory', fullfile(pwd, 'build', 'biochemistry-setup-check'), ...
       'simulationDirectory', fullfile(pwd, 'build', 'biochemistry-setup-cache'));
   lastBacterialState = results(1).states{end};
   gasSaturation = lastBacterialState.s(:, 2);
   complete = [results.complete];

Expect two result structures, one per scenario. ``complete`` is false because
only the first two flow steps are requested. This prefix checks compositional
flow and reaction setup; it contains no complete storage cycle. The example
writes compact and packed simulation output. Use the full command in
:ref:`example-biochemistry` for the gallery configuration and its plotting
function. Keep prefix output separate from full-run output.

The case contains residual methane and three microbial pathways, with
molecular diffusion and dispersion disabled here. PHREEQC is unnecessary.
Use ``startupH2sim`` to select H2sim's biochemistry implementation, rather
than loading MRST's separate ``h2-biochem`` module.

.. _quickstart-chemistry:

Short PHREEQC mineral comparison
--------------------------------

After configuring native IPhreeqc on Linux or IPhreeqcCOM on Windows
(see :ref:`optional-phreeqc-setup`), explicitly initialize chemistry:

.. code-block:: matlab

   startupH2sim('phreeqc', true)
   comparison = exampleCompositionalBacterial1DPhreeqcMinerals( ...
       'gridCells', 4, 'maximumFlowSteps', 2, 'plotResults', false);
   pH = comparison(2).states{end}.phreeqcPH;

Redraw the completed states without solving again:

.. code-block:: matlab

   plotPhreeqcMineralComparison(comparison, ...
       'outputDirectory', fullfile(pwd, 'build', 'my-figures'));

Expect four result structures: a microbial baseline followed by Bentheimer,
Berea and Grey Berea mineral cases. ``pH`` is a four-cell aqueous pH vector
for the first PHREEQC case. Two timesteps are a dependency and chemistry setup
check, not a full injection run. The plotting function exports PNG/PDF figures
from the accepted states without solving again.

These cases use different kinetic owners. Read :doc:`phreeqc` before
interpreting a backend comparison as a sensitivity to mineral chemistry.
