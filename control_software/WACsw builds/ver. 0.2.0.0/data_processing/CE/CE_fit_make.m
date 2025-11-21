% Fit cable error model to frequency-amplitude dependece 
%   Inputs:
%       f - frequency vector
%       V1, V2 - amplitude vectors,
%       L1, L2 - cable lengths
%   Output:
%       CE_fit - structure containing fit information
%
%   The output structure contains:
%       .method - fitting method used ('nlinfit')
%       .model_fun - cable error model function
%       .params    - coefficients of the best fit

function fit = CE_fit_make(f, V1, V2, L1, L2)
    % check if input lengts are properly ordered from longer to shorter.
    % Ratio of voltages is calculated as longer./shorter:
    if L1 > L2
        V_ratio = V1./V2;
    else
        V_ratio = V2./V1;
    end
    % cable length difference (longer minus shorter):
    L = abs(L1 - L2);

    %TODO use better model

    % cable error model = 2.*pi.^2.*(f.*L./nu).^2;
    % V_ratio = V_long./V_short
    % based on D. Zhao, H. E. van den Brom, and E. Houtzager, ‘Mitigating
    % voltage lead errors of an AC Josephson voltage standard by impedance
    % matching’, Measurement Science and Technology, vol. 28, no. 9, p. 095004,
    % Sept. 2017, doi: 10.1088/1361-6501/aa7aba.
    % (using eval so the L is hardcoded into the function and variable L does
    % not have to be saved together with model_fun)
    model_fun = eval(sprintf('@(p, f) 2.*pi.^2.*(f .* %.16g./p(1)).^2', L));
    % Initial guess for parameters [a, b]
    p0 = 2e8; % initial guess for nu (m/s) as 66 % of speed of light
    % make the fit. Fitting is done with voltage errors only, because the
    % results are much better (fitting near zero is bettter, dunno why, but it
    % is general quality)
    V_err_rel = V_ratio - 1;
    [beta, R, J, COVB, MSE] = nlinfit (f, V_err_rel, model_fun, p0);
    if beta <= 0
        error('CE_fit_make: fitted parameter nu (propagation velocity) is non-physical (<= 0). Fit failed.');
    end

    % now make proper function to generate voltage ratio including 1 and put it
    % into the result structure:
    model_fun = eval(sprintf('@(p, f) 1 + 2.*pi.^2.*(f .* %.16g./p(1)).^2', L));

    % output structure:
    fit.method = 'nlinfit';
    % model_fun is saved as string to allow saving into .mat files v7
    fit.model_fun = func2str(model_fun);
    fit.params = beta;
end % function CE_fit_make

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
