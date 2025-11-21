
clearvars; close all;
addpath('acdc')
addpath('info')

verbose = 0;
p_min = 5;
p_max = 200;
p_vals = p_min:p_max;
nP = numel(p_vals);

err_vals = nan(size(p_vals));

% Preallocate a progress display every N steps
report_every = max(1, floor(nP/50));
tic;
for k = 1:nP
    p = p_vals(k);
    % Generate simulated measurement with p points
    try
        [M_FR, simulated_digitizer_FR] = G_FR(verbose, p);
    catch ME
        warning('G_FR failed for p=%d: %s', p, ME.message);
        err_vals(k) = NaN;
        continue;
    end

    % Process measurement to get fit structure
    try
        [f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', 0);
    catch ME
        warning('P_FR failed for p=%d: %s', p, ME.message);
        err_vals(k) = NaN;
        continue;
    end

    % Evaluate the piecewise fit at the measurement frequencies
    try
        fit_data_y = piecewise_FR_evaluate(FR_fit, f.v, M_FR.fs);
    catch ME
        warning('piecewise_FR_evaluate failed for p=%d: %s', p, ME.message);
        err_vals(k) = NaN;
        continue;
    end

    % Compute error using same metric used in piecewise_FR_fit verbose block:
    idx = ~isnan(fit_data_y);
    if any(idx)
        %err_vals(k) = sum(abs(fit_data_y(idx) - measured_digitizer_FR.v(idx)));
        err_vals(k) = trapz(M_FR.f.v(1:2:end), simulated_digitizer_FR.v(1:2:end))-trapz(f.v, measured_digitizer_FR.v)
    else
        err_vals(k) = NaN;
    end

    % Progress reporting
    if mod(k, report_every) == 0 || k == nP
        elapsed = toc;
        fprintf('p = %5d  (%d/%d)  current err = %.3g  elapsed = %.1fs\n', p, k, nP, err_vals(k), elapsed);
    end
end

% Final plot
figure;
plot(p_vals, abs(err_vals./err_vals(end)) - 1, '-b');
xlabel('number of frequency points p');
ylabel('total absolute fit error sum(|fit - measured|)');
title('Sweep of p vs piecewise_FR_fit absolute error');

% Optional: plot in log scale for error
figure;
semilogy(p_vals, abs(err_vals./err_vals(end)) - 1, '-r');
xlabel('number of frequency points p');
ylabel('total absolute fit error (log scale)');
title('Sweep of p vs piecewise_FR_fit absolute error (log)');

% save('sweep_p_err_results.mat', 'p_vals', 'err_vals');
