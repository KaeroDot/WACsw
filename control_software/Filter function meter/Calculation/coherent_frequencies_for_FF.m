% Function to generate almost linear list of coherent signal frequencies in the
% required range for a given sampling rate 'fs'. The list of signal frequencies will start
% at 'f_min', increase by 'f_step' and stop at 'f_max'. However the actual
% signal frequencies will be changed maximally by 'f_tolerance' to achieve the coherent
% sampling for set sampling frequency 'fs'. The target number of sampled periods
% is 'P', however the number of periods can be also changed maximally by 'P_tolerance' to
% achieve coherent sampling. The resolution of the signal generator
% 'generator_resolution' is taken into account when changing the frequencies.
% The output list will be interleaved by reqerence frequency 'f_reference'.
%
% Inputs (similar to linspace):
%   'fs': sampling frequency, Hz, required, positive real, default 15e6.
%   'f_min': minimum of the range of the frequencies, Hz, required, positive real, default 10e3.
%   'f_step': frequency step to generate list of frequencies, Hz, required, positive real, default 10e3.
%   'f_max': maximum of the range of the frequencies, Hz, required, positive real, default 7.5e6.
%   'P': expected number of periods to be sampled, periods, required, positive integer, default 1000.
%   'f_reference': reference frequency to be interleaved, Hz, required, positive real, default 1e3.
%   'generator_resolution': resolution of the signal generator in significant digitis of the frequency, digits, positive integer, default 4.
%   'f_tolerance': maximal relative change of the signal frequency to achieve coherency, Hz/Hz, real in range (0,1), default 0.01.
%   'P_tolerance': maximal absolute change of the number of sampled periods to achieve coherency, periods, positive integer, default 50.
%
%   If any input is empty matrix, or last inputs are ommited, default values are set.
%
% Outputs:
%   'Mo': two collumn matrix with coherent frequecies and coherent periods in collumns.
%
% Example:
% Mo = coherent_frequencies_for_FF(323e3, 125e3, 10e3, 150e3, 1000, 1e3, 4, 0.01, 10)
% Mo = 
%   125000  1000  <--- minimum frequency, 1000 periods
%     1000  1000  <--- reference frequency, 1000 periods
%   134900   994  <--- intermediate frequency, 994 periods
%     1000  1000  <--- reference frequency, 1000 periods
%   144500  1003  <--- maximum frequency, 1003 periods
%     1000  1000  <--- reference frequency, 1000 periods

function Mo = coherent_frequencies_for_FF(fs, f_min, f_step, f_max, P, f_reference, generator_resolution, f_tolerance, P_tolerance)
    %% Check inputs
    if ~exist('fs') fs = []; end
    if ~exist('f_min') f_min = []; end
    if ~exist('f_step') f_step = []; end
    if ~exist('f_max') f_max = []; end
    if ~exist('P') P = []; end
    if ~exist('f_reference') f_reference = []; end
    if ~exist('generator_resolution') generator_resolution = []; end
    if ~exist('f_tolerance') f_tolerance = []; end
    if ~exist('P_tolerance') P_tolerance = []; end

    if isempty(fs) fs = 15e6; end
    if isempty(f_min) f_min = 10e3; end
    if isempty(f_step) f_step = 10e3; end
    if isempty(f_max) f_max = 7.5e6; end
    if isempty(P) P = 1000; end
    if isempty(f_reference) f_reference = 1e3; end
    if isempty(generator_resolution) generator_resolution = 4; end
    if isempty(f_tolerance) f_tolerance = 0.05; end
    if isempty(P_tolerance) P_tolerance = 50; end

    %% Validate inputs
    if or(fs <= 0, f_min <= 0, f_step <= 0, f_max <= 0, f_reference <= 0)
        error('coherent_frequencies_for_FF: All frequency inputs must be greater than zero.');
    end
    if f_min >= f_max
        error('coherent_frequencies_for_FF: Minimum of the frequency range (f_min) must be smaller than maximum (f_max).');
    end
    if f_step >= f_max - f_min
        error('coherent_frequencies_for_FF: Frequency step (f_step) must be smaller than frequency range (f_max - f_min).');
    end
    if or(f_min > fs, f_step > fs, f_max > fs, f_reference > fs)
        error('coherent_frequencies_for_FF: Sampling frequency must be greater than other frequency inputs.');
    end
    if P < 1
        error('coherent_frequencies_for_FF: Expected number of periods (P) must be at least 1.');
    end
    if fix(P) ~= P
        error('coherent_frequencies_for_FF: Expected number of periods (P) must be integer.');
    end
    if generator_resolution < 2
        error('coherent_frequencies_for_FF: Generator resolution (generator_resolution) must be at least 2 significant digits.');
    end
    if fix(generator_resolution) ~= generator_resolution
        error('coherent_frequencies_for_FF: Generator resolution (generator_resolution) must be integer.');
    end
    if f_tolerance <= 0 || f_tolerance >= 1
        error('coherent_frequencies_for_FF: Frequency tolerance (f_tolerance) must be between 0 and 1.');
    end
    if or(P_tolerance < 0, fix(P_tolerance) ~= P_tolerance)
        error('coherent_frequencies_for_FF: Period tolerance (P_tolerance) must be positive integer.');
    end

    %% Generate coherent measurement frequencies (Hz)
    f_proposed = f_min : f_step : f_max;
    % Process each proposed frequency to find its coherent equivalent
    % Initialize arrays:
    f_selected = []; % Matrix with coherent frequencies near the proposed ones.
    P_selected = []; % Matrix with coherent periods near the required ones.
    for j = 1:numel(f_proposed)
        [f_selected(end+1), P_selected(end+1)] = find_coherent(fs, f_proposed(j), P, generator_resolution, f_tolerance, P_tolerance);
    end

    %% Find coherent frequency and period for the reference frequency
    [f_reference, P_reference] = find_coherent(fs, f_reference, P, generator_resolution, f_tolerance, P_tolerance);

    %% Create output
    % Interleave the reference frequency across all selected frequencies
    % create list:
    fi = f_reference .* ones(size(f_selected)); % Reference frequencies
    Pi = P_reference .* ones(size(f_selected)); % Reference periods

    % Create a whole list of frequencies: alternating selected and reference frequencies
    lf = [f_selected(:), fi(:)];
    % Create a list of periods: alternating selected and reference periods
    lP = [P_selected(:), Pi(:)];
    % Combine frequencies and periods into a single matrix
    Mo = [lf'(:), lP'(:)];

    % Write the results to a CSV file
    csvwrite('Mo.csv', Mo);
