function result = runPhreeqcValidation(varargin)
%Compare compositional PHREEQC with an external UGFACT reference
%
% SYNOPSIS:
%   result = runPhreeqcValidation('ugfactRoot', referenceRoot)
%
% DESCRIPTION:
%   Run the storage-cycle comparison in exampleCompositionalPhreeqcValidation.
%   A separate UGFACT checkout supplies the reference model. Both simulations
%   run serially, and their setups, states, and comparison diagnostics are
%   saved for subsequent plotting. The external reference requires Windows
%   MATLAB with IPhreeqcCOM.
%
% PARAMETERS:
%   Pass name/value options to exampleCompositionalPhreeqcValidation.
%
% SEE ALSO:
%   exampleCompositionalPhreeqcValidation, plotCompositionalPhreeqcValidation

    result = exampleCompositionalPhreeqcValidation(varargin{:});
end
