% G_FF inputs
% f – calibrator frequencies (Hz), $N$ values.
% A – calibrator nominal amplitude (V), scalar.
% noise – simulation of calibrator + digitizer noise (V), scalar (frequency independent).
% digitizer amplitude error function (optional?)
% digitizer phase error function (optional?)
% ratio – value of $M/N$ (samples), scalar
% Unom – nominal voltage measured by voltmeter on ac–dc standard (V), scalar)
% ac–dc transfer function of the ac–dc standard (V/V), matrix with frequency vs voltage axis.
% G_FF outputs
% Data saved to a file according definition in P_FF data processing.

% function G_FF(); %f, A, noise, tf_dig_A, tf_dig_ph, ratio, Unom, tf_acdc)

    # sampling frequency: 4 MS/s
    fs = 4e6;

    % list of frequencies where transfer function was measured:
    f_real = linspace(1e3, 1.0e6, 1000);

    tf_dig_A = NI5922_tf_simulator(f_real, fs);


    

% load('data.txt')

