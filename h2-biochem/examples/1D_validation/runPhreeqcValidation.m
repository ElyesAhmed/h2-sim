function result = runPhreeqcValidation(varargin)
%Compare compositional PHREEQC with an optional external reference
%
% SYNOPSIS:
%   result = runPhreeqcValidation()
%   result = runPhreeqcValidation('referenceRoot', referenceRoot)
%
% DESCRIPTION:
%   Run the storage-cycle comparison in exampleCompositionalPhreeqcValidation.
%   The default case uses only H2sim and the bundled chemistry database.
%   Supply referenceRoot to add an external comparison. Simulations run
%   serially and save setups, states, and diagnostics for plotting. Only
%   the optional external reference requires Windows MATLAB with COM.
%
% PARAMETERS:
%   Pass name/value options to exampleCompositionalPhreeqcValidation.
%
% SEE ALSO:
%   exampleCompositionalPhreeqcValidation, plotCompositionalPhreeqcValidation

    result = exampleCompositionalPhreeqcValidation(varargin{:});
end
