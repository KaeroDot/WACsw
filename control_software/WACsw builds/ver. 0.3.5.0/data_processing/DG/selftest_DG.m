% this script checks the measurement of digitizer gain error
clear all, close all

% Setup environment
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));

% simulation setup:

verbose = 0;

% prepare simulation parameters:
S_DG = struct();
S_DG.noise.v = 1e-8;
S_DG.dig_lin.v = [1+1e-6 0]; % 1 ppm error at 1 V

% Generate simulated DG measurement:
M_DG = G_DG(S_DG, verbose);

% Process simulated DG measurement:
[DG_fit] = P_DG(M_DG, verbose);

printf('Simulated digitizer gain error: %.3f ppm\n', (S_DG.dig_lin.v(1)-1)*1e6);
printf('Calculated digitizer gain error: %.3f ppm\n', (DG_fit.coefs.v(2)-1)*1e6);
printf('That is difference of %.3f ppm\n', ((DG_fit.coefs.v(2)-1) - (S_DG.dig_lin.v(1)-1))*1e6);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
