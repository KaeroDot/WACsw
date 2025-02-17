% simulate subsampling measurement data
% Inputs:
%   empty
% OR
%   M_SS structure
%   [verbose]
% OR
%   predefined_values
%   [verbose]

function [M_SS] = G_SS(varargin);

    % Parse and check inputs %<<<1
    if nargin == 0
        predefined_values = 1;
        input1 = 1;
        verbose = 0;
    elseif nargin == 1
        input1 = varargin{1};
        verbose = 0;
    elseif nargin == 2
        input1 = varargin{1};
        verbose = varargin{2};
    else
        print_usage();
    end

    if isstruct(input1)
        M_SS = input1;
        predefined_values = 0;
    else
        if isempty(input1)
            error('G_SS: predefined values can be only 1, 2 or 3.')
        end
        predefined_values = input1(1);
        if not(any(predefined_values == [1 2 3]))
            error('G_SS: predefined values can be only 1, 2 or 3.')
        end
        M_SS = check_gen_M_SS();
    end

    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Nominal values %<<<1
    if predefined_values == 1
        % These values are working and produce simple plots:
        M_SS.f.v = 100;
        M_SS.A.v = 1;
        M_SS.ph.v = 0;
        M_SS.fs.v = 1e3;
        M_SS.f_envelope.v = 1;
        M_SS.A_envelope.v = M_SS.A.v;
        M_SS.ph_envelope.v = 0*pi;
        M_SS.f_step.v = 40*M_SS.f_envelope.v;
        M_SS.L.v = 1e3;
        M_SS.ph_step.v = 0.0314;
        M_SS.fm.v = 1e14;
        M_SS.waveformtype.v = 2;
        M_SS.Rs.v = 0;
        M_SS.Re.v = M_SS.Rs.v;
    elseif predefined_values == 2
        % These values are according Ralf Behr and Luis Palafox 2021 Metrologia 58 025010.
        % DUT signal frequency:
        M_SS.f.v = 100e3;
        % DUT signal amplitude:
        M_SS.A.v = 1;
        % DUT signal phase:
        M_SS.ph.v = 0;
        % sampling frequency (MS/s):
        M_SS.fs.v = 10e6;
        % PJVS envelope signal frequency (Hz):
        M_SS.f_envelope.v = 20;
        % PJVS envelope Amplitude (V):
        M_SS.A_envelope.v = 1;
        % PJVS envelope phase (rad):
        M_SS.ph_envelope.v = 0;
        % PJVS step change frequency (Hz):
        % (number of PJVS steps in a single envelope (Hz) is given by ratio
        % f_step/f_envelope)
        M_SS.f_step.v = 40.*M_SS.f_envelope.v;
        % Length of the record (samples):
        % one period of the PJVS signal
        M_SS.L.v = fix(1.*M_SS.fs.v./M_SS.f_envelope.v);
        % ph_step - phase of the PJVS steps (rad), scalar.
        M_SS.ph_step.v = 0;
        % fm - microwave frequency (Hz), scalar.
        M_SS.fm.v = 75e9;
        % waveformtype - 1: sine, 2: triangular, 3: sawtooth, 4: rectangular.
        M_SS.waveformtype.v = 2;
        % number of samples to be removed at start/end of PJVS step:
        M_SS.Rs.v = M_SS.fs.v./M_SS.f.v; % one period of the signal
        M_SS.Re.v = M_SS.Rs.v;
    elseif predefined_values == 3
        % testing values
        M_SS.f.v = 100;
        M_SS.A.v = 0.9;
        M_SS.ph.v = 0;
        M_SS.fs.v = 100e3;
        M_SS.f_envelope.v = 1;
        M_SS.A_envelope.v = M_SS.A.v;
        M_SS.ph_envelope.v = 0; %*pi;
        M_SS.f_step.v = 40*M_SS.f_envelope.v;
        M_SS.L.v = 1.*M_SS.fs.v./M_SS.f_envelope.v;
        M_SS.ph_step.v = 0;
        M_SS.fm.v = 75e9;
        M_SS.waveformtype.v = 2;
        M_SS.Rs.v = M_SS.fs.v./M_SS.f.v;
        M_SS.Re.v = M_SS.Rs.v;
    end

                    % % calculate condition according Ihlenfeld, ‘Investigations on extending the
                    % % frequency range of PJVS based AC voltage calibrations by coherent
                    % % subsampling’, in CPEM 2016, Ottawa, ON, Canada: IEEE, Jul. 2016, pp. 1–2.
                    % % doi: 10.1109/CPEM.2016.7539732:
                    % % f_n = f_J ( n*N + 1 ) => n = (f_n./f_J - 1)./N
                    % % where n must be integer (condition), f_n is frequency of DUT signal, N is number of pjvs steps, f_J is PJVS envelope frequency
                    % % f = f_envelope * (n * f_step./f_envelope + 1);
                    % n = (f./f_envelope - 1) ./ (f_step./f_envelope) ;
                    % if not(n == fix(n))
                    %     error('bad synchro') %XXX better description
                    % end

    % generate PJVS step function:
    % [y_pjvs, n, Upjvs, Upjvs1period, Spjvs, tsamples] = pjvs_wvfrm_generator2(fs, L, [], f_envelope, A_envelope, ph_envelope, f_step, ph_step, fm, waveformtype);
    [y_pjvs, n, M_SS.Upjvs.v, M_SS.Upjvs1period.v, M_SS.Spjvs.v, M_SS.t.v] = pjvs_triangle_generator(M_SS.fs.v, ...
        M_SS.L.v, ...
        [],
        M_SS.f_envelope.v, ...
        M_SS.A_envelope.v, ...
        [], ...
        M_SS.f_step.v, ...
        [], ...
        M_SS.fm.v, ...
        [], ...
        verbose);

    % DUT signal:
    y_dut = M_SS.A.v.*sin(2.*pi.*M_SS.f.v.*M_SS.t.v + M_SS.ph.v); % add offset XXX: + linspace(0, -1, numel(tsamples));
    % starts and ends properly XXX

    % digitized signal:
    M_SS.y.v = y_dut + y_pjvs;

    % Create output structure %<<<1
    % XXX put somewhere else?
    M_SS.A_nominal.v = round(M_SS.A.v.*100)./100;

    % Verbose info and figure %<<<1
	if verbose
        % print out some information
        disp('---')
        disp('G_SS verbose informations:')
        tmp = sqrt(mean(y_dut.^2)).*sqrt(2);
        printf('Maximum of DUT + PJVS waveform: %.7f\n', max(M_SS.y.v))
        printf('Minimum of DUT + PJVS waveform: %.7f\n', max(M_SS.y.v))
        printf('RMS of DUT waveform: %.7f\n', tmp)
        % Signal meant to be used for processing.
        % number of steps per one period of pjvs signal:
        steps_in_envelope = M_SS.f_step.v./M_SS.f_envelope.v;
        % votlage limit needed to cover whole signal by subsampling:
        limit = 2.*M_SS.A.v./steps_in_envelope; % XXX remove and use value from M_SS
        printf('Usefull +-limit to cover whole waveform: %.7f\n', limit)

        % overview plot
        % set samples above and below limit to NaN:
        idx = not(and(M_SS.y.v < limit, M_SS.y.v > -1.*limit));
        y_usefull = M_SS.y.v;
        y_usefull(idx) = NaN;
        % time as inverse of period of triangular pjvs waveform:
        % (only for this plot)
        tsamples_inv = M_SS.t.v.*M_SS.f_envelope.v;
		figure
		hold on
        plot(tsamples_inv, y_pjvs, 'g-');
        plot(tsamples_inv, y_dut, 'g-.');
        plot(tsamples_inv, M_SS.y.v, '+r');
        plot(tsamples_inv, y_usefull, 'kx');
        xl = xlim();
        yl = ylim();
        % plot usefull voltage limits
        plot(xl, [limit limit], 'k');
        plot(xl, -1.*[limit limit], 'k');
        % plot step changes
        for j = 1:numel(M_SS.Spjvs.v) - 1
            plot([tsamples_inv(M_SS.Spjvs.v(j)) tsamples_inv(M_SS.Spjvs.v(j))], yl, '--b')
        end % for j
        legend('PJVS', 'DUT signal', 'PJVS + DUT', 'usefull signal', 'limits for usefull signal')
        title(sprintf('G_SS.m\nf_meas/f_pjvs = %d\nlimit = %.4f', M_SS.f.v./M_SS.f_envelope.v, limit), 'interpreter', 'none')
        hold off
        xlabel('time (f_{envelope}^{-1})')
    end % if verbose

end % function [M_SS] = G_FR(verbose);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
