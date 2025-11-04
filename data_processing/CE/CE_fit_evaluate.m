% Evaluate voltage ratio caused by cable error for selected frequencies
%
% Inputs:
%   CE_fit - structure containing cable error model and fit parameters
%   f  - frequency vector for evaluation
% Outputs:
%   V_ratio = V(L)./V_s, where V_s is voltage of source, V(L) is voltage at
%   the end of the cable of length L.
%
function V_ratio = CE_fit_evaluate(CE_fit, f)
    if strcmp(CE_fit.method, 'nlinfit')
        V_ratio = CE_fit.model_fun(CE_fit.params, f);
    else
        error('CE_fit_evaluate: unknown fit method `%s`!', CE_fit.method)
    end
end % function CE_fit_evaluate

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4

