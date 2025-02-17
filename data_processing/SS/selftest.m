clear all, close all
addpath('../FR')
% simulation setup:

verbose = 0;
% first simulate FR:
% generate simulated measurement data:
[M_FR, simulated_digitizer_FR] = G_FR(verbose);
% process measurement:
[f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, verbose);

% M_SS = conditions_M_SS(check_gen_M_SS());
% M_SS = G_SS(M_SS, verbose);
M_SS = G_SS(2, verbose);

% add modification of samples according the FR of the digitizer.
% XXX This should go into selfstanding script
% Evaluate FR fit for fft frequencies:
% Build frequency vector (spacing is df=fs/N):
N = numel(M_SS.y.v);
% XXX suppose even number of samples!
f = M_SS.fs.v./N.*[0:N/2 - 1];
fitfreqs = piecewise_FR_evaluate(FR_fit, f, M_SS.fs);
% Construct the whole filter for both negative and positive frequencies:
% XXX is the filter correct?
% XXX what if numel(F) is odd number?!
fftfilter = [fitfreqs conj(fliplr(fitfreqs))];
% Calculate fft:
F = fft(M_SS.y.v);
% Apply filter:
F = F.*fftfilter;
% Calculate inverse fft
y_filtered = real(ifft(F));
M_SS.y.v = y_filtered;

[A_rms, A_fft] = P_SS(M_SS, FR_fit, verbose);
disp('---')
disp('selftest results:')
printf('Nominal amplitude (V): %.7f\n', M_SS.A_nominal.v)
printf('Calculated amplitude from RMS value (V): %.7f\n', A_rms)
printf('... error (uV): %.3f\n', 1e6.*(M_SS.A_nominal.v - A_rms))
printf('Calculated amplitude from FFT value (V): %.7f\n', A_fft)
printf('... error (uV): %.3f\n', 1e6.*(M_SS.A_nominal.v - A_fft))

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=octave textwidth=80 tabstop=4 shiftwidth=4

