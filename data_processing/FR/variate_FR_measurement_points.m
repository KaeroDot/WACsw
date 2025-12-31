% This script variates the number of frequency points during FR measurement to
% find out minimal needed number of measuement points

clear all;
addpath('acdc')
addpath('info')

% variate number measurement points:
verbose = 0;
P_list = 5:200;
P_list = 5:50; % TODO SMAZAT

err_vals = nan(size(P_list));

% Preallocate a progress display every N steps
report_every = max(1, floor(numel(P_list)/50));
for k = 1:numel(P_list)
    p = P_list(k);
    % Generate simulated measurement
    [M_FR, simulated_digitizer_FR] = G_FR(verbose, P_list(k));
    % Process measurement to get fit structure
    [f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', 0);
    % Evaluate the piecewise fit at the measurement frequencies
    fit_data_y = piecewise_FR_evaluate(FR_fit, f.v, M_FR.fs);

    % Compute error by calculating integral difference between simulated and fit:
    idx = ~isnan(fit_data_y);
    if any(idx)
        err_vals(k) = trapz(M_FR.f.v(1:2:end), simulated_digitizer_FR.v(1:2:end))-trapz(f.v, measured_digitizer_FR.v);
    else
        err_vals(k) = NaN;
    end
end

% plot errors in log scale
figure;
semilogy(P_list, abs(err_vals./err_vals(end)) - 1, '-r');
xlabel('number of frequency points p');
ylabel('Integral error between simulated and piecewise_FR_fit (absolute)');
ylabel('total absolute fit error (log scale)');
title('Errors of the FR vs number of measurement points');

% saveas(gcf(),'variate_FR_measurement_points.fig')
% saveas(gcf(),'variate_FR_measurement_points.png')
