% Simulates the frequency response (transfer function) of the NI5922 digitizer
% using precomputed fit data based on calibration measurements.
%
% Inputs:
%   f          - Structure with field .v containing frequencies (Hz) to evaluate.
%                Frequencies outside valid range are set to NaN.
%   fs         - Structure with field .v containing sampling frequency (Hz).
%                Valid values: 50e3, 500e3, 4e6, 10e6, 15e6 Hz.
%   randomize  - (Optional) If nonzero, use Monte Carlo method to estimate uncertainty of gain values.
%                If set to Inf, use all available randomized data from
%                precomputed fit. If set to 0, do not randomize (use only the
%                mean fit).
%   verbose    - (Optional) Verbosity level for debugging. Default: 0 (silent).
%
% Outputs:
%   gain       - Transfer function gain values at input frequencies (structure with .v field).
%
% Example:
%   f.v = logspace(3, 6.6, 1000); fs.v = 10e6; 
%   gain = NI5922_FR_simulator(f, fs, Inf, 0);

function gain = NI5922_FR_simulator(f, fs, randomize, verbose)
    % Constants %<<<1
    % the only valid sampling frequencies for this simulator:
    valid_fs = [50e3, 500e3, 4e6, 10e6, 15e6];
    % maximum relative frequency covered by this simulator:
    max_f_rel = 0.41;
    % files with precomputed fit data for each valid sampling frequency:
    path_to_this_script = fileparts(mfilename('fullpath'));
    fit_data_files = {fullfile(path_to_this_script, 'data_for_FR_response/2026-02-24 K2182 GrdDisGnd digit ch2 50 kHz_fit.mat'), ...
                      fullfile(path_to_this_script, 'data_for_FR_response/2026-02-24 K2182 GrdDisGnd digit ch2 500 kHz_fit.mat'), ...
                      fullfile(path_to_this_script, 'data_for_FR_response/2026-02-24 K2182 GrdDisGnd digit ch2 4 MHz_fit.mat'), ...
                      fullfile(path_to_this_script, 'data_for_FR_response/2026-02-24 K2182 GrdDisGnd digit ch2 10 MHz_fit.mat'), ...
                      fullfile(path_to_this_script, 'data_for_FR_response/2026-02-24 K2182 GrdDisGnd digit ch2 15 MHz_fit.mat')...
                      };

    % Check inputs %<<<1
    % The randomize is only sent to piecewise_FR_evaluate, so we don't need to
    % check it fully here:
    if not(exist('randomize', 'var'))
        randomize = Inf;
    end
    if exist('verbose', 'var') && ~isempty(verbose)
        verbose = logical(verbose);
    else
        verbose = false;
    end

    % Intitialize %<<<1
    % frequencies below and above limits are set to NaN:
    f.v(f.v <= 0) = NaN;
    f.v(f.v > fs.v.*0.41) = NaN;

    % Load and use FR fit %<<<1
    persistent fr_fit_data = cell(size(valid_fs));

    % index of fit:
    fit_idx = find(valid_fs == fs.v, 1);
    if isempty(fr_fit_data{fit_idx})
        % load fit data if not already loaded:
        fr_fit_data{fit_idx} = load(fit_data_files{fit_idx});
    end
    % now generate gains with uncertainties:
    gain = piecewise_FR_evaluate(fr_fit_data{fit_idx}.FR_fit, f, fs, randomize);

end

% demo %<<<1
%!demo
%! % /---------------------------------------
%! % | Simulate frequency response for all available sampling frequencies and
%! % | plot the results.
%! % \---------------------------------------
%! fs_list = [50e3, 500e3, 4e6, 10e6, 15e6];
%! colors_list = {'k', 'r', 'g', 'b', 'm'};
%! figure; hold on;
%! for ii = 1:numel(fs_list)
%!     f.v = linspace(1e3, 0.4*fs_list(ii), 1e3);
%!     fs.v = fs_list(ii);
%!     gain = NI5922_FR_simulator(f, fs, 1e2, 0);
%!     plot(f.v./fs.v, 1e6.*(gain.v - 1), ['-' colors_list{ii}], 'displayname', sprintf('%.2f MHz', fs_list(ii)/1e6));
%!     plot(f.v./fs.v, 1e6.*(gain.v - 1) + 1e6.*gain.u, ['--' colors_list{ii}], 'handlevisibility', 'off');
%!     plot(f.v./fs.v, 1e6.*(gain.v - 1) - 1e6.*gain.u, ['--' colors_list{ii}], 'handlevisibility', 'off');
%! end
%! xlabel('Normalized Frequency f/fs');
%! ylabel('Gain - 1 (μV/V)');
%! title('NI5922 Simulated Transfer Functions for all available sampling frequencies');
%! legend();
%! grid('on');

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
