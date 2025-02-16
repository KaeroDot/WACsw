clear all, close all
% simulation setup:

verbose = 1;
M_SS = conditions_M_SS(M_SS);
M_SS = G_SS(M_SS, verbose);
[A_rms, A_fft] = P_SS(M_SS, verbose);
disp('---')
disp('selftest results:')
printf('Nominal amplitude (V): %.7f\n', M_SS.A_nominal.v)
printf('Calculated amplitude from RMS value (V): %.7f\n', A_rms)
printf('... error (uV): %.3f\n', 1e6.*(M_SS.A_nominal.v - A_rms))
printf('Calculated amplitude from FFT value (V): %.7f\n', A_fft)
printf('... error (uV): %.3f\n', 1e6.*(M_SS.A_nominal.v - A_fft))

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=octave textwidth=80 tabstop=4 shiftwidth=4

