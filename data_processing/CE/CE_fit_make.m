% Fit cable error model to frequency-amplitude dependece. For the case of single
% measurment point, the scripts adds a point at 0 Hz with V_ratio=1 to make the
% fit possible.
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

function fit = CE_fit_make(f, V1, V2, L1, L2) %<<<1
    % check if input lengts are properly ordered from longer to shorter.
    % Ratio of voltages is calculated as longer./shorter:
    if L1 > L2
        V_ratio = V1./V2;
    else
        V_ratio = V2./V1;
    end
    % cable length difference (longer minus shorter):
    L = abs(L1 - L2);


    % Single point case %<<<2
    if numel(f) == 1
        % Case of single point cable error measurement with only single
        % frequency point. Suppose at 0 Hz there is no error. Add measurement
        % point f=0, V_ration=1.
        f = [0 f];
        V_ratio = [1 V_ratio];
        warning('CE_fit_make: only single frequency point provided. New point f=0 Hz, V_ratio=1 was added to make fit possible.');
    end

    % Multiple frequency points, make fit according a cable error model %<<<2
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
    if or(beta <= 0, beta >=299792458)
        error('CE_fit_make: fitted parameter nu (propagation velocity) is non-physical (<= 0 or >=299792458). Fit failed.');
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

% demo %<<<1
%!demo
%! % Generate synthetic cable error data with very small noise and calculate fit
%! randn('seed', 1);  % reproducible random noise
%! f = linspace(1e3, 100e3, 5)';  % frequency from 100 Hz to 100 kHz
%! L = 1;  % cable length difference (m)
%! nu = 2e8;  % propagation velocity (m/s)
%! 
%! % Generate noise-free cable error
%! V_err_rel_ideal = 2.*pi.^2.*(f .* L./nu).^2;
%! 
%! % Add small random noise
%! noise = 1e-6 .* randn(size(f));
%! V_err_rel_noisy = V_err_rel_ideal + noise;
%! V_ratio_noisy = 1 + V_err_rel_noisy;
%! 
%! % Create two voltage measurements (long and short cable paths)
%! V1 = V_ratio_noisy;  % long cable path
%! V2 = ones(size(f));  % short cable path (reference)
%! L1 = L+0.1;  % longer cable
%! L2 = 0.1;  % shorter cable
%! 
%! % Calculate cable error fit
%! fit = CE_fit_make(f, V1, V2, L1, L2);
%! 
%! % Evaluate the fit over frequency range
%! fplot = linspace(0, 100e3, 50);
%! model_func = str2func(fit.model_fun);
%! V_ratio_fit = model_func(fit.params, fplot);
%! 
%! % Plot voltage ratio errors (relative to 1)
%! figure();
%! plot(f, (V_ratio_noisy - 1) .* 1e6, 'xb', 'LineWidth', 1.5, 'markersize', 6);
%! hold on;
%! plot(fplot, (V_ratio_fit - 1) .* 1e6, '-r', 'LineWidth', 2);
%! plot(f, V_err_rel_ideal .* 1e6, '--g', 'LineWidth', 1.5);
%! hold off;
%! xlabel('Frequency (Hz)');
%! ylabel('Voltage Error (ppm)');
%! title(sprintf('Cable Error Fit Demo (L = %.2f m, \\nu_{fit} = %.2e m/s)', L, fit.params(1)));
%! legend('Noisy measurement', 'Fitted model', 'Ideal (no noise)', 'location', 'northwest');
%! grid on;

% tests %<<<1
%!test
%! % Single point measurement, no noise, nu = 2e8 m/s
%! f = 50e3;
%! nu = 2e8;
%! L1 = 1.1;
%! L2 = 0.1;
%! L = L1 - L2;
%! V_err_rel = 2.*pi.^2.*(f .* L./nu).^2;
%! V1 = 1 + V_err_rel;
%! V2 = 1;
%! CE_fit = CE_fit_make(f, V1, V2, L1, L2);
%! assert(CE_fit.params(1), nu, nu * 1e-10);

%!test
%! % 3-point measurement, no noise, nu = 2e8 m/s
%! f = [10e3; 50e3; 100e3];
%! nu = 2e8;
%! L1 = 1.1;
%! L2 = 0.1;
%! L = L1 - L2;
%! V_err_rel = 2.*pi.^2.*(f .* L./nu).^2;
%! V1 = 1 + V_err_rel;
%! V2 = ones(size(f));
%! CE_fit = CE_fit_make(f, V1, V2, L1, L2);
%! assert(CE_fit.params(1), nu, nu * 1e-10);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
