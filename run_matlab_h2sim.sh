#!/usr/bin/env bash
# Linux/WSL MATLAB launcher for this checkout.
# Usage: bash run_matlab_h2sim.sh "results = profilePhreeqcWorkflows;"
# Override MATLAB_BIN to select a Linux or Windows MATLAB installation.
set -euo pipefail
if [[ $# -ne 1 || "$1" == --help ]]; then
    echo 'Usage: bash run_matlab_h2sim.sh "MATLAB statements"'
    [[ $# -eq 1 && "$1" == --help ]] && exit 0
    exit 2
fi
h2sim_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Prefer native Linux MATLAB; retain the WSL Windows fallback.
matlab_executable="${MATLAB_BIN:-$(command -v matlab || true)}"
if [[ -z "$matlab_executable" ]]; then
    matlab_executable='/mnt/c/Program Files/MATLAB/R2026a/bin/matlab.exe'
fi
if [[ "$matlab_executable" != */* ]]; then
    matlab_executable="$(command -v "$matlab_executable" || true)"
fi
if [[ ! -x "$matlab_executable" ]]; then
    echo 'MATLAB not found. Set MATLAB_BIN to a Linux MATLAB or Windows MATLAB executable.' >&2
    exit 1
fi
if [[ "$matlab_executable" == *.exe ]]; then
    matlab_root="$(wslpath -w "$h2sim_root")"
else
    matlab_root="$h2sim_root"
    # Apply PhreeqcMatlab's Linux libstdc++ setup before starting MATLAB.
    export MATLAB_BIN="$matlab_executable"
    phreeqc_launcher="$h2sim_root/submodules/PhreeqcMatlab/run_matlab.sh"
    if [[ ! -f "$phreeqc_launcher" ]]; then
        echo 'Initialize dependencies: git submodule update --init --recursive' >&2
        exit 1
    fi
fi
matlab_root="${matlab_root//\'/\'\'}"
# Initialize this checkout from MATLAB's standard path, avoiding other MRST
# installations and Octave shims left on the user's saved MATLAB path.
if [[ "$matlab_executable" != *.exe ]]; then
    # Windows checkouts may give the dependency script CRLF line endings.
    exec bash <(tr -d '\r' < "$phreeqc_launcher") -batch "cd(tempdir); restoredefaultpath; cd('$matlab_root'); startupH2sim; $1"
fi
exec "$matlab_executable" -batch "cd(tempdir); restoredefaultpath; cd('$matlab_root'); startupH2sim; $1"
