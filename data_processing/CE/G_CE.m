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
    l_PJVS = 5.1;
    % length of the cable to the short (m):
    l_short = 0.1;
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
    % get amplitudes of the drifting AC source:
    [A_source, total_err_rel_ppm, t] = AC_source_error_simulator(f_signal_all_meas, A_nominal, [], t_one_reading);
    % generate cable errors for both short and PJVS:
    err_rel_PJVS = cable_error(f_signal, l_PJVS);
    err_rel_short = cable_error(f_signal, l_short);
    % get all cable errors according the measurement order (first short, then PJVS):
    err_rel_no_FR = [err_rel_short; err_rel_PJVS](:)';
    % only for plotting purposes:
    A_no_FR = A_source .* err_rel_no_FR;

                                    %     % times of readings (two readings per signal frequency):
                                    %     starttime = time();
                                    %     t = starttime + t_one_reading .* [1 : 1 : 2.*numel(f_signal)] - t_one_reading;
                                    %     t = t(:);
                                    % % amplitude of the source - time dependent linear drift that starts at nominal amplitude:
                                    % % (no frequency dependence of ac source!)
                                    % % ac source drift in V/s:
                                    % ac_drift = ac_change./(numel(t).*t_one_reading);
                                    % A_source = A_nominal + ac_drift .* (t - t(1));
    % get relative error from FR fit to simulate measurement by a real digitizer:
    FR_err_rel = piecewise_FR_evaluate(FR_fit, f_signal_all_meas, fs);
    err_rel = FR_err_rel .* err_rel_no_FR;
    A = A_source .* err_rel;

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
    M_CE.FR_fit.v = FR_fit;
    M_CE.l_PJVS.v = l_PJVS;
    M_CE.l_short.v = l_short;

    % Verbose figure %<<<1
	if verbose
        % double y-axis plot of the generated cable errors:
		figure
		hold on
        [ax, h1, h2] = plotyy(f_signal, 1e6.*(err_rel_PJVS-1), f_signal, 1e6.*(err_rel_short-1));
        set(h1, 'Color', 'b');
        set(h2, 'Color', 'r');
        legend([h1; h2], {'PJVS', 'short'}, 'location', 'northwest');
        ylabel(ax(1), 'Cable error PJVS (uV/V)');
        ylabel(ax(2), 'Cable error short (uV/V)');
        xlabel('Time (s)');
        grid on
		title(sprintf('G_CE.m\nsimulated cable errors, PJVS cable length: %.3g m, short cable length: %.3g m', l_PJVS, l_short), 'interpreter', 'none');
        hold off

        % second figure - generated amplitudes and drift:
        figure
        hold on
        plot(t(:) - t(1), 1e6.*(A_source(:) - 1), 'kx-');
        plot(t(:) - t(1), 1e6.*(A_no_FR(:) - 1), 'rx-');
        plot(t(:) - t(1), 1e6.*(A(:) - 1), 'bx-');
        xlabel('Measurement time (s)');
        ylabel('Voltage error from nominal (uV)');
        title(sprintf('G_CE.m\nSimulated amplitudes including cable errors and source drift\nFirst reading at selected frequency is with short, second is with PJVS short'), 'interpreter', 'none');
        legend('Source voltage', 'Voltage at digitizer input', 'Voltage measured by digitizer');
        grid on
        hold off
    end
end % function G_CE

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
