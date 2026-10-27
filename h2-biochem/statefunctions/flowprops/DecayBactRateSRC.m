classdef DecayBactRateSRC < StateFunction
    % Bacterial decay rate computation for compositional simulations
    %
    % SYNOPSIS:
    %   decay = DecayBactRateSRC(model, 'property1', value1, ...)
    %
    % DESCRIPTION:
    %   Returns one specific decay coefficient [1/s] per population.
    %   First-order decay returns b + 0*nbact, preserving the AD shape.
    %   Legacy quadratic decay returns b*max(nbact, 0). The facility applies
    %   these coefficients to BacterialMass to form a mass sink [kg/s].
    %   Inactive bacteria or liquid phase return zero coefficients. The
    %   existing MET/ACE component guard returns all zeros if a required
    %   H2 or substrate component is missing.
    %
    % SEE ALSO:
    %   GrowthBactRateSRC, BacterialMass, BiochemistryGenericFacilityModel

    methods
        function gp = DecayBactRateSRC(model, varargin)
            % Constructor for bacterial decay rate calculator
            gp@StateFunction(model, varargin{:});

            % Quadratic legacy decay depends on biomass; first-order
            % benchmark decay retains this harmless dependency so both
            % formulations share the same state-function interface.
            gp = gp.dependsOn('nbact', 'state');

            % Set label for output
            gp.label = 'Psi_{decay}';
        end

        function Psidecay = evaluateOnDomain(~, model, state)
            % Compute the specific decay rate coefficient [1/s].
            %
            % PARAMETERS:
            %   model - Reservoir model instance
            %   state - State struct with fields
            %
            % RETURNS:
            %   Psidecay - Decay rate coefficient (depends on current nbact) [1/s]

            % Get model parameters
            if isprop(model, 'ReservoirModel') && ~isempty(model.ReservoirModel)
                rm = model.ReservoirModel;
            else
                rm = model;
            end
            bcrm = rm.biochemFluid;
            nbioreact = bcrm.nbioreact;


            % Initialize with zeros
            Psidecay = cell(1, nbioreact);
            [Psidecay{:}] = deal(0);

            % Check if bacterial modeling is active
            if ~(rm.bacteriamodel && rm.liquidPhase)
                return;
            end

            % Get component names and indices
            namecp = rm.getComponentNames();
            % Validate required components
            for i = 1:nbioreact
                idx_H2 = find(strcmpi(namecp, bcrm.rH2(i)), 1);     % Case-insensitive search
                idx_sub = find(strcmpi(namecp, bcrm.rsub(i)), 1);   % Case-insensitive search
                if strcmp(bcrm.metabolicReaction(i), 'MethanogenicArchae') || ...
                        strcmp(bcrm.metabolicReaction(i), 'AcetogenicBacteria')
                    if isempty(idx_H2) || isempty(idx_sub)
                        return;
                    end
                end
            end

            % Get required state variables
            nbact = rm.getProp(state, 'nbact');

            for i = 1:nbioreact
                if iscell(nbact)
                    nbacti = nbact{i};
                else
                    nbacti = nbact(:, i);
                end
                bbact = bcrm.bbact(i);
                decayOrder = 2;
                if isprop(rm, 'bacterialDecayOrder')
                    decayOrder = rm.bacterialDecayOrder;
                end
                if decayOrder == 1
                    % Paper kinetics: biomass loss is b*M.
                    Psidecay{i} = bbact + 0.*nbacti;
                else
                    % Legacy h2-biochem kinetics: biomass loss is b*n*M.
                    Psidecay{i} = bbact .* max(nbacti, 0);
                end
            end
        end
    end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}