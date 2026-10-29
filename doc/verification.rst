Local verification
==================

Run numerical checks locally from the repository root. GitHub Actions builds
this website, checks documentation links and runs Python tooling tests; it does
not execute MATLAB or establish numerical correctness. A green documentation
check is separate from the MATLAB verification record below.

Choose the checks for your installation
---------------------------------------

H2-store unit and numerical tests require the pinned MRST dependency and do not
need PHREEQC, internet downloads, plots or Parallel Computing Toolbox during
the test run. Initialize the submodule beforehand:

.. code-block:: matlab

   addpath(fullfile(pwd, 'tests', 'h2store'));
   results = runH2StoreTests();

The runner restores the original MATLAB path and working folder and requires
every test to pass without skips. It can also accept an existing pinned MRST
checkout as its argument.

For biochemistry tests, first follow :doc:`installation` and initialize H2sim:

.. code-block:: matlab

   startupH2sim('phreeqc', true)
   mrstModule add test-suite
   checks = runtests(fullfile(pwd, 'tests', 'biochemistry'));
   assertSuccess(checks);

Some tests require a PHREEQC engine or optional parallel support. Inspect
incomplete results separately; a skipped test does not validate its backend.
The fully configured verification record below contains no incomplete tests.

Complete-cycle and serialized-restart regressions require working PHREEQC:

.. code-block:: matlab

   addpath(fullfile(pwd, 'tests', 'cycles'));
   cases = runStorageCycleRegressions();

This runner checks two four-cell cases: black-oil dissolution/vaporization and
reactive biochemistry with PHREEQC. Each has six steps spanning injection,
shut-in and production. A MAT-file checkpoint within shut-in is loaded into a
fresh model and solver before resuming production. The PHREEQC check also uses
a fresh engine session. Physical-state bounds, well control changes, hydrogen
inventory accounting for the black-oil case, reaction consumption, restart
agreement and the reviewed saved reference must pass. Missing dependencies or
failed comparisons raise an error; the runner never regenerates references.

See the `cycle regression guide
<https://github.com/sintefmath/h2-sim/blob/master/tests/cycles/README.md>`_
for comparison bounds, reference provenance and diagnostic inspection commands.
Run test folders explicitly after activation; they are intentionally outside
the runtime module path.

Recorded local run
------------------

This is a dated record, not an automatically refreshed badge:

.. list-table:: Verification on 29 October 2026
   :header-rows: 1
   :widths: 30 70

   * - Item
     - Recorded environment or result
   * - Source
     - EOS fix ``d3dbf3f`` and reviewed reference ``fc6e2fa``, merged in ``a8b56fc``
   * - MATLAB / platform
     - R2026a Update 5, Windows MATLAB launched from WSL
   * - MRST
     - Pinned commit ``8e218b0786cd4651814553b0f9ebd6844eaabcb2``
   * - PhreeqcMatlab / IPhreeqc
     - Pinned commit ``20662bf8fab5fe2a9bcaa7b60bc7f1ae5337733f``; IPhreeqc 3.8.6
   * - Biochemistry
     - 121 of 121 tests passed; zero failed or incomplete
   * - H2-store
     - 217 of 217 tests passed
   * - Complete-cycle regressions
     - Both model cases passed, including fresh-model serialized restarts
   * - Documentation and tooling
     - Strict Sphinx build, local HTML links/images and seven Python tooling tests passed

The physical HS restart discrepancy was traced to an EOS trace-composition
floor comparison and corrected without widening regression bounds. The maximum
HS tracer difference in the reactive cycle decreased from
``7.170710469e-8`` to ``1.394717675e-14 mol/m^3``. The changed uninterrupted
reference was reviewed and its old/new hashes and numerical differences recorded.

The revised coarse-grid introductory aquifer command was also executed in
this environment with fresh output: 33 cells, 179 accepted control steps and
one 220-day simulated build-up/storage cycle. Its explicit plotting call passed.
This manual onboarding check is separate from the 338 MATLAB test results and
uses a different grid and cycle count from the archived five-cycle figures.

Optional-startup verification
-----------------------------

On 29 October 2026, startup change ``4b86044`` was checked in the same Windows
MATLAB R2026a Update 5 environment, using archived pinned MRST and PhreeqcMatlab
source files rather than locally edited dependency checkouts:

* With no PhreeqcMatlab directory, default startup completed three black-oil
  phase-transfer cases and a two-step compositional simulation. The chemistry
  checkout remained absent. A requested native interface reported
  ``H2sim:PhreeqcNotInitialized`` with explicit setup instructions.
* Default and explicit-false startup passed repeated-call and changed-working-
  directory checks without initializing chemistry.
* Explicit chemistry startup initialized the real IPhreeqc engine; both complete-
  cycle/reference/restart cases passed. Repeating core startup preserved the
  already initialized chemistry paths.
* All 126 biochemistry tests and 217 H2-store tests passed, with no failed or
  incomplete biochemistry tests. The five additional biochemistry tests cover
  startup options, explicit initialization and dependency errors.
* All 13 Python tooling tests passed. The six launcher checks exercise core
  startup without a chemistry checkout, opt-in Linux preloading, Windows routing,
  path quoting, argument errors and MATLAB exit-status propagation using fake
  executables. They do not execute native Linux MATLAB.

The focused startup tests can also run without a chemistry checkout:

.. code-block:: matlab

   startupH2sim
   checks = runtests(fullfile(pwd, 'tests', 'biochemistry', ...
       'H2simPhreeqcStartupTest.m'));
   assertSuccess(checks);

No numerical references, chemistry parameters or solver acceptance bounds were
changed for optional startup. The earlier dated record remains above for the
EOS restart correction and reference provenance.

Platform and scientific limits
-------------------------------

The stated minimum for core workflows is MATLAB R2021a. This record does not
establish results on every MATLAB release. Native Linux PHREEQC coupling is
implemented, but a complete native-Linux MATLAB regression run is not recorded
here. Native-interface chemistry tested with Windows DLLs is not a substitute
for an end-to-end Linux run. macOS sequential PHREEQC coupling is unsupported.

The hybrid PE diagnostic remains history-sensitive and is reported separately
from physical restart comparisons. The existing checks require finite PE and
retain it in the uninterrupted reference; they do not require PE restart
equality. See :doc:`reference` for the chemistry ownership and restart details.

These are unit checks and small numerical cases, not full paper-duration
simulations, exhaustive phase-transition coverage, or an independent reactive
elemental-conservation audit. Reference agreement detects numerical change; it
does not prove that every physical model is correct. Papers and archived figures
may use different grids, schedules and parameter sets.

Record a new environment
------------------------

When reporting another validation run, record the MATLAB version and platform,
H2sim commit, pinned dependency revisions, backend and library version, and all
passed/failed/incomplete counts. From the checkout, capture:

.. code-block:: shell

   git rev-parse HEAD
   git submodule status

.. code-block:: matlab

   version
   computer
   which BiochemistryModel

Keep earlier results as dated records. A reference update must explain the
numerical change and retain a before/after review; do not regenerate a reference
or relax its bounds simply to make a failing test pass.
