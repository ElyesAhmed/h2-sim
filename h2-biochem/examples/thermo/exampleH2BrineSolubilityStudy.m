function result = exampleH2BrineSolubilityStudy(varargin)
    % Compare hydrogen-brine phase partitioning and salting-out models
    %
    % SYNOPSIS:
    %   result = exampleH2BrineSolubilityStudy();
    %   result = exampleH2BrineSolubilityStudy('plotResults', false);
    %
    % DESCRIPTION:
    %   Compare RK brine correlations, Soreide-Whitson, Peng-Robinson and
    %   Henry-Setschenow with a bundled near-pure-water ePC-SAFT reference table.
    %   The table is reference data; a live PC-SAFT solver is not used. PHREEQC,
    %   NIST access and Parallel Computing Toolbox are not required.
    %   See Ahmed et al. (2024), Advances in Water Resources 191, 104772.
    %
    % OPTIONAL PARAMETERS:
    %   plotResults     - Plot computed comparisons (default true).
    %   outputDirectory - Table/result folder (default build/thermodynamics-study).
    %
    % RETURNS:
    %   result - Partitioning and salting-out tables, reference information and
    %            output directory. Pressure is in Pa, temperature in K and NaCl
    %            salinity in mol/kg water. Mole fractions are dimensionless.
    %
    % SEE ALSO:
    %   plotH2BrineSolubilityStudy, generateH2BrineSolubilityTable

    mrstModule add compositional ad-core ad-props;

    %% Load the reference coordinates
    opt = merge_options(struct('plotResults', true, ...
        'outputDirectory', fullfile(pwd, 'build', 'thermodynamics-study')), ...
        varargin{:});
    if ~isfolder(opt.outputDirectory)
        mkdir(opt.outputDirectory);
    end
    root = h2simRoot();
    referenceFile = fullfile(root, 'h2-store', 'examples', 'data', ...
        'PcSaftSolubilityTable', 'ePcSaftH2BrineData.mat');
    reference = load(referenceFile, 'state');
    ref = reference.state;
    validateReference(ref);

    % Use the supplied coordinates rather than assuming a reshape order.
    P = ref.pressure;
    T = ref.T;
    temps = unique(T);
    pressures = unique(P);
    fluid = TableCompositionalMixture({'Water', 'Hydrogen'}, {'H2O', 'H2'});
    z = [0.8, 0.2];

    %% Compare phase partitioning in near-pure water
    rk = generateH2BrineSolubilityTable( ...
        'min_temp', min(T) - 273.15, 'max_temp', max(T) - 273.15, ...
        'n_temp', numel(temps), 'min_press', min(P), 'max_press', max(P), ...
        'n_press', numel(pressures), 'ms', 0, 'outputPath', opt.outputDirectory);
    [found, order] = ismember([T, P], ...
        [rk.("# temperature [°C]") + 273.15, rk.("pressure [Pa]")], 'rows');
    assert(all(found), 'RK and reference coordinates must coincide.');

    sw = SoreideWhitsonEos([], fluid, 'msalt', 0);
    pr = EquationOfStateModel([], fluid, 'pr');
    [Lsw, xsw, ysw] = standaloneFlash(P, T, z, sw);
    [Lpr, xpr, ypr] = standaloneFlash(P, T, z, pr);
    assert(all(Lsw > 0 & Lsw < 1) && all(Lpr > 0 & Lpr < 1), ...
        'Comparison requires two phases.');
    henry = HenrySetschenowH2BrineEos(T, 0, P);
    partition = struct('pressurePa', P, 'temperatureK', T, ...
        'xH2', [rk.x_H2(order), xsw(:, 2), xpr(:, 2), henry.x_H2, ref.X_L(:, 2)], ...
        'yWater', [rk.y_H2O(order), ysw(:, 1), ypr(:, 1), nan(size(P)), ref.X_V(:, 1)], ...
        'modelNames', {{'RK', 'Soreide–Whitson', 'Peng–Robinson', ...
        'Henry–Setschenow', 'ePC-SAFT table'}});

    %% Isolate salinity at 40 degrees C and 15 MPa
    salts = linspace(0, 5, 21).';
    salting = struct('saltMolality', salts, 'pressurePa', 15e6, ...
        'temperatureK', 313.15, 'xH2', zeros(numel(salts), 3), ...
        'modelNames', {{'RK', 'Soreide–Whitson', 'Henry–Setschenow'}});
    for k = 1:numel(salts)
        tab = generateH2BrineSolubilityTable( ...
            'min_temp', 40, 'max_temp', 40, 'n_temp', 1, ...
            'min_press', 15e6, 'max_press', 15.01e6, 'n_press', 2, ...
            'ms', salts(k), 'outputPath', opt.outputDirectory);
        sw.msalt = salts(k);
        [L, x] = standaloneFlash(15e6, 313.15, z, sw);
        assert(L > 0 && L < 1);
        tabH = HenrySetschenowH2BrineEos(313.15, salts(k), 15e6);
        salting.xH2(k, :) = [tab.x_H2(1), x(2), tabH.x_H2];
    end
    validateResults(partition, salting);

    %% Save results and optionally plot
    result = struct('partition', partition, 'salting', salting, ...
        'referenceFile', referenceFile, ...
        'referenceDescription', ...
        'Bundled near-pure-water ePC-SAFT data; no live PC-SAFT computation.', ...
        'HenryPressureConvention', ...
        'Hydrogen-dominated gas: total pressure approximates H2 partial pressure.', ...
        'outputDirectory', opt.outputDirectory);
    file = [tempname, '.mat'];
    cleanup = onCleanup(@() delete(file));
    save(file, 'result', '-v7');
    copyfile(file, fullfile(opt.outputDirectory, 'solubility_results.mat'), 'f');
    if opt.plotResults
        plotH2BrineSolubilityStudy(result, 'outputDirectory', opt.outputDirectory);
    end
end

function validateReference(ref)
    assert(max(abs(ref.components(:, 3:end)), [], 'all') < 1e-6, ...
        'Bundled reference is expected to be the near-pure-water case.');
    assert(numel(unique(ref.T)) * numel(unique(ref.pressure)) == numel(ref.pressure));
end

function validateResults(partition, salting)
    assert(all(isfinite(partition.xH2(:))) && ...
        all(partition.xH2(:) > 0 & partition.xH2(:) < 1));
    assert(all(isfinite(salting.xH2(:))) && ...
        all(salting.xH2(:) > 0 & salting.xH2(:) < 1));
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of h2sim.

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
