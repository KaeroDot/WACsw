% this script checks the measurement of digitizer gain error
clear all, close all

% Setup environment
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));

% simulation setup:

verbose = 0;

% prepare simulation parameters:
S_DC = struct();
S_DC.noise.v = 1e-8;
S_DC.dig_lin.v = [1+1e-6 0]; % 1 ppm error at 1 V

% Generate simulated DC measurement:
M_DC = G_DC(S_DC, verbose);

% Process simulated DC measurement:
[DC_fit] = P_DC(M_DC, verbose);

printf('Simulated digitizer gain error: %.3f ppm\n', (S_DC.dig_lin.v(1)-1)*1e6);
printf('Calculated digitizer gain error: %.3f ppm\n', (DC_fit.coefs.v(2)-1)*1e6);
printf('That is difference of %.3f ppm\n', ((DC_fit.coefs.v(2)-1) - (S_DC.dig_lin.v(1)-1))*1e6);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
