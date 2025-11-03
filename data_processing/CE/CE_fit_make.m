% Fit cable error model to frequency-amplitude dependece 
%   Inputs:
%       f - frequency vector
%       A - amplitude vector
%       M_CE - cable error measurement structure
%   Output:
%       CE_fit - structure containing fit information
%
%   The output structure contains:
%       .model_fun - cable error model function
%       .params    - fitted parameters [a, b]
%       .freqs     - input frequency vector
%       .A_v       - input amplitude vector

function fit = CE_fit_make(f, A, M_CE)
    %TODO use better model
    % cable error model = 2.*pi.^2.*(f.*L./nu).^2; % err = V(L)./V_s
    L = M_CE.L.v; % length difference (m)
    model_fun = @(p, f) 2.*pi.^2.*(f .* L./p(1)).^2;
    % Initial guess for parameters [a, b]
    p0 = 2e8; % initial guess for nu (m/s) as 66 % of speed of light
    % make the fit:
    [beta, R, J, COVB, MSE] = nlinfit (f, A, model_fun, p0);

    fit.method = 'nlinfit';
    fit.model_fun = model_fun;
    fit.params = beta;
    fit.fit.R = R;
    fit.fit.J = J;
    fit.fit.COVB = COVB;
    fit.fit.MSE = MSE;
end % function CE_fit_make

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
