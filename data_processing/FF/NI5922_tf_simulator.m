% Very simple generator of a filter function of the National Instruments 5922
% digitizer. Works for frequencies above 0 and less than 0.41*fs. Works only
% for sampling frequencies 4, 10 and 15 MSa/s.
%
% Missing implementation: gain at DC is not equal for all sampling frequencies.
%
% Actual data for this script are saved in a file
% 'NI5922_filter_simulation_polynomial.mat', that has to be placed in the same
% directory as this script.
%
% Inputs:
%   f - list of frequencies where transfer function was measured (Hz)
%   fs - sampling frequency (Hz)
%
% Outputs:
%   gain - gain errors of the digitizer at the frequencies `f` for
%   sampling frequency `fs`, (V/V)
%
% Example:
%   NI5922_tf_simulator(logspace(1, 6.6, 1e4), 10e6, 1);

function gain = NI5922_tf_simulator(f, fs, verbose)
    % Check inputs %<<<1
    if ~isnumeric(f)
        error('NI5922_tf_simulator: input `f` must be a numeric vector.')
    end
    if ~isnumeric(fs)
        error('NI5922_tf_simulator: input `fs` must be a numeric vector.')
    end

    if not(or(fs == 4e6, fs == 10e6, fs == 15e6))
        error('NI5922_tf_simulator: only following sampling frequencies are supported: 4, 10, 15 MSa/s')
    end

    % frequencies below and above limits are set to NaN:
    f(f <= 0) = NaN;
    f(f > fs.*0.41) = NaN;

    if ~exist('verbose')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Constants %<<<1
    % initialize variables and polymonial data %<<<1
    % set values persistent for speed up:
    persistent fs4P
    persistent fs4S
    persistent fs4MU
    persistent fs10P
    persistent fs10S
    persistent fs10MU
    persistent fs15P
    persistent fs15S
    persistent fs15MU

    % test if data were already loaded (newly initialized persistent values are
    % empty):
    if isempty(fs4P)
        % construct path to the data file - same directory as this script:
        [DIR NAME EXT] = fileparts(mfilename('fullpath'));
        data_file = fullfile(DIR, 'NI5922_tf_simulator_polynomial_data.mat');
        load(data_file)
    end % if

    % find out polynomial parameters of actual transfer function:
    if fs == 4e6
        P = fs4P;
        S = fs4S;
        MU = fs4MU;
    elseif fs == 10e6
        P = fs10P;
        S = fs10S;
        MU = fs10MU;
    elseif fs == 15e6
        P = fs15P;
        S = fs15S;
        MU = fs15MU;
    end

    % Calculate tranfser function %<<<1
    % Polynomial works for frequencies relative to the sampling frequency:
    f_rel = f./fs;
    gain = 1 + polyval(P, f_rel, S, MU);

    % Verbose figure %<<<1
    if verbose
    figure
    % sorting needed for plotting with line, often inputs are unsorted frequencies
    [tmp1, idx] = sort(f);
    plot(tmp1, gain(idx) - 1, '-')
    xlabel('signal frequency (Hz)')
    ylabel('gain - 1 (V/V)')
    title('Simulated transfer function of a NI5922')
    end % if verbose
end

% demo %<<<1
%!demo
%! f_real4 = [1e3 : 1e3 : 1.64e6];
%! fs4 = 4e6;
%! gain4 = NI5922_tf_simulator(f_real4, fs4);
%! f_real10 = [1e3 : 1e3 : 4.1e6];
%! fs10 = 10e6;
%! gain10 = NI5922_tf_simulator(f_real10, fs10);
%! f_real15 = [1e3 : 1e3 : 6.14e6];
%! fs15 = 15e6;
%! gain15 = NI5922_tf_simulator(f_real15, fs15);
%! figure
%! plot(f_real4./fs4, 1e3.*(gain4 - 1), '-b', f_real10./fs10, 1e3.*(gain10 - 1), '-r', f_real15./fs15, 1e3.*(gain15 - 1), '-g')
%! legend('4 MSa/s', '10 MSa/s', '15 MSa/s')
%! xlabel('f/fs(Hz)')
%! ylabel('gain - 1 (mV/V)')
%! ylim([-20 30])
%! title('Simulated transfer functions of a NI5922')
