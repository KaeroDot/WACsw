clear all, close all
addpath('../FR')
% simulation setup:

verbose = 1;
% first simulate FR:
% generate simulated measurement data:
% (no verbose because only CE is relevant here)
[M_FR, simulated_digitizer_FR] = G_FR(0);
% process measurement:
% (no verbose because only CE is relevant here)
[f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', 0);

% Generate simulated CE measurement:
M_CE = G_CE(FR_fit, verbose);

% Process simulated CE measurement:
[CE_fit] = P_CE(M_CE, FR_fit, verbose);

% evaluate simulation
% simualted cable error for measurement poings:
simulated_err_rel_PJVS = cable_error(M_CE.f.v, M_CE.l_PJVS.v);
% calculated cable error from fit:
calculated_err_rel_PJVS = curve_CE_evaluate(CE_fit, M_CE.f.v);

% calculate surface between simulated and calculated error curves:
area = trapz(M_CE.f.v, abs(simulated_err_rel_PJVS - 1 - calculated_err_rel_PJVS));

% TODO relative errors? some output is 1.0001, other 0.0001, FIX!

if verbose
    disp('CE selftest results:')
    fprintf('Total absolute error between simulated and calculated cable error (uV·Hz): %.3f\n', 1e6.*area);

    figure;
    hold on;
    plot(M_CE.f.v, 1e6.*(simulated_err_rel_PJVS - 1), 'xb-', 'LineWidth', 1.5);
    plot(M_CE.f.v, 1e6.*(calculated_err_rel_PJVS), 'xr-', 'LineWidth', 1.5);
    legend('Simulated cable error (full PJVS length)', 'Calculated cable error (short length unknown for calculation)');
    xlabel('Frequency (Hz)');
    ylabel('Relative error (uV/V)'); % TODO is it really relative?
    title(sprintf('selftest_CE.m\nComparison of simulated and calculated cable error\ncurves difference: %g uV.Hz', 1e6.*area), 'interpreter', 'none');
    hold off;
end

% Now do the same but with two CE measurements (first one is made before SS
% measurement, second one is made after SS measurement)
% TODO add time drift between both CE measurements

% Generate second simulated CE measurement:
M_CE(2) = G_CE(FR_fit, verbose);
% Process second simulated CE measurement:
[CE_fit(2)] = P_CE(M_CE(2), FR_fit, verbose);
% make a fit average
CE_fit_int = interpolate_CE_fits(CE_fit);
% evaluate simulation
% calculated cable error from fit:
calculated_err_rel_PJVS_int = curve_CE_evaluate(CE_fit_int, M_CE(1).f.v);

% calculate surface between simulated and calculated error curves:
area = trapz(M_CE(1).f.v, abs(simulated_err_rel_PJVS - 1 - calculated_err_rel_PJVS_int));

if verbose
    fprintf('Total absolute error between simulated and calculated cable error for interpolated CE_fit (uV·Hz): %.3f\n', 1e6.*area);
end
