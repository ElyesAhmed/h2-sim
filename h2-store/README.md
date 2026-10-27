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
