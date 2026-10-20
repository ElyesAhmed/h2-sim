function [nls, lsolve] = setupOptimizedLinearSolver(model, varargin)
% Setup optimized AMGCL CPR linear solver for compositional biochemical models
%
% SYNOPSIS:
%   [nls, lsolve] = setupOptimizedLinearSolver(model)
%   [nls, lsolve] = setupOptimizedLinearSolver(model, 'complexityLevel', 'high')
%
% PARAMETERS:
%   model           - BiochemistryModel instance
%   complexityLevel - 'low' (advection only), 'medium' (with diffusion),
%                     'high' (with both diffusion & dispersion) [default: 'medium']
%   solverTolerance - Tolerance for linear solver [default: 1e-4]
%   maxNonlinIter   - Max nonlinear iterations [default: 15]
%   linearThreads   - AMGCL OpenMP threads, no Parallel Toolbox [default: 4]
%   cprDamp         - Retained for backward-compatible calls; AMGCL CPR
%                     does not expose this setting.
%
% RETURNS:
%   nls    - NonLinearSolver configured with linear solver
%   lsolve - Selected linear solver; AMGCL CPR when available for a large model

    opt = struct('complexityLevel', 'medium', ...
                 'solverTolerance', 1e-4, ...
                 'maxNonlinIter', 15, ...
                 'cprDamp', [], ...
                 'linearThreads', 4);
    opt = merge_options(opt, varargin{:});
    validateattributes(opt.linearThreads, {'numeric'}, {'scalar', 'integer', 'positive'});

    % Use an optional user-local AMGCL installation when configured.
    activateH2simAMGCL();

    % Select base linear solver
    lsolve = selectLinearSolverAD(model);

    % Configure AMGCL CPR parameters based on problem complexity
    amgclSettings = struct('max_levels', 20, 'verbose', false);

    switch lower(opt.complexityLevel)
        case 'low'
            % Simple advection-only: aggressive coarsening
            amgclSettings.aggr_eps_strong = 1e-1;
            amgclSettings.maxIterations = 50;

        case 'medium'
            % Diffusion included: balanced settings (default)
            amgclSettings.aggr_eps_strong = 1e-2;
            amgclSettings.maxIterations = 100;

        case 'high'
            % Both diffusion & dispersion: conservative coarsening
            amgclSettings.aggr_eps_strong = 5e-3;
            amgclSettings.maxIterations = 150;

        otherwise
            error('Unknown complexityLevel: %s', opt.complexityLevel);
    end

    % Apply AMGCL settings through the solver's actual configuration
    % interface. Small systems may use the backslash fallback instead.
    if isa(lsolve, 'AMGCLSolverAD')
        lsolve.setCoarsening('aggregation');
        lsolve.amgcl_setup.nthreads = opt.linearThreads;
        lsolve.amgcl_setup.max_levels = amgclSettings.max_levels;
        lsolve.amgcl_setup.verbose = amgclSettings.verbose;
        lsolve.amgcl_setup.aggr_eps_strong = amgclSettings.aggr_eps_strong;
        lsolve.maxIterations = amgclSettings.maxIterations;
    end
    if isa(lsolve, 'AMGCL_CPRSolverAD') && isa(model, 'BiochemistryModel') && model.bacteriamodel
        % Keep bacterial and aqueous tracer cell unknowns in the CPR system.
        % Reducing to fluid components can create an expensive Schur fill-in.
        % Derive the pressure equation from the full local Jacobian.
        % Residual convergence scales are not true-IMPES weights.
        lsolve.decoupling = 'quasiIMPES';
        lsolve.amgcl_setup.block_size = 0;
        lsolve.amgcl_setup.cpr_blocksolver = false;
        lsolve.variableOrdering = [];
        lsolve.equationOrdering = [];
        lsolve.keepNumber = [];
        lsolve.reduceToCell = true;
    end
    lsolve.tolerance = opt.solverTolerance;

    % Configure nonlinear solver
    nls = NonLinearSolver();
    nls.LinearSolver = lsolve;
    nls.maxIterations = opt.maxNonlinIter;
    nls.verbose = false;
end

%{
Copyright 2026 H2sim contributors.

This file is part of H2sim.

H2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

H2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with H2sim.  If not, see <http://www.gnu.org/licenses/>.
%}
