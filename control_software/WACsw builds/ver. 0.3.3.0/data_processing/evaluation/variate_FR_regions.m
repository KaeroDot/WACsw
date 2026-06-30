% This script investigates the impact of number of FR regions on RMS
% values calculated in subsampling measurements.

%% Setup environment %<<<1
clear all, close all
% set environment for data processing:
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));
% where to save reulsts:
results_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'evaluation_results', 'variate_FR_reg_results');
% ensure results directory exists:
if not(exist(results_dir, 'dir'))
    mkdir(results_dir);
end

% ====================
% variate number of regions:
regions_list = 10:250;
fit_errors = NaN(size(regions_list));
% generate simulated frequency response measurement:
[M_FR, simulated_digitizer_FR] = G_FR([], 0);
for k = 1:numel(regions_list)
    M_FR.no_fit_regions.v = regions_list(k);
    f = M_FR.f;
    r = regions_list(k);
    piecewise_fit(k) = piecewise_FR_fit(f, simulated_digitizer_FR, M_FR, 0);
    fit_errors(k) = piecewise_fit(k).total_error;
end

figure;
semilogy(regions_list, fit_errors, '-r', 'MarkerSize', 4)
freqs = linspace(10, 0.4.*M_FR.fs.v, 1000);
saveas(gcf, fullfile(results_dir, sprintf('FR_regions_error.png')));
% TODO title
close(gcf);

figure;
hold on
for k = 1:numel(piecewise_fit)
    tmp = piecewise_FR_evaluate(piecewise_fit(k), freqs, M_FR.fs);
    % this is needed so the plotting library do not complain about extremely
    % large numbers:
    tmp(tmp>1e3) = NaN;
    tmp(tmp<1e-3) = NaN;
    plot(tmp, '-')
end
ylim([0.998 1.005])
% TODO title
saveas(gcf, fullfile(results_dir, sprintf('FR_regions_fits.png')));
close(gcf);
