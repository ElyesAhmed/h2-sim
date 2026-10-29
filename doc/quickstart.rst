Quick start
===========

After :doc:`installation`, choose one of the three model families.
All examples below use serial execution.

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
introductory configuration is not the configuration of the archived figures. Gravity, capillarity, and dissolved hydrogen use the existing aquifer
model and input tables. See :doc:`store` and :doc:`thermodynamics`.

Hydrogen storage in depleted gas reservoirs
-------------------------------------------

.. code-block:: matlab

   results = exampleCompositionalBacterial2DThreeReactions( ...
       'numCycles', 5, 'scenarios', {'bacterial', 'abiotic'}, ...
       'molecularDiffusion', false, 'molecularDispersion', false, ...
       'plotResults', false);
   plotCompositionalBacterial2DThreeReactions(results);

Open the compositional notebook in :doc:`examples` to inspect the setup,
well controls, microbial populations, and transport plots.

Short PHREEQC mineral comparison
--------------------------------

After configuring native IPhreeqc on Linux or IPhreeqcCOM on Windows
(see :ref:`optional-phreeqc-setup`):

.. code-block:: matlab

   comparison = exampleCompositionalBacterial1DPhreeqcMinerals( ...
       'gridCells', 4, 'maximumFlowSteps', 2, 'plotResults', false);
   pH = comparison(2).states{end}.phreeqcPH;

Redraw the completed states without solving again:

.. code-block:: matlab

   plotPhreeqcMineralComparison(comparison, ...
       'outputDirectory', fullfile(pwd, 'build', 'my-figures'));

These cases use different kinetic owners. Read :doc:`phreeqc` before
interpreting a backend comparison as a sensitivity to mineral chemistry.
