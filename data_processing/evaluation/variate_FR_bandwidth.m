% This script investigates the impact of flattening high-frequency part of
% frequency response on RMS values calculated in subsampling measurements.

%% Setup environment %<<<1
clear all, close all

% set environment for data processing:
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));

% where to save results:
results_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'evaluation_results', 'variate_FR_bandwidth_results');
if not(exist(results_dir, 'dir'))
    mkdir(results_dir);
end

%% Settings %<<<1
% set prefix to the results:
fn_prefix = 'flatten_to_last';
% Define flattened high-frequency fractions to test.
% 0.25 means highest 25 % of frequencies are flattened to gain 1.
flatten_fraction_list = [0:0.01:1];
% Monte Carlo iterations for each flattening fraction:
MCM = 100;

%% Calculation %<<<1

% Preallocate arrays for results
A_rms_values = NaN(size(flatten_fraction_list));

% loop through monte carlo iterations:
for MC_iter = 1:MCM
    % Loop through different flattening fractions
    for k = 1:numel(flatten_fraction_list)
        % Generate simulated FR measurement and process it:
        [M_FR, simulated_digitizer_FR] = G_FR([], 0);
        [f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', 0);

        % Generate simulated CE measurement before SS and process it:
        M_CE(1) = G_CE(FR_fit, 0);
        [CE_fit(1)] = P_CE(M_CE(1), 0);

        % Generate simulated subsampling measurement (set no. 2):
        M_SS = G_SS(2, 0);

        % Apply true FR+CE to the generated waveform:
        y_filtered = apply_CE_FR_on_samples(M_SS, FR_fit, CE_fit(1), 1, 0);
        M_SS.y.v = y_filtered;

        % Flatten FR from highest frequencies to lower frequencies:
        flatten_fraction = flatten_fraction_list(k);
        FR_flat = measured_digitizer_FR;

        if flatten_fraction > 0
            f_min = min(f.v);
            f_max = max(f.v);
            f_flat_start = f_max - flatten_fraction.*(f_max - f_min);
            idx_flat = f.v >= f_flat_start;
            idx_ref = find(not(idx_flat), 1, 'last');
            if isempty(idx_ref)
                idx_ref = 1;
            end
            % flattening by setting to 1:
            % FR_flat.v(idx_flat) = 1;
            % flattening by setting gain to last value:
            FR_flat.v(idx_flat) = FR_flat.v(idx_ref);
            % flattening by setting gain to zero:
            % FR_flat.v(idx_flat) = 0;
        end

        %% Variate FR data by random correlated noise:
        n = numel(FR_flat.v); % Number of points in FR data
        rho = 0.5;        % Desired correlation between all pairs - weak correlation
        sigma = 1e-6; % desired standard deviation
        Sigma = sigma^2 * ((1 - rho) * eye(n) + rho * ones(n)); % Covariance matrix
        FR_flat_noisy.v = mvnrnd(FR_flat.v, Sigma, 1)(:)'; % 1 row of correlated Gaussian numbers

        % Build fit from flattened and noisied FR data:
        FR_fit_flat = piecewise_FR_fit(f, FR_flat_noisy, M_FR, 0);

        % % Compare original FR and flattened FR:
        % figure();
        % plot(f.v, measured_digitizer_FR.v, '-b', f.v, FR_flat.v, '-r');
        % legend('Original FR', 'Flattened FR', 'location', 'best');
        % xlabel('Frequency (Hz)');
        % ylabel('Gain (V/V)');
        % title(sprintf('FR flattening of highest %.0f%%%% of frequencies', flatten_fraction.*100));
        % grid on;
        % saveas(gcf, fullfile(results_dir, sprintf('%s_FR_flatten_highest_%03d_percent.png', fn_prefix, round(flatten_fraction.*100))));
        % close(gcf);

        % Process simulated subsampling measurement with flattened FR:
        [A_rms_values(MC_iter, k), A_fft] = P_SS(M_SS, FR_fit_flat, CE_fit(1), 0);
    end % for k fraction list
end % for MC iterations

A_rms_mean = mean(A_rms_values, 1);
A_rms_std = std(A_rms_values, 0, 1);

%% Results plot %<<<1
figure();
hold on
plot(flatten_fraction_list.*100, (A_rms_mean - 1).*1e6, '-or');
plot(flatten_fraction_list.*100, (A_rms_mean - 1 + A_rms_std).*1e6, '--g');
plot(flatten_fraction_list.*100, (A_rms_mean - 1 - A_rms_std).*1e6, '--g');
xlabel('Flattened highest frequency range (%)');
ylabel('Measured RMS error (ppm)');
title('Effect of High-Frequency FR Flattening on Measured RMS Value');
xlim([0 100]);
grid on;
saveas(gcf, fullfile(results_dir, [fn_prefix '_FR_flattening_dependence.png']));
saveas(gcf, fullfile(results_dir, [fn_prefix '_FR_flattening_dependence.fig']));
hold off

% csvwrite(fullfile(results_dir, 'FR_flattening_dependence.csv'), ...
%     [flatten_fraction_list(:).*100, (A_rms_values(:) - 1).*1e6]);
