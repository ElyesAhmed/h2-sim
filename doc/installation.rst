Installation
============

Clone H2sim with its pinned dependencies, then initialize it from MATLAB.
See :doc:`dependencies` for required and optional components.

Clone the repository
--------------------

.. code-block:: shell

   git clone --recurse-submodules https://github.com/sintefmath/h2-sim.git
   cd h2-sim

For a checkout cloned without submodules:

.. code-block:: shell

   git submodule update --init --recursive

Initialize MATLAB
-----------------

Open MATLAB and set its current folder to the cloned ``h2-sim`` directory.
Then run:

.. code-block:: matlab

   startupH2sim

The stated minimum for core examples is MATLAB R2021a. The latest recorded
regression environment is R2026a Update 5; earlier releases were not retested
in that record. See :doc:`verification` for tested environments and limits.

Startup adds H2sim modules and initializes dependencies. It currently also
checks PhreeqcMatlab native libraries for core-only workflows and may download
them on first startup. Offline use requires those libraries and the pinned
submodule contents to be present beforehand. Optional chemistry initialization
is not yet implemented. Do not add the complete MRST tree with ``genpath``.

H2sim uses its own biochemistry implementation, registered as
``h2sim-biochem``. Initialize it with ``startupH2sim``; do not use
``mrstModule add h2-biochem`` to initialize this toolbox. That name belongs
to MRST's separate module. H2sim startup removes the upstream module's
paths and mapping for the current MATLAB session, then selects this
checkout's implementation. Other MRST modules remain available.

If you have already created model objects with MRST's upstream module,
restart MATLAB and initialize H2sim before constructing new models.
You can check which implementation is selected:

.. code-block:: matlab

   which BiochemistryModel
   mrstPath('search', 'h2sim-biochem')

Both paths should point into this H2sim checkout's ``h2-biochem`` folder.

Runtime and development paths
-----------------------------

Startup adds the supported biochemistry module, storage module and toolbox
utilities. Biochemistry tests live in ``tests/biochemistry``; archived examples
and older 3D studies live in ``research/biochemistry``. These folders are
outside the registered module root, so MRST module reactivation does not add
them. Activation also removes paths left by their previous locations.
Older storage prototypes live in ``research/h2store/prototypes``. Supported
entry points remain in the module example folders; tests and research code
are added explicitly only when needed.

Run tests by their explicit folder path from the repository root:

.. code-block:: matlab

   checks = runtests('tests/biochemistry');
   assertSuccess(checks);

To inspect an archived study, add only its selected folder explicitly after
startup. Do not recursively add the entire repository. See the README files
under ``research/`` for the scope and limitations of
archived studies and prototypes. These are separate from supported tutorials.

Run a first example
-------------------

.. code-block:: matlab

   result = exampleBlackOilAquifer2D( ...
       'gridSpacing', [10, 10], 'numCycles', 1, 'plotResults', false);
   plotBlackOilAquifer2D(result);

This coarse, one-cycle saline-aquifer configuration uses the black-oil model
and bundled property tables. Its flow calculation needs neither a PHREEQC
engine nor Parallel Computing Toolbox; startup still performs the library
check described above. Continue with :doc:`quickstart` or :doc:`examples`.

Optional AMGCL acceleration
---------------------------

This step is optional. The core examples can run without AMGCL.

Large compositional cases can use MRST's AMGCL CPR solver. Configure a C++
compiler with ``mex -setup C++``, load ``mrstModule add linearsolvers``,
and follow the AMGCL gateway build instructions in your pinned MRST checkout.
The compiled gateway must match your MATLAB platform.

A gateway compiled in a separate local directory can be activated through
MATLAB preferences:

.. code-block:: matlab

   setpref('H2sim', 'AMGCLGatewayPath', gatewayDirectory);
   setpref('H2sim', 'AMGCLSourcePath', amgclSourceDirectory);
   setpref('H2sim', 'BoostHeaderPath', boostHeaderDirectory);
   assert(activateH2simAMGCL());

``gatewayDirectory`` contains MRST's gateway files and its ``utils`` directory
with ``amgcl_matlab`` compiled for your platform. A standard MRST installation
can keep its existing solver paths. AMGCL does not require Parallel Computing
Toolbox.

.. _optional-phreeqc-setup:

Optional PHREEQC setup
----------------------

This step is needed only for examples that couple H2sim to PHREEQC.
Both sequential backends support Linux MATLAB through the native IPhreeqc
C library supplied by PhreeqcMatlab. Windows MATLAB continues to use
IPhreeqcCOM. macOS sequential coupling is not supported.

