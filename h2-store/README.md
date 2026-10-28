# h2-store: Hydrogen storage in aquifers

This is H2sim's maintained version of MRST's h2store module, with H2sim-specific
changes. MRST remains the simulation framework. Inherited files retain their
MRST copyright and license notices; development here does not require matching
changes in MRST's copy.

This module provides simulation tools for modeling a hydrogen (H₂) and brine mixture within the **ad-blackoil** module in the **MATLAB Reservoir Simulation Toolbox (MRST)**.

Our module includes tools for implementing the **Redlich-Kwong** (**RK**) equation of state (EoS) and generating tabulated PVT data for H₂-brine systems. 
Additionally, it provides solubility tables derived from **ePC-Saft** and **Henry’s law** EoS for precise phase behavior calculations in hydrogen 
storage simulations.

## Overview

This module is developed to simulate the phase behavior and thermodynamic properties of hydrogen stored in saline aquifers, with specific consideration of temperature, pressure, and salinity effects on hydrogen solubility and fluid properties.

## Features

- **Implementation of RK Equation of State**: The module includes an implementation of the Redlich-Kwong (RK) EoS for H₂-brine mixtures, allowing for quick thermodynamic calculations that capture real gas behavior and temperature effects.

- **Scripts for tabulating PVT Data for blackoil simulators**: Precomputed PVT tables facilitate efficient simulation of H₂-brine mixtures in MRST's ad-blackoil module. The resulting tables are also suitable for other blackoil simulators.

- **Solubility tables**: Estimate solubility from both ePC-Saft (data) and Henry-Setschnow correlation.
- **Correlations** for estimating the properties of water and H₂ mixtures for different pressure, temperature and salinity.

## Prerequisites

This code assumes that you are running in **MATLAB R2021a** or newer.

## Funding
- This work was funded by Norwegian Research and Innovation Centre for Hydrogen and Ammonia HYDROGENi (Grant No. 333118) and
the Research Council of Norway HYSTORM project (Grant No. 315804)

## Local tests

See [the h2-store test instructions](../tests/h2store/README.md) for quick
unit checks and numerical regressions. These checks run locally.

## Hydrogen inventories

`computeGasVolumes` returns per-cell hydrogen component volumes at surface
conditions [m³], split into dissolved and gas-phase contributions. It uses
model pore volume (including rock compressibility), liquid saturation for
dissolved hydrogen, and reciprocal formation volume factors. It can evaluate
states without saved PVT caches, and returns zero dissolved inventory when
`disgas` is disabled. Vaporized brine is not counted as hydrogen.

This corrects older postprocessing that used bulk cell volume and gas
saturation in the dissolved term. Recompute inventory plots and dissolved
fractions produced with older versions. The correction changes postprocessing;
it does not change the reservoir simulation equations or stored states.

## Dome schedule timing

Dome stages retain their full remainder and every injection timestep. The
default cushion timestep is one day. The default four-cycle schedule lasts
547 days: 365 days of cushion injection, 90 days of shut-in and four cycles
of 10-day charge, 3-day idle and 10-day discharge stages. This correction changes
stage timing and injected volumes. Recompute stored dome results and plots when
adopting it. The other models keep their existing timestep construction.

## Dome cell mapping

The dome grid retains its logical cell indices in `G.cells.indexMap`. Saturation
region IDs remain in `rock.regions.saturation` and `deck.REGIONS.SATNUM`. Keeping
these arrays separate ensures that MRST deck-region and rock lookups select the
corresponding cells rather than repeating the first few deck entries.

## Modified benchmark schedule timing

Benchmark injection stages now use the two-step opening and closing ramps
without skipping or overlapping timesteps, and retain their final remainder.
The default BHP-controlled schedule lasts 1200 days. The 90/94/98/102/102/102 bar
buildup levels and six cushion/shut-in pairs are unchanged. Recompute stored
benchmark results when adopting this timing correction. In rate-controlled mode,
every cushion/shut-in pair repeats the configured `rateCushion` profile, including
its closing ramp. The 94/98/102 bar escalation applies only in BHP mode. This
corrects pressure values previously assigned to rate controls; recompute results
from affected rate-controlled buildup cases.

## Modified benchmark gravity

Full benchmark setup initializes standard downward gravity before constructing
boundary pressures and the flow model. Previously boundary pressures used the
incoming global gravity setting, while deck initialization reset model gravity.
With boundary conditions enabled, results started with gravity off or rotated
can therefore change; rerun affected cases. Setups already using standard gravity retain the same pressure formula,
face selection and acceleration. Metadata-only calls leave gravity unchanged.

## Modified benchmark cushion count

`numCyclesCushions` now sets the number of cushion/shut-in pairs for both full
and cushion-only schedules. It must be a finite positive integer; use
`use_cushion = false` to disable buildup. BHP levels start at `bhp`, then use
94 and 98 bar, and remain at 102 bar from pair four onward. Rate mode repeats
the configured cushion-rate profile for each pair.

The default full schedule retains six buildup pairs and its 1200-day duration.
Default cushion-only runs now contain six pairs (900 days), instead of the
previous four pairs (600 days). Set `numCyclesCushions = 4` to retain that earlier
cushion-only schedule. Rerun results affected by a different buildup count.

## Modified benchmark active cells

Benchmark permeability, porosity and saturation regions follow
`G.cells.indexMap`, so inactive logical deck cells are excluded consistently.
Fluid initialization uses the same processed grid. The fixed benchmark well
completions are logical deck-cell IDs and are mapped to active-cell indices;
setup raises a descriptive error if a required completion is inactive or absent.
All-active decks retain their property values and completion locations.
