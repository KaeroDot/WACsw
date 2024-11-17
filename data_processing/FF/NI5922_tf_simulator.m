% Feature-way generation of filter function of the National Instruments
% 5922 digitizer. Just generate some transfer function looking slightly
% similar.
% (The best would be using symbolic variables, however the symbolic package
% got python dependency, and I do not want to add this dependent ency
% because of auxiliary script.)
% Script needs sort of regular spacing, otherwise the transfer function is very distorted.
%
% Inputs:
%   f_real - list of frequencies where transfer function was measured (Hz)
%   fs - sampling frequency (Hz)
% Outputs:
%   tf_dig_A - gain errors of the digitizer at the f_real frequencies, (V/V)

% XXX add if frequencies does not cover whole range from almost 0 to 0.4*fs.

function tf_dig_A = NI5922_tf_simulator(f_real, fs)
    % frequencies relative to the sampling frequency:
    f_rel = f_real./fs;

    % simulate sine like properties of the real transfer function:
    tf_dig_A = 1e-3.*sin(2*pi*15*f_rel + pi/2);

    % simulate positive slope of the real transfer function:
    slope = 2e-3*[1 : 1 : numel(tf_dig_A)]./numel(tf_dig_A);
    tf_dig_A = tf_dig_A + slope;

    % simulate left and right side of the real transfer function by creating a window
    window_x = linspace(0, 1, numel(f_rel))
    plot(window_x)
    keyboard
    % right hand side of the window - fast fall:
    window_rh = 1 + 3.*( -1.*window_x.^11 );
    % left hand side of the window - rise from 0 to 1:
    window_lh = 1 + ( -1.*window_x.^3 );
    window_lh = window_lh(end:-1:1);
    % combine both sides:
    window = window_lh .* window_rh;

    % apply window to the transfer function:
    tf_dig_A = tf_dig_A.*window;

    % debug plot - plot transfer function in ppm:
    plot(f_rel, tf_dig_A.*1e6, 'x');
    xlabel('frequency relative to sampling freq. (Hz/Hz)')
    ylabel('relative error of the digitizer (uV/V)')
end
