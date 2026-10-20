function mixture = h2BiochemCompositionalMixture(names, outnames)
%H2BIOCHEMCOMPOSITIONALMIXTURE Tabulated MRST fluids plus legacy acetate data.
% Keep H2sim's acetic-acid component independent of local MRST table edits.
% The acetate parameters retain the values used by the existing H2sim setup;
% they are an EOS parameterization, not PHREEQC aqueous speciation constants.
if nargin<2, outnames=names; end
assert(numel(names)==numel(outnames));
acid=strcmpi(names,'AceticAcid');
if ~any(acid)
    mixture=TableCompositionalMixture(names,outnames); return
end
n=numel(names); [Tc,Pc,Vc,acc,mass]=deal(zeros(1,n));
if any(~acid)
base=TableCompositionalMixture(names(~acid),outnames(~acid));
Tc(~acid)=base.Tcrit; Pc(~acid)=base.Pcrit; Vc(~acid)=base.Vcrit;
acc(~acid)=base.acentricFactors; mass(~acid)=base.molarMass;
end
Tc(acid)=592; Pc(acid)=5790000; mass(acid)=0.060050;
Vc(acid)=0.060050/276; acc(acid)=0.466;
mixture=CompositionalMixture(outnames,Tc,Pc,Vc,acc,mass);
mixture.name='MRST tabulated fluids with H2sim acetate parameters';
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
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with H2sim. If not, see <https://www.gnu.org/licenses/>.
%}
