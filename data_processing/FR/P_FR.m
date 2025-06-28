% -- [digitizer_fr f_tf] = P_FR(M_FR) % XXX fix according definition
% -- [digitizer_fr f_tf] = P_FR(M_FR, verbose)
% Process data from measurement of digitizer frequency response. Calculate
% frequqency response from a measurement M_FR. %
%    Inputs:
%      M_FR - structure with frequency response measurement.
%      verbose - if nonzero, a figure with results will be plotted.
%
%    Outputs:
%      acdc_difference - AC/DC difference of the SJTC (V/V)
%      dc_voltage - DC output of the SJTC (V)
%
%    Example:
%      [f digitizer_FR] = P_FR(read_M_FR_from_spreadsheet('my_measurement_data.xls'), 1)

function [f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, verbose);

    % Check inputs %<<<1
    if not(isstruct(M_FR))
        error('P_FR: first input must be a structure!')
    end
    if mod(numel(M_FR.f.v), 2)
        % count of frequencies is odd!
        error('P_FR: number of measurement points is odd, it should be even. M_FR.f.v must be a vector with even numbers!')
    end

    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));


                            % XXX use elsewere!
                            % if ischar(input1)
                            %     % suppose it is file name to the excel file. Read the file
                            %     if ~exist(input1, 'file')
                            %         error('P_FR: first input was a string, so it should be a path to an excell file, however the file does not exist!')
                            %     end
                            %     % read spreadsheet to get measurement structure
                            %     M_FR = read_measurement_from_spreadsheet(input1);
                            % elseif isstruct(input1)
                            %     % it is already structure with data.
                            %     M_FR = input1;
                            % end


    % find out if amplitudes exists or have to be calculated:
    % if M_FR.A.v ... M_FR.A.u
        % XXX

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

    % fix XXX move it outside. Add properties of acdcsimulator to M_FF?
    % get calibration values of the ACDC standard (ac dc errors):
    [acdc_differenceL dc_voltage(:, 1)] = ACDC_simulator(f_meas(:, 1));
    [acdc_differenceR dc_voltage(:, 2)] = ACDC_simulator(f_meas(:, 2));

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
    digitizer_FR.v = Av(:, 1)./Av(:, 2) .* Udc(:, 2)./Udc(:, 1) .* dc_voltage(:, 1)./dc_voltage(:, 2);
    % freuencies of measurement points:
    f.v = f_meas(:,1);

    % stability of ac source as measured by thermal transfer element and voltmeter:
    ac_source_stability.v = Udc(:,2);

    % fit frequency response by a piecewise polynomial:
    FR_fit = piecewise_FR_fit(f, digitizer_FR, M_FR, verbose);

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
%! [f digitizer_FR] = P_FR(G_FR());
%! plot(f.v, digitizer_FR.v)

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
