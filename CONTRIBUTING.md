# Contributing to H2sim

H2sim uses MRST as a pinned dependency and maintains its own biochemistry and
H2-store implementations. Use `startupH2sim` to select them; do not modify
submodules as part of a local-module cleanup.

## MATLAB style

Use four-space indentation, descriptive help with units, and one executable
statement per line. Keep numerical formulas and solver controls unchanged in
formatting changes. Put repeated calculations and substantial validation in
named helpers. Describe what the code currently does; avoid comments about
cleanup history. Keep existing public function names and input conventions.

`miss_hit.cfg` provides optional [MISS_HIT](https://github.com/florianschanda/miss_hit)
formatting settings. With MISS_HIT
installed in a development environment, run:

```sh
mh_style --input-encoding utf-8 h2-biochem h2-store utils tests research startupH2sim.m
```

Review changes before using `--fix`. The formatter is not a runtime dependency.
Its rules preserve project naming and existing copyright placement. Dependency
sources are excluded. A formatter pass alone does not establish correctness.

## Local validation

Use the test commands in the [README](README.md). Preserve numerical reference
files and tolerances during cleanup. Compare representative models before and
after source changes, including actual PHREEQC cases when that interface works.
Record optional backend skips separately from passed tests. Code Analyzer
findings require review; an unused value or unreachable branch is not by itself
a confirmed numerical bug. Keep scientific corrections identifiable in review. The
[reviewed analyzer snapshot](tests/CODE_ANALYZER_REVIEW.md) records findings
retained during the consolidated cleanup.

Build the website with warnings treated as errors:

```sh
python -m sphinx -E -a -W --keep-going -b html doc build/docs
python tools/check_documentation.py build/docs
python -m unittest discover -s tools/tests -v
```

Keep [example roles](h2-biochem/README.md) clear. Supported entry points live in
module example folders, paper drivers in `paper_scripts`, and unfinished work
under `research`, outside the registered runtime path. Reusing saved states for
postprocessing does not require rerunning the original simulation.

## Attribution

Retain original MRST/SINTEF GPL notices for inherited and derived code and update
the last copyright year when modifying a file. New H2sim code uses the same
GPL boilerplate with h2sim as the software name. Never relabel inherited code
as newly owned, or describe new H2sim files as part of MRST.
