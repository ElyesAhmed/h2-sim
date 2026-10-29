#!/usr/bin/env bash
# Linux/WSL batch launcher. Chemistry runtime setup is explicitly opt-in.
# Override MATLAB_BIN to select a Linux or Windows MATLAB installation.
set -euo pipefail
usage() {
    echo 'Usage: bash run_matlab_h2sim.sh [--phreeqc] "MATLAB statements"'
}
phreeqc_enabled=false
if [[ ${1:-} == --help && $# -eq 1 ]]; then
    usage
    exit 0
fi
if [[ ${1:-} == --phreeqc ]]; then
    phreeqc_enabled=true
    shift
fi
if [[ $# -ne 1 || ${1:-} == --* ]]; then
    usage >&2
    exit 2
fi
h2sim_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
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
startup_command='startupH2sim'
if [[ "$phreeqc_enabled" == true ]]; then
    startup_command="startupH2sim('phreeqc', true)"
fi
if [[ "$matlab_executable" == *.exe ]]; then
    matlab_root="$(wslpath -w "$h2sim_root")"
else
    matlab_root="$h2sim_root"
fi
matlab_root="${matlab_root//\'/\'\'}"
matlab_command="cd(tempdir); restoredefaultpath; cd('$matlab_root'); $startup_command; $1"
if [[ "$phreeqc_enabled" == true && "$matlab_executable" != *.exe ]]; then
    export MATLAB_BIN="$matlab_executable"
    phreeqc_launcher="$h2sim_root/submodules/PhreeqcMatlab/run_matlab.sh"
    if [[ ! -f "$phreeqc_launcher" ]]; then
        echo 'Initialize chemistry: git submodule update --init --recursive -- submodules/PhreeqcMatlab' >&2
        exit 1
    fi
    # Handle CRLF dependency scripts and preload the Linux chemistry runtime.
    exec bash <(tr -d '\r' < "$phreeqc_launcher") -batch "$matlab_command"
fi
exec "$matlab_executable" -batch "$matlab_command"
