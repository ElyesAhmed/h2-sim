classdef ChemotaxisBactFlux < StateFunction
    % Chemotactic bacterial mass flux driven by dissolved H2 gradients.
    %
    % SYNOPSIS:
    %   flux = ChemotaxisBactFlux(model)
    %
    % DESCRIPTION:
    %   Computes J_i = rhoL_face .* T_i .* Grad(xH2_i) [kg/s].
    %   ChemotaxisTransmissibility contains the effective chemotactic
    %   coefficient and geometry. The volume-filling population factor
    %   is evaluated by MicrobialChemotaxis. Positive flux follows the
    %   increasing dissolved-H2 mole fraction, opposite to diffusion.
    %
    % SEE ALSO:
    %   MicrobialChemotaxis, ChemotaxisTransmissibility, DiffusiveBactFlux

    methods

        % -----------------------------------------------------------------%
        function df = ChemotaxisBactFlux(model, varargin)
            df@StateFunction(model, varargin{:});
            df = merge_options(df, varargin{:});

            % Dependencies
            df = df.dependsOn('ChemotaxisTransmissibility');
            df = df.dependsOn('x', 'state');
            df = df.dependsOn('Density', 'PVTPropertyFunctions');

            df.label = 'J_{bact}^{chemo}';
        end

        % -----------------------------------------------------------------%
        function DN = evaluateOnDomain(prop, model, state)
            op = model.operators;
            bcrm = model.biochemFluid;
            nbioreact = bcrm.nbioreact;

            % Retrieve chemotactic transmissibility
            T = prop.getEvaluatedDependencies(state, 'ChemotaxisTransmissibility');

            % State variables and properties
            [x, rho] = model.getProps(state, 'x', 'Density');

            % One internal-face mass flux per microbial population [kg/s].
            DN = cell(1, nbioreact);
            [DN{:}] = deal(0);

            % Liquid density (face averaged)
            namecp = model.getComponentNames();
            L_ix = model.getLiquidIndex();
            if iscell(rho)
                rhoL = rho{L_ix};
            else
                rhoL = rho(:, L_ix);
            end
            rhoLf = model.operators.faceAvg(rhoL);

            for i = 1:nbioreact
                indH2 = find(strcmpi(namecp, bcrm.rH2(i)), 1);
                if iscell(x)
                    xH2 = x{indH2};
                else
                    xH2 = x(:, indH2);
                end

                % Chemotactic flux on internal faces
                DN{i} = +rhoLf .* T{i} .* op.Grad(xH2);
            end
        end

    end
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
