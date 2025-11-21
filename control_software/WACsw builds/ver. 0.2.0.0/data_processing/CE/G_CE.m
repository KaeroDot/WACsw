% Simulates cable error measurement data.
%
% Inputs:
%   FR_fit  - Frequency response fit structure (from P_FR)
%   verbose - If nonzero, generates diagnostic plots (optional)
%
% Outputs:
%   M_CE    - Structure containing simulated cable error measurement data
%
% Usage:
%   [M_FR, ~] = G_FR(0);
%   [~, ~, ~, FR_fit] = P_FR(M_FR, '', 0);
%   [M_CE] = G_CE(FR_fit, 1)

function [M_CE] = G_CE(FR_fit, verbose);

    % Check inputs %<<<1
    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Constants %<<<1
    % length of the cable to the PJVS chip (m):
    L_long = 5.1;
    % length of the cable to the short (m):
    L_short = 0.1;
    % signal (measurement) frequencies (Hz):
    f_signal = linspace(50, 100e3, 10);
    % double the frequencies because two readings per frequency (short and PJVS):
    f_signal_all_meas = [f_signal; f_signal](:)';
    % nominal amplitude:
    A_nominal = 1; % V
    % sampling frequency (MS/s):
    fs.v = 4e6;
	% ac source total change of voltage from the beginning to the end of
	% measurement (V): % (drif is calculated from total time of measurement)
    ac_change = -30e-6;
    % period between two readings (s):
    t_one_reading = 10;

    % Simulate measurement %<<<1
    % get voltages of the drifting AC source:
    [A_source, total_err_rel_ppm, t] = AC_source_error_simulator(f_signal_all_meas, A_nominal, [], t_one_reading);
    % generate voltage ratios at end of cable for both short and long (PJVS) cable lengths:
    V_ratio_long = simulate_cable(f_signal, L_long);
    V_ratio_short = simulate_cable(f_signal, L_short);
    % get all voltage ratios according the measurement order (first long (PJVS), then short):
    V_ratio_no_FR = [V_ratio_long; V_ratio_short](:)';
    % only for plotting purposes:
    A_no_FR = A_source .* V_ratio_no_FR;
    % get digitizer gain  from FR fit to simulate measurement by a real digitizer:
    FR_gain = piecewise_FR_evaluate(FR_fit, f_signal_all_meas, fs);
    V_ratio = FR_gain .* V_ratio_no_FR;
    A = A_source .* V_ratio;

    % Set output structure %<<<1
    M_CE.A_nominal.v = A_nominal;
    M_CE.fs = fs;
    M_CE.alg_id.v = 'TWM-WRMS';
    M_CE.ac_source_id.v = 'simulated_AC_source';
    M_CE.digitizer_id.v = 'simulated_digitizer';
    M_CE.f.v = f_signal_all_meas;
    M_CE.M.v = f_signal_all_meas; % multiples of periods in record - same number of periods as the frequency
    M_CE.t.v = t;
    M_CE.A.v = A;
    M_CE.FR_fit = FR_fit;
    M_CE.L.v = [L_long L_short];
    M_CE.label.v = 'simulated_CE_measurement';

    % Verbose figure %<<<1
	if verbose
        % double y-axis plot of the generated cable errors:
		figure
		hold on
        [ax, h1, h2] = plotyy(f_signal, 1e6.*(V_ratio_long-1), f_signal, 1e6.*(V_ratio_short-1));
        set(h1, 'Color', 'b');
        set(h2, 'Color', 'r');
        legend([h1; h2], {'long (PJVS)', 'short'}, 'location', 'northwest');
        ylabel(ax(1), 'Amplitude error caused by long (PJVS) cable (uV/V)');
        ylabel(ax(2), 'Amplitude error caused by short cable (uV/V)');
        xlabel('Time (s)');
        grid on
		title(sprintf('G_CE.m\nsimulated errors caused by cable, long (PJVS) cable length: %.3g m, short cable length: %.3g m', L_long, L_short), 'interpreter', 'none');
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
