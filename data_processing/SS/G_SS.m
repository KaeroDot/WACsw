% simulate subsampling measurement data

function [M_SS] = G_SS(verbose);

    % inputs XXX 2DO really ?

    % Check inputs %<<<1
    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Nominal values %<<<1
    f = 10;
    A = 1;
    ph = 0;
    fs = 1e3;
    f_envelope = 1;
    A_envelope = A;
    ph_envelope = 0.5*pi; % if phase incorrect, rms does not work!
    fstep = 10*f_envelope;
    L = 1000*fs;  % for limited, this works only for value 1, not for 0.5 or 5 or 10!XXX
    phstep = 0.0314;
    fm = 1e14;
    waveformtype = 2;
                % THIS SEEMS CORRECT, after testing return to these values:
                % % Nominal values are according Ralf Behr and Luis Palafox 2021 Metrologia 58 025010.
                % % DUT signal frequency:
                % f = 100e3;
                % % DUT signal amplitude:
                % A = 1;
                % % DUT signal phase:
                % ph = 0;
                % % sampling frequency (MS/s):
                % fs = 10e6;
                % % PJVS envelope signal frequency (Hz):
                % f_envelope = 1e3;
                % % PJVS envelope Amplitude (V):
                % A_envelope = 1;
                % % PJVS envelope phase (rad):
                % ph_envelope = 0;
                % % PJVS step change frequency (Hz):
                % % (number of PJVS steps in a single envelope (Hz) is given by ratio
                % % fstep/f_envelope)
                % fstep = 40e3;
                % % Length of the record (samples):
                % % one period of the PJVS signal
                % L = fix(1.*fs./f_envelope);
                % % phstep - phase of the PJVS steps (rad), scalar.
                % phstep = 0;%pi + 0.012566;
                % % fm - microwave frequency (Hz), scalar.
                % fm = 75e9;
                % % waveformtype - 1: sine, 2: triangular, 3: sawtooth, 4: rectangular.
                % waveformtype = 2;

    % generate PJVS step function:
    [y_pjvs, n, Upjvs, Upjvs1period, Spjvs, tsamples] = pjvs_wvfrm_generator2(fs, L, [], f_envelope, A_envelope, ph_envelope, fstep, phstep, fm, waveformtype);

    % DUT signal:
    y_dut = A.*sin(2.*pi.*f.*tsamples + ph); % add offset XXX: + linspace(0, -1, numel(tsamples));
    % starts and ends properly XXX

    % digitized signal:
    y = y_dut + y_pjvs;

    % Create output structure %<<<1
    M_SS = check_gen_M_SS();
    % Generate measurement data structure:
    M_SS.fs.v = fs;
    M_SS.y.v = y;
    M_SS.t.v = tsamples;
    M_SS.Upjvs.v = Upjvs;
    M_SS.Upjvs1period.v = Upjvs1period;
    M_SS.Spjvs.v = Spjvs;
    M_SS.f.v = f;
    M_SS.f_envelope.v = f_envelope;
    M_SS.f_step.v = fstep;

    % Verbose info and figure %<<<1
	if verbose
        % print out some information
        disp('---')
        disp('G_SS verbose informations:')
        tmp = sqrt(mean(y_dut.^2)).*sqrt(2);
        printf('Maximum of DUT + PJVS waveform: %.7f\n', max(y))
        printf('Minimum of DUT + PJVS waveform: %.7f\n', max(y))
        printf('RMS of DUT waveform: %.7f\n', tmp)
        % Signal meant to be used for processing.
        % number of steps per one period of pjvs signal:
        steps_in_envelope = fstep./f_envelope;
        % votlage limit needed to cover whole signal by subsampling:
        limit = 2.*A./steps_in_envelope;
        printf('Usefull +-limit to cover whole waveform: %.7f\n', limit)

        % overview plot
        % set samples above and below limit to NaN:
        idx = not(and(y < limit, y > -1.*limit));
        y_usefull = y;
        y_usefull(idx) = NaN;
        % time as inverse of period of triangular pjvs waveform:
        % (only for plot)
        tsamples_inv = tsamples.*f_envelope;
		figure
		hold on
        plot(tsamples, y_pjvs, 'g-');
        plot(tsamples, y_dut, 'g-.');
        plot(tsamples_inv, y, '+r');
        plot(tsamples_inv, y_usefull, 'kx');
        xl = xlim();
        yl = ylim();
        % plot usefull voltage limits
        plot(xl, [limit limit], 'k');
        plot(xl, -1.*[limit limit], 'k');
        % plot step changes
        for j = 1:numel(Spjvs) - 1
            plot([tsamples_inv(Spjvs(j)) tsamples_inv(Spjvs(j))], yl, '--b')
        end % for j
        legend('PJVS', 'DUT signal', 'PJVS + DUT', 'usefull signal', 'limits for usefull signal')
        title(sprintf('G_SS.m\nf_meas/f_pjvs = %d\nlimit = %.4f', f./f_envelope, limit), 'interpreter', 'none')
        hold off
        xlabel('time (f_{envelope}^{-1})')
    end % if verbose

end % function [M_SS] = G_FR(verbose);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
