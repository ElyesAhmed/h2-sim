classdef SRBTracerConvRate < StateFunction
    % Molar reaction source/sink rates for the SO4 and HS aqueous tracers
    % due to sulfate-reducing bacteria (SRB) growth.
    %
    % SYNOPSIS:
    %   scr = SRBTracerConvRate(model)
    %
    % DESCRIPTION:
    %   SO4^2- and HS- are non-volatile and are tracked as aqueous
    %   tracers outside the EOS/flash (see BiochemistryModel primary
    %   variables 'SO4'/'HS' and AqueousTracerMass), unlike the volatile
    %   H2S EOS component. This state function computes their molar
    %   reaction rates [mol/s] from the same bacterial growth kinetics
    %   used for the EOS component sources in BactConvertionRate:
    %
    %       SO4 sink:  q_SO4 = gamrsub/|gamrH2| * nbactMax * qbase / rhoL
    %       HS source: q_HS  = (1 - f_H2S) * gamp2/|gamrH2| * nbactMax * qbase / rhoL
    %
    %   where qbase = PsiGrowthRate .* BacterialMass ./ Y_H2, and f_H2S
    %   is the pH/salinity-dependent fraction of total sulfide produced
    %   that stays volatile (H2S); the complementary f_H2S fraction is
    %   applied to the H2S EOS component source in BactConvertionRate.
    %
    %   Optional anhydrite dissolution adds a positive sulfate rate:
    %       drive = 1 - C_SO4/C_eq
    %       smooth_drive = 0.5*(drive + sqrt(drive^2 + 1e-6))
    %       q_dissolve = k_dissolve * specific_surface_area ...
    %                    * max(sL, 1e-8)^sw_exponent * smooth_drive * V_cell
    %   The smoothing and saturation floor are part of the existing model.
    %   This is a kinetic source, not a PHREEQC mineral-equilibrium call.
    %
    % RETURNS:
    %   q - {qSO4, qHS} molar rates [mol/s]. Biological SO4 consumption is
    %       negative; dissolution can make the net sulfate rate positive.
    %
    % SEE ALSO:
    %   BactConvertionRate, AqueousTracerMass, SoreideWhitsonEos

    properties
        % Optional kinetic anhydrite dissolution, independent of PHREEQC.
        k_dissolve = 4.1e-7;          % Base dissolution constant (mol/m2/s)
        specific_surface_area = 1500; % Mineral area per bulk volume [m2/m3]
        C_eq = 20;                    % Equilibrium threshold (mol/m3)
        sw_exponent = 1.5;            % Saturation scaling factor (n)
        enable_sulfate_source = true; % Toggle flag
    end

    methods
        function scr = SRBTracerConvRate(model, varargin)
            scr@StateFunction(model, varargin{:});
            if isprop(model, 'ReservoirModel') && ~isempty(model.ReservoirModel)
                rm = model.ReservoirModel;
            else
                rm = model;
            end
            if isprop(rm, 'enableSulfateSource')
                scr.enable_sulfate_source = rm.enableSulfateSource;
            end
            scr = scr.dependsOn({'BacterialMass', 'Density'}, 'PVTPropertyFunctions');
            scr = scr.dependsOn('PsiGrowthRate', 'state');
            scr = scr.dependsOn('so4', 'state');
            scr = scr.dependsOn('s', 'state');
            if isprop(model, 'phreeqcTimestepCoupling') && model.phreeqcTimestepCoupling
                scr = scr.dependsOn('phreeqcPH', 'state');
            end
            scr.label = 'Q_{SRB,tracer}';
        end

        function q = evaluateOnDomain(scr, model, state)
            if isprop(model, 'ReservoirModel') && ~isempty(model.ReservoirModel)
                rm = model.ReservoirModel;
            else
                rm = model;
            end
            q = {0, 0};
            if isempty(rm) || ~isprop(rm, 'sulfateReduction') || ~rm.sulfateReduction
                return;
            end
            if ismethod(rm, 'isSequentialCompositionalPhreeqcBackend') && ...
                    rm.isSequentialCompositionalPhreeqcBackend()
                % Kinetic sulfate/sulfide changes are supplied by the
                % post-convergence compositional PHREEQC split in this mode.
                return;
            end

            bcrm = rm.biochemFluid;
            idxS = find(strcmp(bcrm.metabolicReaction, 'SulfateReducingBacteria'), 1);
            if isempty(idxS)
                return;
            end

            bmass = rm.PVTPropertyFunctions.get(rm, state, 'BacterialMass');
            psigrowth = model.getProps(state, 'PsiGrowthRate');

            if iscell(bmass)
                bmass_i = bmass{idxS};
            else
                bmass_i = bmass(:, idxS);
            end
            if iscell(psigrowth)
                psigrowth_i = psigrowth{idxS};
            else
                psigrowth_i = psigrowth(:, idxS);
            end

            Y_H2     = bcrm.Y_H2(idxS);
            nbactMax = bcrm.nbactMax(idxS);
            gamrH2   = bcrm.gamrH2(idxS);
            gamrsub  = bcrm.gamrsub(idxS);
            gamp2    = bcrm.gamp2(idxS);

            qbase      = psigrowth_i .* bmass_i ./ Y_H2;
            qSO4_total = nbactMax .* gamrsub ./ abs(gamrH2) .* qbase;
            qS2_total  = nbactMax .* gamp2   ./ abs(gamrH2) .* qbase;

            % BiochemistryModel inserts the EOS-component conversion
            % source as BactConvRate/rhoL. Apply the same scaling to the
            % biological aqueous-tracer sources so 4 mol H2 consumed
            % corresponds to 1 mol SO4 consumed.
            rho = rm.PVTPropertyFunctions.get(rm, state, 'Density');
            L_ix = rm.getLiquidIndex();
            if iscell(rho)
                rhoL = rho{L_ix};
            else
                rhoL = rho(:, L_ix);
            end
            qSO4_bio = qSO4_total ./ rhoL;
            qS2_bio  = qS2_total ./ rhoL;

            if isfield(state, 'phreeqcPH')
                pH = state.phreeqcPH;
            else
                pH = [];
            end
            fH2S = rm.EOSModel.fractionH2SVolatile(state.T, pH);

            % Add optional kinetic anhydrite dissolution to the sulfate sink.
            if scr.enable_sulfate_source
                r_dissolution = scr.getAnhydriteSource(rm, state, L_ix);
                q{1} = qSO4_bio + r_dissolution;
            else
                q{1} = qSO4_bio;
            end

            q{2} = (1 - fH2S) .* qS2_bio;
        end
    end

    methods (Access = private)
        function r_dissolution = getAnhydriteSource(scr, rm, state, L_ix)
            % Optional positive sulfate source in the model's liquid phase.
            s = rm.getProps(state, 's');
            SO4_conc = rm.getProps(state, 'so4');

            if iscell(s)
                sL = max(s{L_ix}, 1.0e-8);
            else
                sL = max(s(:, L_ix), 1.0e-8);
            end

            % Smoothed positive driving force, retaining AD derivatives.
            drive = 1 - (SO4_conc ./ scr.C_eq);
            smooth_drive = 0.5 * (drive + (drive.^2 + 1e-6).^0.5);

            % Rate density [mol/(m3 bulk*s)] with the existing saturation floor.
            r_density = scr.k_dissolve.* scr.specific_surface_area.* ...
                        (sL.^scr.sw_exponent).* smooth_drive;

            % Integrate over cell bulk volumes to obtain mol/s.
            V_cell = rm.G.cells.volumes;
            r_dissolution = r_density .* V_cell;
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
