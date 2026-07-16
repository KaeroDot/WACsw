% This script investigates the impact of number of FR regions on RMS
% values calculated in subsampling measurements.
clear all, close all

%% Constants %<<<1
results_dir_name = 'variate_FR_regions_SS_errors_results';
ref_no_fit_regions = 50;

%% Setup environment %<<<1
% set environment for data processing:
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));
% where to save results:
results_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'evaluation_results', results_dir_name);
% ensure results directory exists:
if not(exist(results_dir, 'dir'))
    mkdir(results_dir);
end

%% Prepare %<<<1
% variate number of regions:
% Maximum of regions list must not exceed S_FR.no_fit_regions.v, otherwise
% results got no sense. However large values also got no sense because the
% simulator of NI5922 is based on real data and is not so fine!
% 100 max?
regions_list = 2:ref_no_fit_regions;

% Preallocate arrays for results
A_rms_values = NaN(size(regions_list));
FR_fit_reg = cell(size(regions_list));

%% First generate all measurements with reference number of FR fit regions %<<<1
% (same process as in selftest_SS)
S_FR.no_fit_regions.v = ref_no_fit_regions; % This value should be larger or same as maximum of regions_list
% Generate simulated FR measurement and process it:
[M_FR, simulated_digitizer_FR] = G_FR(S_FR, 0);
[f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', 0);

% Generate simulated CE measurement before SS and process it:
M_CE(1) = G_CE(FR_fit, 0);
[CE_fit(1)] = P_CE(M_CE(1), 0);
% Generate simulated subsampling measurement:
% Use set of prefefined values no. 2:
M_SS = G_SS(2, 0);

y_filtered = apply_CE_FR_on_samples(M_SS, FR_fit, CE_fit, 1, 0);
M_SS.y.v = y_filtered;

%% Process measured data using different no of regions %<<<1
for k = 1:numel(regions_list)
    % Process all measurements using different number of regions in FR fit:
    M_FR.no_fit_regions.v = regions_list(k);
    [f, measured_digitizer_FR, ac_source_stability, FR_fit_reg{k}] = P_FR(M_FR, '', 0);
    % Calculate cable error:
    [CE_fit_reg(1)] = P_CE(M_CE(1), 0);
    % Process simulated subsampling measurement:
    [A_rms_values(k), A_fft] = P_SS(M_SS, FR_fit_reg{k}, CE_fit_reg, 0);
    % Process simulated subsampling measurement:

    fprintf('[%2d/%2d] No of regions: %g, RMS: %.7f V\n', k, numel(regions_list), regions_list(k), A_rms_values(k));
end

%% Plotting %<<<1
% Plot RMS error vs. no of fit regions %<<<2
figure;
[ax, h1, h2] = plotyy(regions_list, (A_rms_values - 1).*1e6, ...
    regions_list, [[FR_fit_reg{:}].total_error].*1e6);
xlabel('No of regions in FR data processing');
ylabel(ax(1), 'Error of RMS amplitude (ppm)');
ylabel(ax(2), 'Total fit error (x10E-6');
title(sprintf('Error of RMS amplitude caused by data processing\nvs no of regions in FR data processing.\nRef number of fit regions: %d', ref_no_fit_regions));
grid on;
ylim([-100 100])
saveas(gcf, fullfile(results_dir, sprintf('RMS_vs_regions_%d_ref_regions.png', ref_no_fit_regions)));
close(gcf);

% Plot RMS error vs total fit error %<<<2
figure;
plot([[FR_fit_reg{:}].total_error].*1e6, (A_rms_values - 1).*1e6);
xlabel('Total fit error (x10E-6');
ylabel('Error of RMS amplitude (ppm)');
title(sprintf('Error of RMS amplitude caused by data processing\nvs total fit error of FR fit.\nRef number of fit regions: %d', ref_no_fit_regions));
grid on;
ylim([-100 100])
saveas(gcf, fullfile(results_dir, sprintf('RMS_vs_fit_error_%d_ref_regions.png', ref_no_fit_regions)));
saveas(gcf, fullfile(results_dir, sprintf('RMS_vs_fit_error_%d_ref_regions.fig', ref_no_fit_regions)));
close(gcf);

% Plot all fits together %<<<2
figure;
freqs = linspace(10, 0.4.*M_FR.fs.v, 1000);
hold on
for k = 1:numel(regions_list)
    tmp = piecewise_FR_evaluate(FR_fit_reg{k}, freqs, M_FR.fs);
    % this is needed so the plotting library do not complain about extremely
    % large numbers:
    tmp(tmp>1e3) = NaN;
    tmp(tmp<1e-3) = NaN;
    plot(freqs, tmp, 'displayname', sprintf('%d', regions_list(k)))
end
legend();
xlabel('Frequency (Hz)');
ylabel('Frequency response (V/V)');
title(sprintf('Frequency response fits for different number of regions.\nRef number of fit regions: %d', ref_no_fit_regions));
grid on;
ylim([0.998 1.005])
saveas(gcf, fullfile(results_dir, sprintf('all_fits_%d_ref_regions.png', ref_no_fit_regions)));
close(gcf);

% Plot difference of all fits to reference fit together %<<<2
figure;
freqs = linspace(10, 0.4.*M_FR.fs.v, 1000);
hold on
for k = 1:numel(regions_list)
    tmp = piecewise_FR_evaluate(FR_fit_reg{k}, freqs, M_FR.fs) - piecewise_FR_evaluate(FR_fit, freqs, M_FR.fs);
    plot(freqs, tmp, 'displayname', sprintf('%d', regions_list(k)))
end
legend();
xlabel('Frequency (Hz)');
ylabel('Difference to reference fit (V/V)');
title(sprintf('Difference of frequency response fits to\nreference fit for different number of regions.\nRef number of fit regions: %d', ref_no_fit_regions));
grid on;
ylim([-1e-3 1e-3])
saveas(gcf, fullfile(results_dir, sprintf('difference_to_ref_fit_%d_ref_regions.png', ref_no_fit_regions)));
saveas(gcf, fullfile(results_dir, sprintf('difference_to_ref_fit_%d_ref_regions.fig', ref_no_fit_regions)));
close(gcf);
