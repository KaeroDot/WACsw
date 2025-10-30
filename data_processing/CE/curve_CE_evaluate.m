% Evaluate cable error model fit for selected frequencies
%
% Inputs:
%   CE_fit - structure containing cable error model and parameters
%   f  - frequency vector for evaluation
%
function y = curve_CE_evaluate(CE_fit, f)
    if CE_fit.method == 'nlinfit'
        y = CE_fit.model_fun(CE_fit.params, f);
    else
        error('CE_evaluate: unknown fit method `%s`!', CE_fit.method)
    end
end % function curve_CE_evaluate

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4

