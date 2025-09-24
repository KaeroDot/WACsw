% simulate cable error measurement data
% Inputs:
%   empty
% OR
%   M_CE structure
%   [verbose]
% OR
%   predefined_values
%   [verbose]
%
% predefined_values can take 1, 2, 3
%   1: to produce simple plots
%   2: according Ralf Behr and Luis Palafox 2021 Metrologia 58 025010
%   3: values for testing

function [M_CE] = G_CE(varargin);

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
        M_CE = input1;
        predefined_values = 0;
    else
        if isempty(input1)
            error('G_CE: predefined values can be only 1, 2 or 3.')
        end
        predefined_values = input1(1);
        if not(any(predefined_values == [1 2 3]))
            error('G_CE: predefined values can be only 1, 2 or 3.')
        end
        M_CE = check_gen_M_CE();
    end

    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Nominal values %<<<1
    if predefined_values == 1
        % These values produce very simple plots:
        error('TODO')
    elseif predefined_values == 2
        % THIS IS NONSENSE:
        % % These values are according Ralf Behr and Luis Palafox 2021 Metrologia 58 025010.
        %    % length of the cable to the shorted PJVS (m):
        %    l_PJVS = 5.2;
        %    % length of the cable to the short (m):
        %    l_short = 0.4;
        % % DUT signal frequencies (Hz):
        % f_signal = linspace(50, 100e3, 10);
        % % Measured amplitude with cable to the short - simply suppose no attenuations or reflections:
        % As = ones(size(f_signal));
        % % Measured amplitude with cable to the PVJS - calculate according the paper:
        %    % systematic error accoding the paper:
        %    % Error = 285e-6*(f/100e3)^2*(l_short/l_PJVS)^2
        %    % Error = (Ac/As - 1)*(f/100e3)^2*(l_short/l_PJVS)^2
        %    % thus amplitude of second measurement must be:
        %    % Error = (Ac/As - 1)*(f/100e3)^2*(l_short/l_PJVS)^2
        %    % Ac = As * (1 + Error / ((f / 100e3)^2 * (l_short / l_PJVS)^2))
        % Ac = As .* (1 + 285e-6./((f_signal./100e3).^2 .* (l_short ./ l_PJVS).^2));
    elseif predefined_values == 3
        % Testing values - error at 100 kHz is 1000 ppm, and pure quadratic
        % dependence on the frequency.
        % DUT signal frequencies (Hz):
        f_signal = linspace(50, 100e3, 10);
        % Measured amplitude with cable to the short - simply suppose no
        % attenuations or reflections. As nominal ampplitude is 1 V, then
        % measured amplitude with short is 1 V:
        Anom = 1; % V
        As = Anom.*ones(size(f_signal));
        % Measured amplitude with cable to the PJVS:
        Ac = As.*(1 + 1000e-6.*((f_signal./100e3).^2));

        % Multiply measured data by inverse frequency response of the digitizer
        % Sampling frequency of the digitizer:
        fs = 4e6; % Hz
        % to simulate measurement by a real digitizer:
        simulated_digitizer_FR.v = NI5922_FR_simulator(f_signal, fs);
        As = As .* simulated_digitizer_FR.v;
        Ac = Ac .* simulated_digitizer_FR.v;
        % add offset 10 uV to the measurements:
        As = As + 10e-6; % V
        Ac = Ac + 10e-6; % V
    end

    % Set output structure %<<<1
    % TODO what if input is M_CE?
    M_CE.A_nominal.v = Anom;
    M_CE.alg_id.v = 'TWM-WRMS';
    M_CE.ac_source_id.v = 'simulated_AC_source';
    M_CE.digitizer_id.v = 'simulated_digitizer';
    M_CE.f.v = f_signal;
    M_CE.M.v = f_signal; % multiples of periods in record - same number of periods as the frequency
    M_CE.t.v = 739836 + [0:1:numel(M_CE.f.v)].*2; % e.g. every measurement takes 2 seconds
    M_CE.Ac.v = Ac;
    M_CE.Ac.u = 1e-6;
    M_CE.As.v = As;
    M_CE.As.u = 1e-6;
    M_CE.FR_fit.v = ''; % TODO FIXME XXX
    M_CE.fs.v = 15e6;

    % verbose output %<<<1
    if verbose
        % print out some information
        disp('---')
        disp('G_CE verbose informations:')
        printf('Measurement span: %g Hz - %g Hz\n', min(M_CE.f.v), max(M_CE.f.v));
        printf('Ratio As/Ac at last measuremnet point: %6.6g\n', M_CE.Ac.v(end)/M_CE.As.v(end));

        % overview plot
        figure
        hold on
        plot(M_CE.f.v, (M_CE.Ac.v./M_CE.As.v - 1)*1e6, 'b-');
        plot(M_CE.f.v, (M_CE.Ac.v - 1)*1e6, 'r-');
        plot(M_CE.f.v, (M_CE.As.v - 1)*1e6, 'g-');
        xlabel('time (s)')
        xlabel('cable error (uV/V)')
        legend('error', 'Ac - amplitude with lon_cable->PJVS', 'As - short_cable->short')
        title(sprintf('G_CE.m\nratio of amplitudes long_cable->PJVS to short_cable->short\nerror calculated as (Ac/As - 1)*1e6'))
        hold off
    end % if verbose

end % function G_CE

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
