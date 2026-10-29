# H2sim

**Underground hydrogen storage simulation, built on the [MATLAB Reservoir Simulation Toolbox (MRST)](https://www.sintef.no/projectweb/mrst/).**

H2sim provides MATLAB models and examples for hydrogen storage in saline aquifers and depleted gas reservoirs. Explore storage cycles, hydrogen dissolution, microbial consumption, gas composition, and geochemical feedback.

[Documentation](https://sintefmath.github.io/h2-sim/) · [Installation](https://sintefmath.github.io/h2-sim/installation.html) · [Examples and notebooks](https://sintefmath.github.io/h2-sim/examples.html) · [Publications](https://sintefmath.github.io/h2-sim/publications.html)

## What you can simulate

| Model family | Capabilities |
| --- | --- |
| **Hydrogen storage in saline aquifers — h2-store** | Black-oil flow, injection and withdrawal cycles, gravity, capillarity, dissolved hydrogen, and fluid-property tables. |
| **Hydrogen storage in depleted gas reservoirs — h2-biochem** | Compositional flow with residual gas and microbial reactions: methanogenesis, acetogenesis, and sulfate reduction. Compare bacterial and abiotic storage. |
| **PHREEQC coupling** | Sequential compositional–geochemical coupling and multirate microbial reaction substeps with aqueous equilibrium feedback. Inspect pH, aqueous chemistry, and mineral effects. |
| **Hydrogen–brine thermodynamics** | RK, Søreide–Whitson, PR, and Henry–Setschenow calculations, comparisons with supplied ePC-SAFT reference tables, and black-oil PVT tabulation. |

## Install

Use **MATLAB R2021a or newer** and Git. See the [verification record](https://sintefmath.github.io/h2-sim/verification.html) for the MATLAB releases and platforms actually tested. Clone the repository with its pinned MRST and PhreeqcMatlab dependencies:

```sh
git clone --recurse-submodules https://github.com/sintefmath/h2-sim.git
cd h2-sim
```

If you already cloned without the dependencies, run this from the repository directory:

```sh
git submodule update --init --recursive
```

In MATLAB, set the current folder to the cloned `h2-sim` directory and initialize:

```matlab
startupH2sim
```

Startup initializes MRST and adds the H2sim modules. Use this startup function rather than recursively adding the entire MRST tree with `genpath`.

Startup currently also checks PhreeqcMatlab's native libraries, even for core-only simulations. The first startup may download them; offline installations must provide the pinned submodules and libraries beforehand. See the [installation guide](https://sintefmath.github.io/h2-sim/installation.html) for platform setup and troubleshooting.

To update a clean checkout on the repository's `master` branch:

```sh
git pull --ff-only
git submodule update --init --recursive
```

Restart MATLAB and run `startupH2sim` after updating. Preserve local work before changing branches or updating. Use Git cloning rather than GitHub's source ZIP, which does not include submodule contents.

**Parallel Computing Toolbox is optional.** The selected examples run serially by default. Optional AMGCL acceleration for larger compositional simulations requires a supported C++ compiler and MRST's compiled gateway; see the [installation guide](https://sintefmath.github.io/h2-sim/installation.html).

## Run your first simulation

Start with a coarse-grid 2D saline aquifer and one storage cycle. The flow calculation uses the bundled fluid tables and needs neither a PHREEQC engine nor Parallel Computing Toolbox; the startup library check described above still applies:

```matlab
result = exampleBlackOilAquifer2D( ...
    'gridSpacing', [10, 10], 'numCycles', 1, 'plotResults', false);
plotBlackOilAquifer2D(result);

% Inspect the final gas saturation.
lastState = result.states{end};
gasSaturation = lastState.s(:, 2);
```

For the full five-cycle example on the default grid, run `exampleBlackOilAquifer2D()`; it plots automatically. The introductory command above uses a coarser grid and is not the configuration of the archived notebook figures.

The [aquifer notebook](https://sintefmath.github.io/h2-sim/notebooks/blackoil_storage.html) explains the setup and shows storage-cycle, dissolution, and fluid-table figures.

## Compare bacterial and abiotic storage

Run the existing 2D depleted-reservoir case with three microbial reactions:

```matlab
results = exampleCompositionalBacterial2DThreeReactions( ...
    'numCycles', 5, 'scenarios', {'bacterial', 'abiotic'}, ...
    'molecularDiffusion', false, 'molecularDispersion', false, ...
    'plotResults', false);
plotCompositionalBacterial2DThreeReactions(results);
```

This is a larger simulation than the introductory aquifer example. The [bacterial storage notebook](https://sintefmath.github.io/h2-sim/notebooks/bacterial_storage_2d.html) presents hydrogen consumption by reaction, spatial results, and signed well component rates with bottom-hole pressure.

Initialize biochemistry through `startupH2sim`, which selects the standalone
`h2sim-biochem` implementation. Do not load MRST's separate `h2-biochem`
module for these examples. See the [upstream comparison and attribution audit](h2-biochem/MRST_COMPARISON.md).

## Use PHREEQC chemistry

H2sim supports sequential PHREEQC coupling on **Linux MATLAB** through PhreeqcMatlab's native IPhreeqc shared library, and on **Windows MATLAB** through IPhreeqcCOM. On Linux, launch with `bash run_matlab_h2sim.sh "MATLAB statements"`; set `MATLAB_BIN` if MATLAB is not on PATH. See the [PHREEQC installation instructions](https://sintefmath.github.io/h2-sim/installation.html#optional-phreeqc-setup).

After completing the platform setup and running `startupH2sim`, check the interface and bundled database:

```matlab
db = which('h2_biogeochemistry.dat');
assert(~isempty(db), 'Initialize H2sim first.');
iph = createH2simIPhreeqc('IPhreeqcCOM.Object');
status = iph.LoadDatabase(db);
assert(status == 0, 'PHREEQC database loading failed.');
delete(iph);
```

Run a small mineral-chemistry setup check and inspect its final pH:

```matlab
comparison = exampleCompositionalBacterial1DPhreeqcMinerals( ...
    'gridCells', 4, 'maximumFlowSteps', 2, 'plotResults', false);
pH = comparison(2).states{end}.phreeqcPH;
plotPhreeqcMineralComparison(comparison);
```

Read the [PHREEQC workflow guide](https://sintefmath.github.io/h2-sim/phreeqc.html) before comparing backends: their microbial kinetic ownership and splitting differ. The bundled database originates from UGFACT; its source revision, checksum, and attribution are recorded in [the database README](h2-biochem/database/README.md). The [full-cycle validation notebook](https://sintefmath.github.io/h2-sim/notebooks/phreeqc_validation.html) includes attributed external reference data. The examples run with the bundled database; reproducing the external reference is optional and requires an explicit `referenceRoot`.

## Explore and reuse results

- [Selected examples and downloadable notebooks](https://sintefmath.github.io/h2-sim/examples.html): model setup, saved figures, and MATLAB commands.
- [Hydrogen–brine phase behavior](https://sintefmath.github.io/h2-sim/thermodynamics.html): pressure, temperature, salinity, and fluid-property calculations.
- [Dependencies](https://sintefmath.github.io/h2-sim/dependencies.html): required software and optional acceleration.
- [Publications and presentations](https://sintefmath.github.io/h2-sim/publications.html): related research and references.

The plotting functions above accept completed result structures, so you can redraw figures without rerunning the simulations. For later use, save the returned structure in MATLAB, for example `save('aquiferResults.mat', 'result', '-v7.3')`.

## License and citation

H2sim is distributed under the [GNU GPL version 3 or later](LICENSE). Inherited MRST/SINTEF copyright and license notices remain in their files; dependencies and bundled datasets retain their own notices and attribution.

Use [CITATION.cff](CITATION.cff) or GitHub's **Cite this repository** metadata to cite the software. Record the H2sim commit and dependency revisions used, and cite the [relevant model publications](https://sintefmath.github.io/h2-sim/publications.html) and chemistry database source for your workflow. The source is available now; the first tagged release is in preparation.

## Tests and support

After `startupH2sim`, run the biochemistry tests explicitly from their test folder:

```matlab
mrstModule add test-suite
checks = runtests(fullfile(pwd, 'tests', 'biochemistry'));
assertSuccess(checks);
```

Optional backend or parallel tests can be skipped when their dependencies are
unavailable; inspect incomplete results separately. Run H2-store unit and small
numerical regression tests with:

```matlab
addpath(fullfile(pwd, 'tests', 'h2store'));
results = runH2StoreTests();
```

Run the small complete-cycle and serialized-restart regressions locally with
MRST and a working PHREEQC engine:

```matlab
addpath(fullfile(pwd, 'tests', 'cycles'));
cases = runStorageCycleRegressions();
```

See the [cycle regression guide](tests/cycles/README.md) for coverage, reference
provenance and comparison bounds.

See the [verification guide](https://sintefmath.github.io/h2-sim/verification.html) for the dated local test record, tested environment, and platform limitations. GitHub Actions checks documentation; MATLAB regressions are run locally.

These local checks do not run the full paper simulations. See
[contributing guidance](CONTRIBUTING.md) for formatting and reference policies.

Report bugs or request features through [GitHub Issues](https://github.com/sintefmath/h2-sim/issues). Include your MATLAB version, operating system, example command, and error message so the issue can be reproduced.
