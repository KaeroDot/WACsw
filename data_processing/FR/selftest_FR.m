% this script checks the frequency response measurement
clear all; close all

addpath('acdc')
addpath('info')

verbose = 1;
% generate simulated measurement data:
[M_FR, simulated_digitizer_FR] = G_FR(verbose);
% process measurement:
[f, measured_digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, '', verbose);

plot(M_FR.f.v, simulated_digitizer_FR.v - 1, '.b', f.v, measured_digitizer_FR.v - 1, '-r')
title(sprintf('selftest.m\nsimulated and measured frequency response of the digitizer'))
legend('simulated FR', 'measured FR')
xlabel('signal frequency (Hz)')
ylabel('gain error ()')