end

function [f_selected, P_selected] = find_coherent(fs, f_required, P, generator_resolution, f_tolerance, P_tolerance)
    % Function to find a coherent frequency and corresponding number of periods
    % that satisfy the sampling constraints.
    % Inputs:
    %   'fs': sampling frequency (Hz)
    %   'f_required': expected signal frequency (Hz)
    %   'P': expected number of periods to be sampled
    %   'generator_resolution': resolution of the signal generator in significant digitis of the frequency
    %   'f_tolerance': maximal relative change of the signal frequency to achieve coherency
    %   'P_tolerance': maximal relative change of the number of sampled periods to achieve coherency

    % Check coherency of inputs:
    S = P .* fs ./ f_required;
    if fix(S) == S
        % Input already coherent, nothing to do here.
        f_selected = f_required;
        P_selected = P;
    else
        % Input is not coherent, must search one.
        % Tuning parameters for periods
        P_step = 1; % Step size for period adjustments

        % Determine the range of candidate periods
        P_min = P - P_tolerance;
        P_min = max(1, P_min); % Ensure number of minimum periods is at least one
        P_max = P + P_tolerance;
        P_max = max(2, P_max); % Ensure number of maximum periods is at least two
        P_candidate = P_min:P_step:P_max;

        % Determine the step size for frequency adjustment based on resolution
        magnitude = 10^floor(log10(f_required)); % Magnitude of the required frequency
        f_step = magnitude / 10^(generator_resolution - 1); % Frequency step size

        % Define the range of candidate frequencies
        % (f_tolerance is relative number)
        % absolute tolerance (Hz) as multiple of f_step:
        f_tolerance_abs = fix(f_tolerance * f_required / f_step) * f_step;
        f_min = f_required - f_tolerance_abs;
        f_max = f_required + f_tolerance_abs;
        f_candidate = f_min:f_step:f_max;

        % Create a grid of candidate frequencies and periods
        [f_grid, P_grid] = meshgrid(f_candidate, P_candidate);

        % Check coherency
        S = P_grid .* fs ./ f_grid;
        coherent = fix(S) == S; % Logical matrix for coherent combinations

        % If any coherent combination is found, select the nearest one
        if any(any(coherent))
            % Find the row and column indices of the nearest coherent point
            [idr, idc] = findNearestOne(coherent);
            % Extract the corresponding frequency and period
            f_selected = f_grid(idr, idc);
            P_selected = P_grid(idr, idc);
        else
            % Error if no coherent frequency is found
            error(['Cannot find coherent frequency for required f = ', ...
                   num2str(f_required), ' Hz and fs = ', num2str(fs), ' Hz.']);
        end % any(any(coherent))
    end % if fix(S) == S
end

function [nearest_row, nearest_col] = findNearestOne(matrix)
    % Helper function to find the location of the element with value 1
    % that is nearest to the center of a given matrix.
    % Is used to find coherent frequency/period combination that is nearest to
    % the expected one.
    % Inputs:
    %   matrix: Input logical matrix (zeros and ones)

    % Get the dimensions of the matrix
    [rows, cols] = size(matrix);

    % Compute the center of the matrix
    center_row = (rows + 1) / 2;
    center_col = (cols + 1) / 2;

    % Find the positions of all ones in the matrix
    [one_rows, one_cols] = find(matrix == 1);

    % Calculate the Euclidean distance of each one to the center
    distances = sqrt((one_rows - center_row).^2 + (one_cols - center_col).^2);

    % Find the index of the minimum distance
    [~, idx] = min(distances);

    % Return the row and column indices of the nearest one
    nearest_row = one_rows(idx);
    nearest_col = one_cols(idx);
end
