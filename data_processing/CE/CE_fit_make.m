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
    % Check inputs %<<<2
    % check if input lengts are properly ordered from longer to shorter.
    % Ratio of voltages is calculated as longer./shorter:
    if L1 > L2
        V_ratio = V1./V2;
    else
        V_ratio = V2./V1;
    end
    % cable length difference (longer minus shorter):
    L = abs(L1 - L2);

    % Initialize %<<<2
    % if full cable erro fit (0) is not available, script will calculate error
    % as an average (1)
    do_average = 0;

    if numel(f) == 1
        % Single point case %<<<2
        warning('CE_fit_make: only single frequency point provided. Fitting by cable error model is disabled.')
        do_average = 1;
    else
        % Multiple point case - fitting using cable error model %<<<2
        try
            %TODO use better model?
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
            % results are much better than with full numbers of V_ratio.
            V_err_rel = V_ratio - 1;
            [beta, R, J, COVB, MSE] = nlinfit (f, V_err_rel, model_fun, p0);
            if or(beta <= 0, beta >=299792458)
                error('WAC:bad_CE_fit', 'CE_fit_make: fitted parameter nu (propagation velocity) is non-physical (<= 0 or >=299792458). Fit failed.');
            end

            % now make proper function to generate voltage ratio including 1 and put it
            % into the result structure:
            model_fun = eval(sprintf('@(p, f) 1 + 2.*pi.^2.*(f .* %.16g./p(1)).^2', L));

            % output structure:
            fit.method = 'nlinfit';
            % model_fun is saved as string to allow saving into .mat files v7
            fit.model_fun = func2str(model_fun);
            fit.params = beta;
        catch ERR
            switch ERR.identifier
                case 'WAC:bad_CE_fit'
                    warning([ERR.message ' Falling back to a simple average.'])
                    do_average = 1;
                otherwise
                    rethrow(ERR);
            end % switch
        end % try-catch
    end % if numel(f) == 1

    if do_average
        % Average case: no fit, just return the average of the voltage ratios as a constant model
        avg_V_ratio = mean(V_ratio);
        model_fun = @(p, f) p(1) * ones(size(f));  % constant model
        fit.method = 'average';
        fit.model_fun = func2str(model_fun);
        fit.params = avg_V_ratio;
    end

end % function CE_fit_make

% demo %<<<1
%!demo
%! % Generate synthetic cable error data with very small noise and calculate fit
%! randn('seed', 1);  % reproducible random noise
%! f = linspace(1e3, 100e3, 20)';  % frequency from 100 Hz to 100 kHz
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
%! % Single-point measurement should use average fallback model.
%! f = 50e3;
%! L1 = 1.1;
%! L2 = 0.1;
%! V1 = 1.000123;
%! V2 = 1.0;
%! CE_fit = CE_fit_make(f, V1, V2, L1, L2);
%! assert(strcmp(CE_fit.method, 'average'));
%! assert(CE_fit.params(1), V1./V2, 1e-15);
%! model_fun = str2func(CE_fit.model_fun);
%! y = model_fun(CE_fit.params, [1e3; 2e3; 3e3]);
%! assert(all(abs(y - CE_fit.params(1)) < 1e-15));

%!test
%! % Multi-point measurement should use nlinfit model and recover nu.
%! f = [10e3; 50e3; 100e3];
%! nu = 2e8;
%! L1 = 1.1;
%! L2 = 0.1;
%! L = L1 - L2;
%! V_err_rel = 2.*pi.^2.*(f .* L./nu).^2;
%! V1 = 1 + V_err_rel;
%! V2 = ones(size(f));
%! CE_fit = CE_fit_make(f, V1, V2, L1, L2);
%! assert(strcmp(CE_fit.method, 'nlinfit'));
%! assert(CE_fit.params(1), nu, nu * 1e-10);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
