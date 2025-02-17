clear all; close all
addpath('../FR') % XXX move this script to new directory upwards, together with example data
% simulation setup:

verbose = 0;
% M_SS = check_gen_M_SS(); % XXX finish

% Load inputs %<<<1
% record:
load('example_data/example_record.mat')
% PJVS voltages:
pjvsdata = dlmread('example_data/example_pjvs_voltages.txt', sprintf('\t'));

% frequency response:
frdata = dlmread('example_data/example_digitizer_fr.txt');
% XXX add: set some proper measurement frequency,

% Frequency response processing %<<<1
% Example got already measured values, so no calculation is needed, only
% fitting.
M_FR.fs.v = 4e6; % sampling frequency, Sa/s
f.v = frdata(:, 1).*M_FR.fs.v; % to get real frequencies
err.v = frdata(:, 2)./1e6+1; % to convert errors in ppm to gain values in V/V
piecewise_fit = piecewise_FR_fit(f, err, M_FR, verbose);

% Subsampling processing %<<<1
% Set properties
% digitizer gain = 1.000152
% 40 periods Calibrator: 100 kHz, 1 V nom which is about 110 ppm low at 1 kHz
M_SS.fs.v = 4e6; % sampling frequency, Sa/s
M_SS.f.v = 100e3; % DUT signal frequency, Hz
M_SS.f_envelope.v = 20; % triangle waveform frequency, Hz
steps_in_period = 40;

M_SS.y.v = record; % samples
M_SS.t.v = 1/M_SS.fs.v.*[1 : numel(M_SS.y.v)] - 1/M_SS.fs.v; % time series
M_SS.f_step.v = steps_in_period.*M_SS.f_envelope.v; % frequency of PJVS steps
samples_in_step = M_SS.fs.v./M_SS.f_step.v; % samples in a single PJVS step
M_SS.Spjvs.v = [ 1 samples_in_step .* [1 : steps_in_period] numel(M_SS.y.v)+1 ]; % indexes of PJVS steps
M_SS.Rs.v = M_SS.fs.v/M_SS.f.v; % samples to remove after PJVS step change, multiple of 100 kHz waveform
M_SS.Re.v = M_SS.Rs.v; % samples to remove before PJVS step change, multiple of 100 kHz waveform
M_SS.Upjvs.v = pjvsdata(:, 2); % PJVS reference voltages

% Calculate %<<<1

if verbose
    plot(M_SS.t.v, M_SS.y.v);
end

[A_rms, A_fft] = P_SS(M_SS, piecewise_fit, verbose);
M_SS.A_nominal.v = sqrt(2); % nominal voltage set on DUT
disp('---')
printf('Nominal amplitude (V): %.7f\n', M_SS.A_nominal.v)
printf('Calculated mean amplitude from RMS value (V): %.7f\n', mean(A_rms))
printf('... error (uV): %.3f\n', 1e6.*(M_SS.A_nominal.v - mean(A_rms) ))
printf('Calculated amplitude from FFT value (V): %.7f\n', mean(A_fft) )
printf('... error (uV): %.3f\n', 1e6.*(M_SS.A_nominal.v - mean(A_fft) ))

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=octave textwidth=80 tabstop=4 shiftwidth=4
