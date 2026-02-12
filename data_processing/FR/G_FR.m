% -- [M_FR, digitizer_FR] = G_FR(S_FR, verbose)
% Generates simulated measurement of NI5922 frequency response.
%
%    Inputs:
%      S_FR - structure with simulation parameters and errors. If empty or not provided,
%             default values will be used. Fields (all as Q.v and Q.u substructures):
%               .fs.v             - sampling frequency (Hz), default: 4e6
%               .f_basic.v        - reference/basic signal frequency (Hz), default: 1e4
%               .ac_change.v      - AC source total voltage change from beginning to end (V), default: -30e-6
%               .t_one_reading.v  - period between two readings (s), default: 10
%               .ac_source_A_nominal.v - nominal source voltage (V), default: 0.5
%               .f_points.v       - number of frequency points in measurement, default: 100
%               .FR_slope.v       - slope error of frequency response (unitless), default: 0
%               .A_uncertainty.v  - digitizer amplitude uncertainty (V), default: 1e-6
%               .Udc_uncertainty.v - DC readings uncertainty (V), default: 1e-6
%               .dc_readings.v    - number of DC readings, default: 10
%               .no_fit_regions.v - number of regions for fitting of the FR, default: 20
%      verbose - if nonzero, a figure will be plotted. Default: 0
%
%    Outputs:
%      M_FR - structure with frequency response measurement.
%      simulated_digitizer_FR - frequency response of simulated digitizer.
%
%    Example:
%      M_FR = G_FR([], 1);
%      S_FR.FR_slope.v = 1e-6; M_FR = G_FR(S_FR, 1);

