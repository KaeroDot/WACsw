% -- [M_FR, digitizer_FR] = G_FR()
% Generates simulated measurement of NI5922 frequency response.
%
%    Inputs:
%      verbose - if nonzero, a figure be plotted.
%
%    Outputs:
%      M_FR - structure with frequency response measurement.
%	   simulated_digitizer_FR - frequency response of simulated digitizer.
%
%    Example:
%      M_FR = G_FR(1);

function [M_FR, simulated_digitizer_FR] = G_FR(verbose); %f, A, noise, tf_dig_A, tf_dig_ph, ratio, Unom, tf_acdc)

    % inputs XXX 2DO really ?

    % Check inputs %<<<1
    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Constants %<<<1
    # sampling frequency (MS/s):
    fs = 4e6;
    % reference/basic signal frequency (Hz):
    f_basic = 1e4;
	% ac source total change of voltage from the beginning to the end of
	% measurement (V): % (drif is calculated from total time of measurement)
    ac_change = -30e-6;
    % period between two readings (s):
    t_one_reading = 10;
    % nominal source voltage (V):
    ac_source_A_nominal = 0.5;

    % Make measurement %<<<1
    % list of frequencies where transfer function was measured:
    f_real = linspace(1e1, 1.0e6, 10000);
    f_real = linspace(1e4, 1e6, 1e2); % XXX
    % measurement was interleaved by 'basic' frequency for AC-AC method:
    f_real = [f_real(:)'; f_basic.*ones(size(f_real(:)'))];
    f_real = f_real(:);

    % times of readings:
    starttime = time();
    t = starttime + t_one_reading .* [1 : 1 : numel(f_real)] - t_one_reading;
    t = t(:);

    % amplitude of the source - time dependent linear drift that starts at nominal amplitude:
    % (no frequency dependence of ac source!)
    % ac source drift in V/s:
    ac_drift = ac_change./(numel(t).*t_one_reading);
    Asource = ac_source_A_nominal + ac_drift .* (t - t(1));
    if any(Asource <= 0)
        error('G_FF: amplitude of the AC source decreased to zero % during the simulated measurement due to the source drift!')
    end

    % get output of AC/DC standard:
    [acdc_difference dc_voltage] = ACDC_simulator(f_real);

    % voltage measured by digitizer:
    simulated_digitizer_FR.v = NI5922_FR_simulator(f_real, fs);
    Adigitizer = Asource .* simulated_digitizer_FR.v;

    % voltage measured by dc voltmeter:
    Udc = Asource .* dc_voltage;

    % Create output structure %<<<1
    M_FR = check_gen_M_FR();
    % Generate measurement data structure:
    M_FR.A_nominal.v = ac_source_A_nominal;
    M_FR.fs.v = fs;
    M_FR.ac_dc_settle_time.v = '0';
    M_FR.ac_dc_warm_up_time.v = '0';
    M_FR.dc_readings.v = 10;
    M_FR.alg_id.v = 'TWM-WRMS';
    M_FR.ac_source_id.v = 'simulated_AC_source';
    M_FR.dc_meter_id.v = 'simulated_DC_meter';
    M_FR.digitizer_id.v = 'simulated_digitizer';
    M_FR.f.v = f_real;
    M_FR.M.v = f_real; % multiples of periods in record - same number of periods as the frequency
    M_FR.t.v = t;
    M_FR.A.v = Adigitizer;
    M_FR.A.u = 1e-6.*ones(size(f_real)); % digitizer amplitude XXX
    M_FR.Udc.v = Udc;
    M_FR.Udc.u = 1e-6.*ones(size(M_FR.Udc.v)); % dc readings uncertainties - for now just some number! XXX
    M_FR.Udc.r = repmat(M_FR.Udc.v, 1, M_FR.dc_readings.v); % dc readings - readings XXX move readings outside .r, that should be randomized values?
    M_FR.y.v = []; %XXX 2DO here generate the samples! Maybe this will not be needed. This can be very large! 20 GB of data! Or maybe better path to files!

    % Verbose figure %<<<1
	if verbose
		figure
		hold on
		plot(1/3600.*(M_FR.t.v - M_FR.t.v(1)), Asource    - Asource(1)   , '-b')
		plot(1/3600.*(M_FR.t.v - M_FR.t.v(1)), dc_voltage - dc_voltage(1), '-k')
		plot(1/3600.*(M_FR.t.v - M_FR.t.v(1)), M_FR.Udc.v - M_FR.Udc.v(1), '-r')
		xlabel('t (h)')
		ylabel('voltage minus offset at beginning (V)')
		legend('amplitude of drifting ac source', 'th. trans. standard dc voltage as simulated by AC/DC simulator',  'final dc voltage of th. transf. standard with drift of the ac source')
		title(sprintf('G_FR.m\nproperties of ac voltage source `%s`', M_FR.ac_source_id.v), 'interpreter', 'none')
		hold off
	end

end % function G_FF

%!demo %<<<1
%! G_FR(1);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