Linux
~~~~~

.. note::

   The current source includes native Linux coupling. Full native-Linux
   MATLAB regression validation is not recorded in the latest verification
   record; native-interface chemistry has also been tested with Windows DLLs.
   See :doc:`verification` for the distinction between implemented support
   and recorded platform validation.

Initialize the pinned submodules, then launch native Linux MATLAB:

.. code-block:: bash

   git submodule update --init --recursive
   MATLAB_BIN=/path/to/MATLAB/bin/matlab bash run_matlab_h2sim.sh "disp('Ready')"

If ``matlab`` is on PATH, ``MATLAB_BIN`` may be omitted. The launcher prefers
Linux MATLAB and falls back to Windows MATLAB under WSL when none is found.
It delegates to PhreeqcMatlab's Linux launcher, which preloads the system
``libstdc++.so.6`` for its modern GCC binaries. Set
``PHREEQCMATLAB_LIBSTDCPP`` to override that library location if necessary.
The system C++ runtime must provide ``GLIBCXX_3.4.32`` for the supplied
3.8.6 binaries. MATLAB needs a configured supported C compiler for
``loadlibrary`` (``mex -setup C``).

``startupH2sim`` initializes PhreeqcMatlab, which resolves the shared
libraries from its ``libs/`` directory, a local install specified by
``PHREEQCMATLAB_LIB_PATH`` (or ``/usr/local/lib``), or release downloads.
For offline installations, provide the libraries before startup.
No COM registration is needed on Linux. Use the same explicit absolute
``phreeqcDatabaseFile`` path to ``h2_biogeochemistry.dat`` as on Windows;
``phreeqcComProgId`` is only used on Windows.

Verify chemistry and cell batching after initialization:

.. code-block:: matlab

   iph = createH2simIPhreeqc('IPhreeqcCOM.Object');
   assert(iph.LoadDatabase(which('h2_biogeochemistry.dat')) == 0);
   delete(iph);
   results = runtests('tests/biochemistry/CompositionalPhreeqcBatchTest.m');
   assertSuccess(results);

Windows
~~~~~~~

Install and register IPhreeqcCOM from the
`USGS PHREEQC distribution <https://www.usgs.gov/software/phreeqc-version-3>`_
on Windows. Test the COM interface and the bundled database:

.. code-block:: matlab

   db = which('h2_biogeochemistry.dat');
   assert(~isempty(db), 'Initialize H2sim first.');
   iph = actxserver('IPhreeqcCOM.Object');
   status = iph.LoadDatabase(db);
   assert(status == 0);
   delete(iph);

Configure ``phreeqcComProgId`` if your COM installation uses a different
identifier. ``phreeqcDatabaseFile`` must resolve to an absolute database path.

Update an existing checkout
---------------------------

From a clean checkout on the repository's ``master`` branch:

.. code-block:: shell

   git pull --ff-only
   git submodule update --init --recursive

Preserve local work before changing branches or updating. Restart MATLAB after
an update and run ``startupH2sim`` before creating model objects. Do not update
submodules with ``--remote``: the repository pins the revisions used for its
verification record.

Troubleshooting
---------------

* **Missing dependencies after downloading a ZIP:** use the Git clone command
  above. GitHub source ZIPs omit submodule contents, and startup cannot fetch
  pinned dependencies automatically outside a Git checkout.
* **A different BiochemistryModel is selected:** restart MATLAB and initialize
  this checkout before loading models. Check ``which BiochemistryModel``;
  avoid recursively adding MRST or the complete repository to the path.
* **First startup fails while downloading chemistry libraries:** startup currently
  checks those files even for core-only simulations. Provide the pinned
  PhreeqcMatlab libraries before startup for offline use. A PHREEQC engine is
  only used by chemistry workflows, but this startup check is unconditional.
* **Linux reports a GLIBCXX or loadlibrary error:** launch through
  ``run_matlab_h2sim.sh``, check the runtime requirement in the Linux section,
  and configure MATLAB's supported C compiler with ``mex -setup C``.
* **No MATLAB executable is found by the launcher:** set ``MATLAB_BIN`` to the
  executable for your installation. Under WSL, a Windows executable needs its
  WSL path; native Linux MATLAB is preferred when available.
* **An optional backend test is incomplete:** inspect its dependency message.
  A skipped test does not validate that backend. See :doc:`verification`.

For support, include the H2sim revision, MATLAB version, operating system,
selected backend and complete error stack. Use the repository's bug-report
form for reproducible failures or :doc:`community` for setup questions.
