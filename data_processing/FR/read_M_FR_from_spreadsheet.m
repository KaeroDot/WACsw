% -- M_FR = read_M_FR_from_spreadsheet(filename)
%    Reads measurement of a digitizer frequency response from a spreadsheet template.
%
%    Inputs:
%    	filename - path and name of a spreadsheet file
%    Outputs:
%      M_FR - structure with measurement data. Structure is defined in function 'check_gen_M_FR.m'.
%
%    Example:
%      M_FR = read_M_FR_from_spreadsheet('my_measurement_data.xls')

function M_FR = read_M_FR_from_spreadsheet(filename)
    % Constants %<<<1
    % constants of cell positions indexes:
    idx_A_nominal           = [2, 5]; % row, collumn
    idx_fs                  = [3, 5];
    idx_ac_dc_settle_time   = [4, 5];
    idx_ac_dc_warm_up_time  = [5, 5];
    idx_dc_readings         = [6, 5];
    idx_alg_id              = [7, 5];
    idx_ac_source_id        = [2, 8];
    idx_dc_meter_id         = [3, 8];
    idx_digitizer_id        = [4, 8];
    idx_f                   = [11,  2, 10000,    2]; % start row, start collumn, end row, end collumn
    idx_M                   = [11,  3, 10000,    3];
    idx_t                   = [11,  4, 10000,    4];
    idx_A_v                 = [11,  5, 10000,    5];
    idx_A_u                 = [11,  6, 10000,    6];
    idx_Udc_v               = [11,  7, 10000,    7];
    idx_Udc_u               = [11,  8, 10000,    8];
    idx_Udc_r               = [11, 11, 10000, 1000];

    % Read and extract data %<<<1
    % read excell file and extract data
    [An, Tn, Ra, limits] = xlsread(filename);

    % parse data
    M_FR.A_nominal.v            = num2str(Ra{idx_A_nominal(1), idx_A_nominal(2)});
    M_FR.fs.v                   = num2str(Ra{idx_fs(1), idx_fs(2)});
    M_FR.ac_dc_settle_time.v    = num2str(Ra{idx_ac_dc_settle_time(1), idx_ac_dc_settle_time(2)});
    M_FR.ac_dc_warm_up_time.v   = num2str(Ra{idx_ac_dc_warm_up_time(1), idx_ac_dc_warm_up_time(2)});
    M_FR.dc_readings.v          = num2str(Ra{idx_dc_readings(1), idx_dc_readings(2)});
    M_FR.alg_id.v               =         Ra{idx_alg_id(1), idx_alg_id(2)};
    M_FR.ac_source_id.v         =         Ra{idx_ac_source_id(1), idx_ac_source_id(2)};
    M_FR.dc_meter_id.v          =         Ra{idx_dc_meter_id(1), idx_dc_meter_id(2)};
    M_FR.digitizer_id.v         =         Ra{idx_digitizer_id(1), idx_digitizer_id(2)};

    M_FR.f.v = shift_limits_get_matrix(idx_f, limits, An);
    M_FR.M.v = shift_limits_get_matrix(idx_M, limits, An);
    M_FR.t.v = shift_limits_get_matrix(idx_t, limits, An);
    M_FR.A.v = shift_limits_get_matrix(idx_A_v, limits, An);
    M_FR.A.u = shift_limits_get_matrix(idx_A_u, limits, An);
    M_FR.Udc.v = shift_limits_get_matrix(idx_Udc_v, limits, An);
    M_FR.Udc.u = shift_limits_get_matrix(idx_Udc_u, limits, An);
    M_FR.Udc.r = shift_limits_get_matrix(idx_Udc_r, limits, An);

    % Properly convert excell time to octave time %<<<1
    % I want to use time as number of seconds from 1.1.1970 (unix time).
    % xlsread returns time as days from 0/0/1900 (non-existing date -
    % Excell stupid format).
    t_delta = datenum(1900,01,00,0,0,0); % that is 693961
    M_FR.t.v = M_FR.t.v + t_delta;
    for j = 1:numel(M_FR.t.v)
        if ~isnan(M_FR.t.v(j))
            tmp = datestr(M_FR.t.v(j), 31);
            tmp2 = strptime(tmp, '%Y-%m-%d %H:%M:%S');
            M_FR.t.v(j) = mktime(tmp2);
        end
    end

    % check data and remove possible nans? XXX %<<<1
    % XXX
end % function read_M_FR_from_spreadsheet(filename)

function res = shift_limits_get_matrix(idx, limits, An) %<<<1
	% Function 'xlsread' returns numeric matrix trimmed around. So if first
	% number in spreadsheet is at position 5,7, xlsread will cut 4 rows and 7 collums
	% so An(1,1) is equal to str(Ra(5,7)). This subfunction fixes the issue.

    idxold = idx;
    idx(1) =      idx(1) - limits.numlimits(1, 1) + 1;
    idx(2) =      idx(2) - limits.numlimits(2, 1) + 1;
    idx(3) = min( idx(3) - limits.numlimits(1, 1) + 1, size(An, 1) );
    idx(4) = min( idx(4) - limits.numlimits(2, 1) + 1, size(An, 2) );
    res = An( idx(1) : idx(3), idx(2) : idx(4) );
end % function shift_limits_get_matrix

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
