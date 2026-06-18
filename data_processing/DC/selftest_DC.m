clear all, close all

% Setup environment
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'check_and_set_environment.m'));

% simulation setup:

verbose = 1;
% Generate simulated DC measurement:
M_CE = G_DC(FR_fit, S_CE, verbose);

% Process simulated DC measurement:
[CE_fit] = P_DC(M_CE, verbose);

% evaluate simulation
% TODO
