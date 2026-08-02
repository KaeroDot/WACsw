% -- [M_CE] = G_CE(FR_fit, S_CE, verbose)
% Simulates cable error measurement data.
%
% Inputs:
%   FR_fit  - Frequency response fit structure (from P_FR)
%   S_CE    - Structure with simulation parameters and cable properties. If empty or not provided,
%             default values will be used. Fields (all as Q.v substructures):
%               .f_signal.v       - vector of measurement frequencies (Hz), default: linspace(50, 100e3, 10)
%               .L_long.v         - length of cable to PJVS chip (m), default: 5.1
%               .L_short.v        - length of cable to short (m), default: 0.1
%               .A_nominal.v      - nominal amplitude (V), default: 1
%               .fs.v             - sampling frequency (Hz), default: 4e6
%               .ac_change.v      - AC source total voltage change from beginning to end (V), default: -30e-6
%               .t_one_reading.v  - period between two readings (s), default: 10
%   verbose - If nonzero, generates diagnostic plots (optional)
%
% Outputs:
%   M_CE    - Structure containing simulated cable error measurement data
%
% Usage:
%   [M_FR, ~] = G_FR([], 0);
%   [~, ~, ~, FR_fit] = P_FR(M_FR, '', 0);
%   [M_CE] = G_CE(FR_fit);
%   S_CE.f_signal.v = [100 1000 10000]; [M_CE] = G_CE(FR_fit, S_CE, 1);

