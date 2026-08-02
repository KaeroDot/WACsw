% Simulates AC source amplitude errors due to frequency dependence, amplitude
% dependence, and drift in time. All properties are hard-coded. At 1 kHz and 1 V
% the error due to frequency dependence and amplitude dependence is zero.
%
% Inputs:
%   f_nominal   - Frequency vector (Hz)
%   A_nominal   - Nominal amplitude(s) of the AC source (V)
%   t           - Time vector of the readings (s), optional
%   t_one_reading - Time of one reading (s), used if t is empty
%
%   f_nominal and A_nominal can be either scalars, vectors or matrices. If one
%   of them is scalar, the value is repeated to match the size of the other.
%
% Outputs:
%   A                 - Simulated amplitude(s) with errors applied (V)
%   total_err_rel_ppm - Total relative amplitude error (uV/V).
%                       total_err_rel_ppm = 1e6.*(A/A_nominal - 1)
%   t                 - Time vector used (s)

function [A, total_err_rel_ppm, t] = AC_source_error_simulator(f_nominal, A_nominal, t, t_one_reading)
    % Constants %<<<1
    DEBUG = 0;
    % if these values are changed, update also the test!
    freq_scale = 10; % frequency dependence scale factor
    freq_offset = -30; % frequency dependence offset
    amp_scale = 0.1010101010100994; % amplitude dependence scale factor
    amp_offset = -0.1010101010101010; % amplitude dependence offset
    A_drift_rel_ppm = 0.1; % relative amplitude drift in uV/(V.s)

    % Check inputs %<<<1
    % Check either t or t_one_reading is given:
    if and(isempty(t), isempty(t_one_reading))
        error('AC_source_error_simulator: Either t or t_one_reading must be provided.');
    end
    % Check all frequencies are positive
    if any(f_nominal <= 0)
        error('AC_source_error_simulator: All input frequencies must be positive.');
    end
    % Check all amplitudes are positive
    if any(A_nominal <= 0)
        error('AC_source_error_simulator: All nominal amplitudes must be positive.');
    end
    % check sizes of f_nominal and A_nominal
    if and(numel(f_nominal) > 1, numel(A_nominal) > 1, numel(f_nominal) ~= numel(A_nominal))
        error('AC_source_error_simulator: f_nominal and A_nominal must have the same number of elements, or one of them must be a scalar.');
    end
    % check size of t if given is same as size of f_nominal or A_nominal whichever is larger
    if and( not(isempty(t)), numel(t) ~= max(numel(f_nominal), numel(A_nominal)) )
        error('AC_source_error_simulator: t must have the same number of elements as f_nominal or A_nominal, whichever is larger.');
    end

    % Frequency and amplitude dependence of AC source %<<<1
    % complete frequency and amplitude vectors if needed
    if and(numel(A_nominal) == 1, numel(f_nominal) > 1)
        A_nominal = A_nominal .* ones(size(f_nominal));
    elseif and(numel(f_nominal) == 1, numel(A_nominal) > 1)
        f_nominal = f_nominal .* ones(size(A_nominal));
    end
    % frequency dependence:
    % for 1 kHz no error, for 100 kHz 20 ppm error
    err_rel_ppm_freq = (freq_scale.*log10(f_nominal)+freq_offset);
    % amplitude dependence:
    % for 1 V no error, for 100 V 10 ppm error
    err_rel_ppm_amp = amp_offset + amp_scale.*A_nominal;

    % Amplitude drift %<<<1
    % create time vector if needed
    if isempty(t)
        % create time vector based on t_one_reading and number of frequencies:
        starttime = time();
        t = starttime + t_one_reading .* [1 : 1 : numel(f_nominal)] - t_one_reading;
        t = t(:);
    end
    % calculate relative amplitude drift:
    err_rel_ppm_drift = A_drift_rel_ppm .* (t - t(1));
    % add the drift to err_rel_ppm:
    err_rel_ppm_drift = reshape(err_rel_ppm_drift, size(f_nominal));
    % reshape t according to f_nominal/A_nominal size
    t = reshape(t, size(f_nominal));

    % Get absolute amplitudes %<<<1
    total_err_rel_ppm = err_rel_ppm_freq + err_rel_ppm_amp + err_rel_ppm_drift;
    A = A_nominal .* (1 + total_err_rel_ppm.*1e-6);

    if DEBUG %<<<1
        f_nominal
        A_nominal
        err_rel_ppm_freq
        err_rel_ppm_amp
        err_rel_ppm_drift
        total_err_rel_ppm
    end % if DEBUG
end % function AC_source_error_simulator

%!demo %<<<1
%! [XX, YY] = meshgrid(logspace(1,6,100), linspace(0.1,100,100));
%! [AA, total_err_rel_ppm] = AC_source_error_simulator(XX, YY, [], 0);
%! [c, h] = contourf(XX, YY, total_err_rel_ppm);
%! set(gca, 'xscale', 'log')
%! colorbar
%! xlabel('Nominal frequency (Hz)')
%! ylabel('Nominal amplitude (V)')
%! title('Total relative amplitude error (ppm)')

%tests %<<<1
%!shared A
% test inputs: f vector, A scalar, t empty:
%! [A, total_err_rel_ppm] = AC_source_error_simulator(repmat(1e3, 10, 1), 1, [], 0);
%!assert(numel(A), 10, 0);
% test inputs: f scalar, A vector, t empty:
%! [A, total_err_rel_ppm] = AC_source_error_simulator(1e3, repmat(1, 10, 1), [], 0);
%!assert(numel(A), 10, 0);
% test inputs: zero error for 1 kHz, 1 V:
%! [A, total_err_rel_ppm] = AC_source_error_simulator(1e3, 1, [], 0);
%!assert(A, 1, 1e-13);
% test inputs: 20 ppm error for 100 kHz, 1 V:
%! [A, total_err_rel_ppm] = AC_source_error_simulator(100e3, 1, [], 0);
%!assert(A, 1.000020, 1e-13);
% test inputs: 10 ppm error for 1 kHz, 100 V:
%! [A, total_err_rel_ppm] = AC_source_error_simulator(1e3, 100, [], 0);
%!assert(A, 100.0010, 1e-13);
% test inputs: drift, first element without drift:
%! [A, total_err_rel_ppm] = AC_source_error_simulator(repmat(1e3, 10, 1), 1, [0:0.1:0.9], 0);
%! A=A(1);
%!assert(A, 1, 1e-13);
% test inputs: drift 1 second, last element with 1 ppm drift
%! [A, total_err_rel_ppm] = AC_source_error_simulator(repmat(1e3, 101, 1), 1, [0:0.1:10], 0);
%! A=A(end);
%!assert(A, 1.000001, 1e-13);
% test inputs: drift 10 second, last element with 1 ppm drift, specifiied measurement time:
%! [A, total_err_rel_ppm] = AC_source_error_simulator(repmat(1e3, 101, 1), 1, [], 0.1);
%! A=A(end);
%!assert(A, 1.000001, 1e-13);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
