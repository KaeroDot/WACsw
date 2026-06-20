clear all, close all

% Setup environment
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));

% simulation setup:

verbose = 3;

% Generate digitizer linearity calibration:
M_DG = G_DG([], 0);
DG_fit = P_DG(M_DG, 0);
% TODO modify all digitizer measurements by DG_fit! Maybe it is not so critical for ratio of CE or ratio of FR.

% Generate simulated FR measurement and process it:
% (no verbose because only SS is relevant here)
[M_FR, simulated_digitizer_FR] = G_FR([], 0);
[f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', 0);

% Generate simulated CE measurement before SS and process it:
% (no verbose because only SS is relevant here)
            M_CE(1) = G_CE(FR_fit, [], 0);
% generate single point CE calibration:
S_CE.f_signal.v = 100e3;
% M_CE(1) = G_CE(FR_fit, S_CE, 0);
[CE_fit(1)] = P_CE(M_CE(1), 0);

% Generate simulated subsampling measurement:
% M_SS = conditions_M_SS(check_gen_M_SS());
% Use set of prefefined values no. 2:
M_SS = G_SS(2, verbose);
% Generate simulated CE measurements after SS and process it:
% XXX here should come time development of the AC source thus M_CE(2) is not identical!
            M_CE(2) = G_CE(FR_fit, [], 0);
% generate single point CE calibration:
% M_CE(2) = G_CE(FR_fit, S_CE, 0);
[CE_fit(2)] = P_CE(M_CE(2), 0);
% apply both CE fits (before and after SS) by combining them:
CE_fit_int = CE_fits_interpolate(CE_fit);

% TODO here should come DG_fit input and apply also linearity correction?
y_filtered = apply_CE_FR_on_samples(M_SS, FR_fit, CE_fit_int, 1, verbose);
M_SS.y.v = y_filtered;

% Process simulated subsampling measurement:
[A_rms, A_fft] = P_SS(M_SS, FR_fit, CE_fit_int, verbose);
disp('SS selftest results:')
% printf('Nominal amplitude (V): %.7f\n')
printf('Calculated amplitude from RMS value (V): %.7f\n', A_rms)
printf('... error (uV): %.3f\n', 1e6.*(M_SS.A_nominal.v - A_rms))
printf('Calculated amplitude from FFT value (V): %.7f\n', A_fft)
printf('... error (uV): %.3f\n', 1e6.*(M_SS.A_nominal.v - A_fft))

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