function [M_CE] = G_CE(FR_fit, S_CE, verbose);

    % Check inputs %<<<1
    if ~exist('FR_fit', 'var')
        FR_fit = [];
    end
    if ~exist('S_CE', 'var')
        S_CE = struct();
    end
    if isempty(S_CE)
        S_CE = struct();
    end
    if not(isstruct(S_CE))
        error('G_CE: S_CE must be a structure!')
    end
    if ~exist('verbose', 'var')
        verbose = [];
    end

    if isempty(FR_fit)
        error('G_CE: input `FR_fit` is required and cannot be empty. Please provide a valid frequency response fit structure (result from P_FR).')
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Set default simulation parameters %<<<1
    % vector of measurement frequencies (Hz):
    if ~isfield(S_CE, 'f_signal') || ~isfield(S_CE.f_signal, 'v') || isempty(S_CE.f_signal.v)
        S_CE.f_signal.v = linspace(50, 100e3, 10)(:)';
    end
    S_CE.f_signal.v = S_CE.f_signal.v(:)'; % ensure it's a row vector
    % length of the cable to the PJVS chip (m):
    if ~isfield(S_CE, 'L_long') || ~isfield(S_CE.L_long, 'v') || isempty(S_CE.L_long.v)
        S_CE.L_long.v = 5.1;
    end
    % length of the cable to the short (m):
    if ~isfield(S_CE, 'L_short') || ~isfield(S_CE.L_short, 'v') || isempty(S_CE.L_short.v)
        S_CE.L_short.v = 0.1;
    end
    % nominal amplitude (V):
    if ~isfield(S_CE, 'A_nominal') || ~isfield(S_CE.A_nominal, 'v') || isempty(S_CE.A_nominal.v)
        S_CE.A_nominal.v = 1;
    end
    % sampling frequency (Hz):
    if ~isfield(S_CE, 'fs') || ~isfield(S_CE.fs, 'v') || isempty(S_CE.fs.v)
        S_CE.fs.v = 4e6;
    end
    % ac source total change of voltage from the beginning to the end of
    % measurement (V): (drift is calculated from total time of measurement)
    if ~isfield(S_CE, 'ac_change') || ~isfield(S_CE.ac_change, 'v') || isempty(S_CE.ac_change.v)
        S_CE.ac_change.v = -30e-6;
    end
    % period between two readings (s):
    if ~isfield(S_CE, 't_one_reading') || ~isfield(S_CE.t_one_reading, 'v') || isempty(S_CE.t_one_reading.v)
        S_CE.t_one_reading.v = 10;
    end

    % Validate f_signal %<<<1
    if ~isnumeric(S_CE.f_signal.v) || ~isvector(S_CE.f_signal.v)
        error('G_CE: S_CE.f_signal.v must be a numeric vector of frequencies in Hz.')
    end
    if any(~isfinite(S_CE.f_signal.v)) || any(S_CE.f_signal.v <= 0)
        error('G_CE: S_CE.f_signal.v must contain finite positive frequencies only.')
    end
    % double the frequencies because two readings per frequency (short and PJVS):
    f_signal_all_meas = [S_CE.f_signal.v; S_CE.f_signal.v](:)';

    % Simulate measurement %<<<1
    % get voltages of the drifting AC source:
    [A_source, total_err_rel_ppm, t] = AC_source_error_simulator(f_signal_all_meas, S_CE.A_nominal.v, [], S_CE.t_one_reading.v);
    % generate voltage ratios at end of cable for both short and long (PJVS) cable lengths:
    V_ratio_long = simulate_cable(S_CE.f_signal.v, S_CE.L_long.v);
    V_ratio_short = simulate_cable(S_CE.f_signal.v, S_CE.L_short.v);
    % get all voltage ratios according the measurement order (first long (PJVS), then short):
    V_ratio_no_FR = [V_ratio_long; V_ratio_short](:)';
    % only for plotting purposes:
    A_no_FR = A_source .* V_ratio_no_FR;
    % get digitizer gain  from FR fit to simulate measurement by a real digitizer:
    FR_gain = piecewise_FR_evaluate(FR_fit, f_signal_all_meas, S_CE.fs);
    V_ratio = FR_gain .* V_ratio_no_FR;
    A = A_source .* V_ratio;

    % Set output structure %<<<1
    M_CE.A_nominal.v = S_CE.A_nominal.v;
    M_CE.fs = S_CE.fs;
    M_CE.alg_id.v = 'TWM-WRMS';
    M_CE.ac_source_id.v = 'simulated_AC_source';
    M_CE.digitizer_id.v = 'simulated_digitizer';
    M_CE.f.v = f_signal_all_meas;
    M_CE.M.v = f_signal_all_meas; % multiples of periods in record - same number of periods as the frequency
    M_CE.t.v = t;
    M_CE.A.v = A;
    M_CE.FR_fit = FR_fit;
    M_CE.L.v = [S_CE.L_long.v S_CE.L_short.v];
    M_CE.label.v = 'simulated_CE_measurement';

    % Verbose figure %<<<1
	if verbose
        % double y-axis plot of the generated cable errors:
		figure
		hold on
        [ax, h1, h2] = plotyy(S_CE.f_signal.v, 1e6.*(V_ratio_long-1), S_CE.f_signal.v, 1e6.*(V_ratio_short-1));
        set(h1, 'Color', 'b', 'Marker', 'x');
        set(h2, 'Color', 'r', 'Marker', 'x');
        legend([h1; h2], {'long (PJVS)', 'short'}, 'location', 'northwest');
        ylabel(ax(1), 'Amplitude error caused by long (PJVS) cable (uV/V)');
        ylabel(ax(2), 'Amplitude error caused by short cable (uV/V)');
        xlabel('Frequency (Hz)');
        grid on
		title(sprintf('G_CE.m\nsimulated errors caused by cable, long (PJVS) cable length: %.3g m, short cable length: %.3g m', S_CE.L_long.v, S_CE.L_short.v), 'interpreter', 'none');
        hold off

        % second figure - generated amplitudes and drift:
        figure
        hold on
        plot(t(:) - t(1), 1e6.*(A_source(:) - 1), 'kx-');
        plot(t(:) - t(1), 1e6.*(A_no_FR(:) - 1), 'rx-');
        plot(t(:) - t(1), 1e6.*(A(:) - 1), 'bx-');
        xlabel('Measurement time (s)');
        ylabel('Voltage error from nominal (uV)');
        title(sprintf('G_CE.m\nSimulated amplitudes including cable errors and source drift\nFirst reading at selected frequency is with long (PJVS) cable, second is with short'), 'interpreter', 'none');
        legend('AC source voltage', 'Voltage at digitizer input', 'Voltage measured by digitizer due to FR');
        grid on
        hold off
    end
end % function G_CE

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
