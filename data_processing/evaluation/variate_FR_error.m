% This script investigates the impact of frequency response slope errors on RMS
% values calculated in subsampling measurements.

%% Setup environment %<<<1
clear all, close all
% set environment for data processing:
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));
% where to save reulsts:
results_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'evaluation_results', 'variate_FR_error_results');
% ensure results directory exists:
if not(exist(results_dir, 'dir'))
    mkdir(results_dir);
end

%% Calculation %<<<1
% Generate SS measurement structure for testing
M_SS = G_SS(1, 0);

% Define range of FR slope errors to test
slope_error_list = [-3e-9:0.1e-9:3e-9];

% Preallocate arrays for results
A_rms_values = NaN(size(slope_error_list));

% Loop through different slope errors
for k = 1:numel(slope_error_list)
    % Generate simulated FR measurement and process it:
    [M_FR, simulated_digitizer_FR] = G_FR([], 0);
    [f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', 0);

    % Generate simulated CE measurement before SS and process it:
    M_CE(1) = G_CE(FR_fit, 0);
    [CE_fit(1)] = P_CE(M_CE(1), 0);
    % Generate simulated subsampling measurement:
    % Use set of prefefined values no. 2:
    M_SS = G_SS(2, 0);

    y_filtered = apply_CE_FR_on_samples(M_SS, FR_fit, CE_fit(1), 1, 0);
    M_SS.y.v = y_filtered;

    % Spoil measurement of the FR by apllying slope error to the measurement:
    spoiled_S_FR.FR_slope.v  = slope_error_list(k);
    [M_FR_err, simulated_digitizer_FR_err] = G_FR(spoiled_S_FR, 0);
    [f_err, measured_digitizer_FR_err, ac_source_stability_err, FR_fit_err] = P_FR(M_FR_err, '', 0);
    % compare FR_fit used for samples creation and FR_fit_err used for
    % data calculation:
    figure()
    plot(f.v, measured_digitizer_FR.v, '-b', f_err.v, measured_digitizer_FR_err.v, '-r')
    title(sprintf('FR measurement with slope error: %g', slope_error_list(k)));
    saveas(gcf, fullfile(results_dir, sprintf('FR_slope_error_%g.png', slope_error_list(k))));
    close(gcf);

    % Process simulated subsampling measurement with erroneous FR:
    [A_rms_values(k), A_fft] = P_SS(M_SS, FR_fit_err, CE_fit(1), 0);

    fprintf('[%2d/%2d] Slope error: %g, RMS: %.7f V\n', k, numel(slope_error_list), slope_error_list(k), A_rms_values(k));
end

A_rms_values - A_rms_values(1)

% Plot RMS values vs. slope error
figure;
plot(slope_error_list.*1e9, (A_rms_values - 1).*1e6, '-o');
xlabel('FR Slope Error x10^{-9}, multiplicator of the frequency value');
ylabel('Measured RMS error (ppm)');
title('Effect of FR Slope Error on Measured RMS Value');
xlim([-0.5 0.5])
ylim([-22 22])
grid on;
saveas(gcf, fullfile(results_dir, 'FR_slope_error_dependence.png'));
