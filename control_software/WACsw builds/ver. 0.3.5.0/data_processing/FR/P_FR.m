% -- [f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, acdc_corrections_path);
% -- [f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, acdc_corrections_path, verbose);
% Process data from measurement of digitizer frequency response. Calculate
% frequqency response from a measurement M_FR.
%
%    Inputs:
%      M_FR - structure with frequency response measurement.
%      acdc_corrections_path - file with AC/DC transfer standard data and corrections.
%      verbose - if nonzero, a figure with results will be plotted.
%
%      note: Path to the AC/DC file can be specified in
%      M_FR.acdc_corrections_path.v or as second input in
%      acdc_corrections_path. The latter is prioritized.
%
%    Outputs:
%      f - frequencies of measurement points (Hz)
%      digitizer_FR - frequency response of the digitizer (V/V)
%      ac_source_stability - stability of the AC source as measured by the thermal transfer element and voltmeter (V)
%      FR_fit - piecewise fit of the frequency response
%
%    Example:
%      (one should correct data in the measurement template before calculating the frequecy response!)
%      [f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(...
%           read_M_FR_from_spreadsheet('Example of FF meter template.xlsx'),...
%           'acdc_standard_data/dummy_acdc_standard/dummy_acdc.info', ...
%           1);

function [f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, acdc_corrections_path, verbose);

    % Check inputs %<<<1
    if not(isstruct(M_FR))
        error('P_FR: first input must be the M_FR structure!')
    end
    M_FR = check_gen_M_FR(M_FR); % ensure M_FR has all required fields
    if mod(numel(M_FR.f.v), 2)
        % count of frequencies is odd!
        error('P_FR: number of measurement points is odd, it should be even. M_FR.f.v must be a vector with even numbers!')
    end

    if ~exist('acdc_corrections_path', 'var')
        acdc_corrections_path = '';
    end
    if not(ischar(acdc_corrections_path))
        error('P_FR: second input must be empty, empty string or a string with path to the AC/DC transfer standard corrections file!')
    end

    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Get corrections for used AC/DC transfer standard %<<<1
    file_exists = [exist(M_FR.acdc_corrections_path.v, 'file'), exist(acdc_corrections_path, 'file')];
    if not(any(file_exists))
        error('P_FR: no AC/DC transfer standard corrections file specified or found! Please specify a valid file with corrections in M_FR.acdc_corrections_path.v or as second input argument acdc_corrections_path.')
    end
    if file_exists(2)
        % use path given in the argument, and rewrite/set value in M_FR:
        M_FR.acdc_corrections_path.v = acdc_corrections_path;
    end

    [acdc_difference ~] = get_ACDC_corrections(M_FR, verbose);

    % Reshape data %<<<1
    % Now samples are processed into M_FR.A.v and M_FR.A.u
    % check data are correct
    % suppose second measurement is reference frequency, and every even also reference
    % reshape measurement points
    % (first collumn will be measured frequency, second collumn will be reference frequency)
    f_meas = reshape(M_FR.f.v, 2, [])'; % signal frequencies
    tv = reshape(M_FR.t.v, 2, [])'; % time of reading
    Av = reshape(M_FR.A.v, 2, [])'; % amplitude as measured by digitizer
    Udc = reshape(M_FR.Udc.v, 2, [])'; % ACDC standard dc voltage output as as measured by voltmeter
    acdc_difference = reshape(acdc_difference, 2, [])'; % ACDC standard errors

    % Calculate results %<<<1
    % measured frequency response of the digitizer, calculated as:
    %   AC signal amplitude from digitizer at measured frequency /
    %   AC signal amplitude from digitizer at reference frequency
    %   *
    %   multimeter dc voltage at reference frequency /
    %   multimeter dc voltage at measured frequency
    %   *
    %   AC/DC error at measured frequency /
    %   AC/DC error at reference frequency
    digitizer_FR.v = Av(:, 1)./Av(:, 2) .* Udc(:, 2)./Udc(:, 1) .* (1 + acdc_difference(:, 1))./(1 + acdc_difference(:, 2));
    % freuencies of measurement points:
    f.v = f_meas(:,1);

    % stability of ac source as measured by thermal transfer element and voltmeter:
    ac_source_stability.v = Udc(:,2);

    % fit frequency response by a piecewise polynomial:
    % (value of regions set to nominal)
    FR_fit = piecewise_FR_fit(f, digitizer_FR, M_FR, verbose);

    % Export results %<<<1
    % create filename:
    [PATH, NAME, ~] = fileparts(M_FR.label.v);
    fn = fullfile(PATH, NAME);
    fn = [fn '_fit.mat'];
    save('-v7', fn, 'FR_fit');

    if verbose
        figure
        plot(f.v, digitizer_FR.v - 1, '-')
        xlabel('signal frequency (Hz)')
        ylabel('gain error (V/V)')
        title(sprintf('P_FR.m\nFrequency response of the digitizer `%s`', M_FR.digitizer_id.v), 'interpreter', 'none')

        % ac source stability
        figure
        plot((tv(:,1) - tv(1,1))./3600, ac_source_stability.v - ac_source_stability.v(1))
        xlabel('time from the first measurement (h)')
        ylabel('change of signal amplitude from the first reading (V)')
        title(sprintf('P_FR.m\nstability of AC source `%s`\n as measured by AC-DC standard and DC voltmeter `%s`', M_FR.ac_source_id.v, M_FR.dc_meter_id.v), 'interpreter', 'none')

		% % This figure is not usefull and probably nonsense
		% figure
		% semilogx(f_meas(:,1), Udc(:,1)./Udc(:,2) - 1)
		% xlabel('signal frequency (Hz)')
		% ylabel('error (V)')
		% title(sprintf('P_FR.m\nAC/DC error of `%s`\n(if amplitude of AC source is frequency independent)\n as measured by AC/DC standard and voltmeter `%s`', M_FR.ac_source_id.v, M_FR.dc_meter_id.v), 'interpreter', 'none')
    end

end % function P_FR

%!demo %<<<1
%! [f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(G_FR(), '', 1);
%! disp('-----------------------------------------------------------')
%! disp('Measurement of frequency response was be simulated.')
%! disp('Ideal AC/DC transfer standard was be used for corrections.')
%! disp('-----------------------------------------------------------')

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
