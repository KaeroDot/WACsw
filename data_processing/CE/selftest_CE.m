clear all, close all

% Setup environment
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));

% simulation setup:

verbose = 1;
% first simulate FR:
% generate simulated measurement data:
% (no verbose because only CE is relevant here)
[M_FR, simulated_digitizer_FR] = G_FR([], 0);
% process measurement:
% (no verbose because only CE is relevant here)
[f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', 0);

% Generate simulated CE measurement:
M_CE = G_CE(FR_fit, verbose);

% Process simulated CE measurement:
[CE_fit] = P_CE(M_CE, verbose);

% evaluate simulation
% simualted cable error for measurement points:
V_ratio_long_sim = simulate_cable(M_CE.f.v, M_CE.L.v(1));
% calculated cable error from fit:
V_ratio_long_calc = CE_fit_evaluate(CE_fit, M_CE.f.v);

% calculate surface between simulated and calculated ratio curves:
area = trapz(M_CE.f.v, abs(V_ratio_long_sim - V_ratio_long_calc));

% TODO relative errors? some output is 1.0001, other 0.0001, FIX!

if verbose
    disp('CE selftest results:')
    fprintf('Curve area between simulated and calculated voltage ratios (uV·Hz): %.3f\n', 1e6.*area);

    figure;
    hold on;
    plot(M_CE.f.v, 1e6.*(V_ratio_long_sim - 1), 'xb-', 'LineWidth', 1.5);
    plot(M_CE.f.v, 1e6.*(V_ratio_long_calc - 1), 'xr-', 'LineWidth', 1.5);
    legend('Simulated voltage ratio for long (PJVS) cable', 'Calculated voltage ratio for long cable');
    xlabel('Frequency (Hz)');
    ylabel('Relative error (uV/V)'); % TODO is it really relative?
    title(sprintf('selftest_CE.m\nComparison of simulated and calculated voltage errors caused by cable lengths\ncurves difference: %g uV.Hz', 1e6.*area), 'interpreter', 'none');
    hold off;
end

% Now do the same but with second CE measurements (first one is made before SS
% measurement, second one is made after SS measurement)
% TODO add time drift between both CE measurements

% Generate second simulated CE measurement:
M_CE(2) = G_CE(FR_fit, verbose);
% Process second simulated CE measurement:
[CE_fit(2)] = P_CE(M_CE(2), verbose);
% make a fit average
CE_fit_int = CE_fits_interpolate(CE_fit);
% evaluate simulation
% calculated cable error from fit:
V_ratio_long_int_calc = CE_fit_evaluate(CE_fit_int, M_CE(1).f.v);

% calculate surface between simulated and calculated error curves:
area_int = trapz(M_CE(1).f.v, abs(V_ratio_long_sim - V_ratio_long_int_calc));

if verbose
    fprintf('Curve area between simulated and calculated voltage ratios for interpolated CE_fit (uV·Hz): %.3f\n', 1e6.*area_int);
end
