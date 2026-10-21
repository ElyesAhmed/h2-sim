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

Use MATLAB R2021a or newer for the core examples. Startup adds H2sim modules
and initializes dependencies. Do not add the complete MRST tree with ``genpath``.

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
Supported examples and model class locations are unchanged. Developer tools
that share a supported example folder remain visible pending a separate review.

Run tests by their explicit folder path from the repository root:

.. code-block:: matlab

   checks = runtests('tests/biochemistry');
   assertSuccess(checks);

To inspect an archived study, add only its selected folder explicitly after
startup. Do not recursively add the entire repository. This separation covers
the moved biochemistry groups; it does not classify local unpublished studies
or reorganize the storage and calibration modules.

Run a first example
-------------------

.. code-block:: matlab

   result = exampleBlackOilAquifer2D;

This two-dimensional saline-aquifer example uses the black-oil model and
requires neither PHREEQC nor Parallel Computing Toolbox. Continue with :doc:`quickstart` or :doc:`examples`.

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

   Native Linux coupling is available in the development checkout containing
   ``createH2simIPhreeqc.m`` and ``H2simNativeIPhreeqc.m``. Earlier releases
   use Windows COM for both sequential backends. Check your checkout before
   following the Linux steps below. Full Linux MATLAB simulation validation
   is pending; native-interface chemistry has been tested with Windows DLLs.

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
