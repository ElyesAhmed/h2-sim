function [logPressure, diagnostics] = solveH2BiochemVolumePressure(residual, initialLogPressure)
% Estimate a local bracket before fzero's full-precision refinement.
% The callback must return fluidVolume/poreVolume - 1 at log pressure.
% Each distinct probe uses the caller's ordinary cold EOS flash. Cache only
% exact repeats (not nearby pressures), including fzero's endpoint checks.
% No residual tolerance or phase-equilibrium assumptions are introduced.

validateattributes(initialLogPressure, {'numeric'}, ...
    {'scalar', 'real', 'finite'});
probes = [];
values = [];
diagnostics = struct('evaluations', 0, 'localBracket', false, ...
    'fallback', false, 'invalidProbes', 0);
f0 = evaluate(initialLogPressure);
if f0 == 0
    logPressure = initialLogPressure;
else
    % A 0.1% pressure perturbation measures local compressibility. Its
    % direction follows the usual decreasing volume-versus-pressure curve;
    % the measured slope, rather than that assumption, drives later probes.
    try
    probe = initialLogPressure + sign(f0)*1e-3;
    fp = evaluate(probe);
    for iteration = 1:6
        if fp == 0
            logPressure = probe;
            diagnostics.evaluations = numel(probes);
            return;
        elseif sign(fp) ~= sign(f0)
            diagnostics.localBracket = true;
            logPressure = fzero(@evaluate, sort([initialLogPressure, probe]));
            diagnostics.evaluations = numel(probes);
            return;
        end
        slope = (fp - f0)/(probe - initialLogPressure);
        if ~isfinite(slope) || slope >= 0
            break;
        end
        % Overshoot the secant estimate slightly to obtain a sign change.
        % Bound each expansion to avoid launching a distant, expensive flash.
        offset = -1.2*f0/slope;
        if ~isfinite(offset) || sign(offset) ~= sign(f0)
            break;
        end
        distance = abs(probe - initialLogPressure);
        offset = sign(offset)*min(max(abs(offset), 2*distance), log(2));
        nextProbe = initialLogPressure + offset;
        if nextProbe == probe
            break;
        end
        probe = nextProbe;
        fp = evaluate(probe);
    end
    catch ME
        % An exploratory EOS probe can fail near a phase boundary. It is
        % not an accepted state: fall back to the original scalar fzero search.
        diagnostics.invalidProbes=diagnostics.invalidProbes+1;
        diagnostics.localProbeError=ME.message;
    end
    diagnostics.fallback = true;
    logPressure = fzero(@evaluate, initialLogPressure);
end
diagnostics.evaluations = numel(probes);

    function result = evaluate(point)
        index = find(probes == point, 1);
        if isempty(index)
            result = residual(point);
            validateattributes(result, {'numeric'}, ...
                {'scalar', 'real', 'finite'});
            probes(end + 1) = point;
            values(end + 1) = result;
        else
            result = values(index);
        end
    end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).

h2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

h2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with h2sim.  If not, see <http://www.gnu.org/licenses/>.
%}