function [M_FR, simulated_digitizer_FR] = G_FR(S_FR, verbose);

    % Check inputs %<<<1
    if ~exist('S_FR', 'var')
        S_FR = struct();
    end
    if isempty(S_FR)
        S_FR = struct();
    end
    if not(isstruct(S_FR))
        error('G_FR: S_FR must be a structure!')
    end
    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = false;
    else
        verbose = logical(verbose(1));
    end

    % Set default simulation parameters %<<<1
    % sampling frequency (Hz):
    if ~isfield(S_FR, 'fs') || ~isfield(S_FR.fs, 'v') || isempty(S_FR.fs.v)
        S_FR.fs.v = 4e6;
    end
    % reference/basic signal frequency (Hz):
    if ~isfield(S_FR, 'f_basic') || ~isfield(S_FR.f_basic, 'v') || isempty(S_FR.f_basic.v)
        S_FR.f_basic.v = 1e4;
    end
    % ac source total change of voltage from the beginning to the end of
    % measurement (V): (drift is calculated from total time of measurement)
    if ~isfield(S_FR, 'ac_change') || ~isfield(S_FR.ac_change, 'v') || isempty(S_FR.ac_change.v)
        S_FR.ac_change.v = -30e-6;
    end
    % period between two readings (s):
    if ~isfield(S_FR, 't_one_reading') || ~isfield(S_FR.t_one_reading, 'v') || isempty(S_FR.t_one_reading.v)
        S_FR.t_one_reading.v = 10;
    end
    % nominal source voltage (V):
    if ~isfield(S_FR, 'ac_source_A_nominal') || ~isfield(S_FR.ac_source_A_nominal, 'v') || isempty(S_FR.ac_source_A_nominal.v)
        S_FR.ac_source_A_nominal.v = 0.5;
    end
    % number of frequency points:
    if ~isfield(S_FR, 'f_points') || ~isfield(S_FR.f_points, 'v') || isempty(S_FR.f_points.v)
        S_FR.f_points.v = 100;
    end
    % slope error of frequency response:
    if ~isfield(S_FR, 'FR_slope') || ~isfield(S_FR.FR_slope, 'v') || isempty(S_FR.FR_slope.v)
        S_FR.FR_slope.v = 0;
    end
    % digitizer amplitude uncertainty (V):
    if ~isfield(S_FR, 'A_uncertainty') || ~isfield(S_FR.A_uncertainty, 'v') || isempty(S_FR.A_uncertainty.v)
        S_FR.A_uncertainty.v = 1e-6;
    end
    % DC readings uncertainty (V):
    if ~isfield(S_FR, 'Udc_uncertainty') || ~isfield(S_FR.Udc_uncertainty, 'v') || isempty(S_FR.Udc_uncertainty.v)
        S_FR.Udc_uncertainty.v = 1e-6;
    end
    % number of DC readings:
    if ~isfield(S_FR, 'dc_readings') || ~isfield(S_FR.dc_readings, 'v') || isempty(S_FR.dc_readings.v)
        S_FR.dc_readings.v = 10;
    end
    % number of regions for fitting of the FR:
    if ~isfield(S_FR, 'no_fit_regions') || ~isfield(S_FR.no_fit_regions, 'v') || isempty(S_FR.no_fit_regions.v)
        S_FR.no_fit_regions.v = 20;
    end

    % Make measurement %<<<1
    % list of frequencies where transfer function was measured:
    f_real.v = linspace(1e4, 1e6, S_FR.f_points.v);
    % measurement was interleaved by 'basic' frequency for AC-AC method:
    f_real.v = [f_real.v(:)'; S_FR.f_basic.v.*ones(size(f_real.v(:)'))];
    f_real.v = f_real.v(:);

    % times of readings:
    starttime.v = time();
    t.v = starttime.v + S_FR.t_one_reading.v .* [1 : 1 : numel(f_real.v)] - S_FR.t_one_reading.v;
    t.v = t.v(:);

    % amplitude of the source - time dependent linear drift that starts at nominal amplitude:
    % (no frequency dependence of ac source!)
    % ac source drift in V/s:
    ac_drift.v = S_FR.ac_change.v./(numel(t.v).*S_FR.t_one_reading.v);
    A_source.v = S_FR.ac_source_A_nominal.v + ac_drift.v .* (t.v - t.v(1));
    if any(A_source.v <= 0)
        error('G_FF: amplitude of the AC source decreased to zero during the simulated measurement due to the source drift!')
    end

    % get output of AC/DC standard:
    [acdc_difference dc_voltage.v acdc_corrections_path] = ACDC_simulator(f_real.v);

    % voltage measured by digitizer:
    simulated_digitizer_FR.v = NI5922_FR_simulator(f_real.v, S_FR.fs.v);
    % apply slope error to the frequency response:
    simulated_digitizer_FR.v = (1 + S_FR.FR_slope.v.*f_real.v).*simulated_digitizer_FR.v;
    A_digitizer.v = A_source.v .* simulated_digitizer_FR.v;
    % TODO should be properly randomized
    A_digitizer.u = S_FR.A_uncertainty.v .* ones(size(A_digitizer.v));

    % voltage measured by dc voltmeter:
    Udc.v = A_source.v .* dc_voltage.v;
    % uncertainties TODO should be properly randomized
    Udc.u = S_FR.Udc_uncertainty.v.*ones(size(Udc.v));
    % readings TODO XXX move readings outside .r, that should be randomized values?
    Udc.r = repmat(Udc.v, 1, S_FR.dc_readings.v);

    % Create output structure %<<<1
    M_FR = check_gen_M_FR();
    % Generate measurement data structure:
    M_FR.A_nominal.v = S_FR.ac_source_A_nominal.v;
    M_FR.fs.v = S_FR.fs.v;
    M_FR.acdc_settle_time.v = '0';
    M_FR.acdc_warm_up_time.v = '0';
    M_FR.dc_readings.v = 10;
    M_FR.alg_id.v = 'TWM-WRMS';
    M_FR.ac_source_id.v = 'simulated_AC_source';
    M_FR.dc_meter_id.v = 'simulated_DC_meter';
    M_FR.digitizer_id.v = 'simulated_digitizer';
    M_FR.f.v = f_real.v;
    M_FR.M.v = f_real.v; % multiples of periods in record - same number of periods as the frequency
    M_FR.t = t;
    M_FR.A = A_digitizer;
    M_FR.Udc = Udc;
    M_FR.acdc_corrections_path.v = acdc_corrections_path; % path to the file with corrections of the AC/DC transfer standard
    M_FR.y.v = []; %XXX 2DO here generate the samples! Maybe this will not be needed. This can be very large! 20 GB of data! Or maybe better path to files!
    M_FR.label.v = 'simulated_FR_measurement';
    M_FR.no_fit_regions.v = S_FR.no_fit_regions.v;

    % Verbose figure %<<<1
	if verbose
		figure
		hold on
		plot(1/3600.*(M_FR.t.v - M_FR.t.v(1)), A_source.v    - A_source.v(1)   , '-b')
		plot(1/3600.*(M_FR.t.v - M_FR.t.v(1)), dc_voltage.v - dc_voltage.v(1), '-k')
		plot(1/3600.*(M_FR.t.v - M_FR.t.v(1)), M_FR.Udc.v - M_FR.Udc.v(1), '-r')
		xlabel('t (h)')
		ylabel('voltage minus offset at beginning (V)')
		legend('amplitude of drifting ac source', 'th. trans. standard dc voltage as simulated by AC/DC simulator',  'final dc voltage of th. transf. standard with drift of the ac source')
		title(sprintf('G_FR.m\nproperties of ac voltage source `%s`', M_FR.ac_source_id.v), 'interpreter', 'none')
		hold off
	end

end % function G_FR

%!demo %<<<1
%! G_FR([], 1);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
