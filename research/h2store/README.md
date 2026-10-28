# H2-store research prototypes

These scripts and their dependent comparison driver are retained for development and are outside the registered
H2-store module path. They are not used by the website or the paper drivers.
Use `exampleBlackOilAquifer2D` for the supported aquifer workflow, or the
scripts under `h2-store/examples/paper_scripts` for paper cases.

- `prototypes/simpleBlackOil2DModel.m` and `simpleExampleBlackOilPVT.m` are
  early PVT/simulation sketches. They overwrite logical grid indices with
  saturation-region IDs and use only the first SGOF region; these behaviors
  need a separate numerical review before using their results.
- `prototypes/exampleBlackoilVsCompositional.m` depends on the PVT prototype
  and is kept beside it. Its shared-workspace assumptions also need review.
- `prototypes/eggUHSExample.m` is an experimental Egg-model workflow requiring
  an external dataset.

Add this directory explicitly when investigating a prototype. Its simulations
and figures are not covered by the small supported-model regression fixtures.
