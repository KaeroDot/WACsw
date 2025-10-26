% simulate cable error measurement data
%   Inputs:
%     FR_fit - frequency response fit structure (from P_FR)
%     verbose - if nonzero, a figure be plotted.
%
%   Outputs:
%     M_CE - structure with cable error measurement.
%     simulated_CE - TODO

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
    % nominal amplitude:
    A_nominal = 1; % V
    % sampling frequency (MS/s):
    fs.v = 4e6;
	% ac source total change of voltage from the beginning to the end of
	% measurement (V): % (drif is calculated from total time of measurement)
    ac_change = -30e-6;
    % period between two readings (s):
    t_one_reading = 10;

    % Make measurement %<<<1
    % generate cable errors for both short and PJVS:
    err_rel_PJVS = cable_error(f_signal, l_PJVS);
    err_rel_short = cable_error(f_signal, l_short);
    % times of readings (two readings per signal frequency):
    starttime = time();
    t = starttime + t_one_reading .* [1 : 1 : 2.*numel(f_signal)] - t_one_reading;
    t = t(:);
    % get relative error from FR fit to simulate measurement by a real digitizer:
    FR_err_rel = piecewise_FR_evaluate(FR_fit, f_signal, fs);
    % amplitude of the source - time dependent linear drift that starts at nominal amplitude:
    % (no frequency dependence of ac source!)
    % ac source drift in V/s:
    ac_drift = ac_change./(numel(t).*t_one_reading);
    A_source = A_nominal + ac_drift .* (t - t(1));

    err_rel_no_FR = [err_rel_short(:), err_rel_PJVS(:)];
    err_rel_no_FR = err_rel_no_FR'(:);
    A_no_FR = A_source .* err_rel_no_FR;

    err_rel = [FR_err_rel(:) .* err_rel_short(:), FR_err_rel(:) .* err_rel_PJVS(:)];
    err_rel = err_rel'(:);
    A = A_source .* err_rel;

    % Set output structure %<<<1
    M_CE.A_nominal.v = A_nominal;
    M_CE.fs = fs;
    M_CE.alg_id.v = 'TWM-WRMS';
    M_CE.ac_source_id.v = 'simulated_AC_source';
    M_CE.digitizer_id.v = 'simulated_digitizer';
    M_CE.f.v = [f_signal(:), f_signal(:)]'(:);
    M_CE.M.v = f_signal; % multiples of periods in record - same number of periods as the frequency
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
		title(sprintf('G_CE.m\ncable errors, PJVS cable length: %.3g m, short cable length: %.3g m', l_PJVS, l_short), 'interpreter', 'none');
        hold off

        % second figure - generated amplitudes and drift:
        figure
        hold on
        plot(t - t(1), 1e6.*(A_source - 1), 'r.-');
        plot(t - t(1), 1e6.*(A_no_FR - 1), 'r.-');
        plot(t - t(1), 1e6.*(A - 1), 'b.-');
        xlabel('Time (s)');
        ylabel('Voltage error from nominal (uV)');
        title('G_CE.m\nGenerated amplitudes at digitizer input including cable errors and source drift', 'interpreter', 'none');
        legend('Source voltage', 'Voltage at digitizer input', 'Voltage measured by digitizer');
        grid on
        hold off
    end


    %    % THIS IS NONSENSE:
    %    % % These values are according Ralf Behr and Luis Palafox 2021 Metrologia 58 025010.
    %    %    % length of the cable to the shorted PJVS (m):
    %    %    l_PJVS = 5.2;
    %    %    % length of the cable to the short (m):
    %    %    l_short = 0.4;
    %    % % DUT signal frequencies (Hz):
    %    % f_signal = linspace(50, 100e3, 10);
    %    % % Measured amplitude with cable to the short - simply suppose no attenuations or reflections:
    %    % As = ones(size(f_signal));
    %    % % Measured amplitude with cable to the PVJS - calculate according the paper:
    %    %    % systematic error accoding the paper:
    %    %    % Error = 285e-6*(f/100e3)^2*(l_short/l_PJVS)^2
    %    %    % Error = (Ac/As - 1)*(f/100e3)^2*(l_short/l_PJVS)^2
    %    %    % thus amplitude of second measurement must be:
    %    %    % Error = (Ac/As - 1)*(f/100e3)^2*(l_short/l_PJVS)^2
    %    %    % Ac = As * (1 + Error / ((f / 100e3)^2 * (l_short / l_PJVS)^2))
    %    % Ac = As .* (1 + 285e-6./((f_signal./100e3).^2 .* (l_short ./ l_PJVS).^2));
    %elseif predefined_values == 3
    %    % Testing values - error at 100 kHz is 1000 ppm, and pure quadratic
    %    % dependence on the frequency.
    %    % DUT signal frequencies (Hz):
    %    f_signal = linspace(50, 100e3, 10);
    %    % Measured amplitude with cable to the short - simply suppose no
    %    % attenuations or reflections. As nominal ampplitude is 1 V, then
    %    % measured amplitude with short is 1 V:
    %    Anom = 1; % V
    %    As = Anom.*ones(size(f_signal));
    %    % Measured amplitude with cable to the PJVS:
    %    Ac = As.*(1 + 1000e-6.*((f_signal./100e3).^2));
    %    % Multiply measured data by inverse frequency response of the digitizer
    %    % Sampling frequency of the digitizer:
    %    fs = 4e6; % Hz
    %    % to simulate measurement by a real digitizer:
    %    simulated_digitizer_FR.v = NI5922_FR_simulator(f_signal, fs);
    %    As = As .* simulated_digitizer_FR.v;
    %    Ac = Ac .* simulated_digitizer_FR.v;
    %    % add offset 10 uV to the measurements:
    %    As = As + 10e-6; % V
    %    Ac = Ac + 10e-6; % V
    %end
end % function G_CE

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
