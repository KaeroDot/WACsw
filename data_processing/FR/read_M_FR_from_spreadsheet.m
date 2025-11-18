% -- M_FR = read_M_FR_from_spreadsheet(filename, verbose)
%     Reads measurement of a digitizer frequency response from a spreadsheet 
%     template defined in `Example of FF meter template.xlsx`.
%     Inputs:
%      filename - path and name of a spreadsheet file
%      verbose - if nonzero, verbose output is printed
%     Outputs:
%      M_FR - structure with measurement data. Structure is defined in function 'check_gen_M_FR.m'.
%
%     Example:
%      M_FR = read_M_FR_from_spreadsheet('Example of FF meter template.xlsx')

function M_FR = read_M_FR_from_spreadsheet(filename, verbose)
    % Check inputs %<<<1
    if ~exist('verbose', 'var')
        verbose = 0;
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Constants %<<<1
    % constants of cell positions indexes:
    % Define cell positions for extracting specific data from the spreadsheet
    % This must be compatible with 'Example of FF meter template.xlsx'!
    % (Values are range ordered as: [row_start, collumn_start, row_end, collumn_end].
    % Counting from 1 - as every normal person does.)
    idx_A_nominal           = [2, 5, 2, 5]; % Nominal amplitude
    idx_fs                  = [3, 5, 3, 5]; % Sampling frequency
    idx_acdc_settle_time   = [4, 5, 4, 5]; % AC/DC settle time
    idx_acdc_warm_up_time  = [5, 5, 5, 5]; % AC/DC warm-up time
    idx_dc_readings         = [6, 5, 6, 5]; % DC readings
    idx_alg_id              = [7, 5, 7, 5]; % Algorithm ID
    idx_simultaneous_meas   = [8, 5, 8, 5]; % Simultaneous measurement?
    idx_ac_source_id        = [2, 8, 2, 8]; % AC source ID
    idx_dc_meter_id         = [3, 8, 3, 8]; % DC meter ID
    idx_digitizer_id        = [4, 8, 4, 8]; % Digitizer ID
    idx_f                   = [14,  2, 2000,    2]; % Frequency range %TODO bad description
    idx_M                   = [14,  3, 2000,    3]; % Measurement data %TODO bad description
    idx_t                   = [14,  4, 2000,    4]; % Time data %TODO bad description
    idx_A_v                 = [14,  5, 2000,    5]; % Amplitude values
    idx_A_u                 = [14,  6, 2000,    6]; % Amplitude uncertainties
    idx_Udc_v               = [14,  7, 2000,    7]; % DC voltage mean values
    idx_Udc_u               = [14,  8, 2000,    8]; % DC voltage uncertainties
    idx_Udc_r               = [14, 11, 2000, 1000]; % DC voltage readings

    % Read and extract data %<<<1
    % Read the Excel file and extract numeric and raw data
    [An, Tn, Ra, limits] = xlsread(filename);

    % Get row offset of measured data:
    data_row_offset = idx_f(1) - limits.numlimits(1,1) + 1;
    % Parse data and populate the M_FR structure
    M_FR.A_nominal.v            = shift_limits_get_matrix(idx_A_nominal,          limits.numlimits, An)(:);
    M_FR.fs.v                   = shift_limits_get_matrix(idx_fs,                 limits.numlimits, An)(:);
    M_FR.acdc_settle_time.v    = shift_limits_get_matrix(idx_acdc_settle_time,  limits.numlimits, An)(:);
    M_FR.acdc_warm_up_time.v   = shift_limits_get_matrix(idx_acdc_warm_up_time, limits.numlimits, An)(:);
    M_FR.dc_readings.v          = shift_limits_get_matrix(idx_dc_readings,        limits.numlimits, An)(:);
    M_FR.alg_id.v               = shift_limits_get_matrix(idx_alg_id,             limits.txtlimits, Ra){1};
    M_FR.simultaneous_meas.v    = shift_limits_get_matrix(idx_simultaneous_meas,  limits.numlimits, An)(:);
    M_FR.simultaneous_meas.v    = ~(~(M_FR.simultaneous_meas.v)); % ensure logical
    M_FR.ac_source_id.v         = shift_limits_get_matrix(idx_ac_source_id,       limits.txtlimits, Ra){1};
    M_FR.dc_meter_id.v          = shift_limits_get_matrix(idx_dc_meter_id,        limits.txtlimits, Ra){1};
    M_FR.digitizer_id.v         = shift_limits_get_matrix(idx_digitizer_id,       limits.txtlimits, Ra){1};

    % Extract matrix data for frequency, measurements, time, etc.
    M_FR.f.v   = shift_limits_get_matrix(idx_f,     limits.numlimits, An)(:);
    M_FR.M.v   = shift_limits_get_matrix(idx_M,     limits.numlimits, An)(:);
    M_FR.t.v   = shift_limits_get_matrix(idx_t,     limits.numlimits, An)(:);
    M_FR.A.v   = shift_limits_get_matrix(idx_A_v,   limits.numlimits, An)(:);
    M_FR.A.u   = shift_limits_get_matrix(idx_A_u,   limits.numlimits, An)(:);
    M_FR.Udc.v = shift_limits_get_matrix(idx_Udc_v, limits.numlimits, An)(:);
    M_FR.Udc.u = shift_limits_get_matrix(idx_Udc_u, limits.numlimits, An)(:);
    M_FR.Udc.r = shift_limits_get_matrix(idx_Udc_r, limits.numlimits, An);

    % Properly convert excell time to octave time %<<<1
    % Convert time from Excel's format (days since 0/0/1900) to Unix time
    % (seconds since 1/1/1970) (this date does not exist - Excell stupid
    % format)
    t_delta = datenum(1900,01,00,0,0,0); % Offset for Excel time, that is 693961
    M_FR.t.v = M_FR.t.v + t_delta;
    for j = 1:numel(M_FR.t.v)
        if ~isnan(M_FR.t.v(j))
            tmp = datestr(M_FR.t.v(j), 31);
            tmp2 = strptime(tmp, '%Y-%m-%d %H:%M:%S');
            M_FR.t.v(j) = mktime(tmp2);
        end
    end

    % Validate data for type, NaNs, and empty values %<<<1
    % Define expected field types
    mandatory_fields = {'fs', 'f', 'M', 't', 'A', 'Udc'};
    % Ensure mandatory fields in M_FR are properly validated
    for i = 1:numel(mandatory_fields)
        data = M_FR.(mandatory_fields{i}).v;
        % Check for empty data
        if isempty(data)
            error('read_M_FR_from_spreadsheet: Quantity `%s.v` is empty. The spreadsheet is probably not according expected template.', mandatory_fields{i});
        end
        if ~isnumeric(data)
            error('read_M_FR_from_spreadsheet: Quantity `%s.v` should be numeric but is not. The spreadsheet is probably not according expected template.', mandatory_fields{i});
        end
    end

    % Remove rows with NaNs in any of f, M, t, A, Udc %<<<1
    % Find rows with NaNs
    nan_rows = any([...
                    isnan(M_FR.f.v) ...
                    isnan(M_FR.M.v) ...
                    isnan(M_FR.t.v) ...
                    isnan(M_FR.A.v) ...
                    isnan(M_FR.Udc.v) ...
                    ], 2);
    % Remove rows with NaNs
    rows_to_remove = find(nan_rows);
    also_remove = [];
    for j = 1:numel(rows_to_remove)
        % if odd row is marked to be removed...
        if rem(rows_to_remove(j), 2)
            % remove also row after:
            also_remove(end+1) = rows_to_remove(j) + 1;
        else
            % if even, remove also previous row:
            also_remove(end+1) = rows_to_remove(j) - 1;
        end
    end
    rows_to_remove = sort(unique([rows_to_remove(:); also_remove(:)]));
    if verbose
        if not(isempty(rows_to_remove))
            printf('read_M_FR_from_spreadsheet: removing %d rows with NaNs in f, M, t, A or Udc. Numbers of rows in excell spreadsheet:\n', numel(rows_to_remove));
            disp(data_row_offset + rows_to_remove(:)');
        end
    end
    % if number of rows is odd, remove also the last one:
    if rem(numel(M_FR.f.v), 2)
        rows_to_remove(end+1) = numel(M_FR.f.v);
        if verbose
            printf('read_M_FR_from_spreadsheet: odd number of rows (%d), removing last one.\n', numel(M_FR.f.v));
        end
    end
    % this should not happen, but just in case:
    rows_to_remove(rows_to_remove > numel(M_FR.f.v)) = []; % Ensure no out-of-bounds indices

    % Remove rows from each field
    M_FR.f.v(rows_to_remove, :)   = [];
    M_FR.M.v(rows_to_remove, :)   = [];
    M_FR.t.v(rows_to_remove, :)   = [];
    M_FR.A.v(rows_to_remove, :)   = [];
    M_FR.A.u(rows_to_remove, :)   = [];
    M_FR.Udc.v(rows_to_remove, :) = [];
    M_FR.Udc.u(rows_to_remove, :) = [];
    M_FR.Udc.r(rows_to_remove, :) = [];

    % check if at least one measurement point is left
    if numel(M_FR.f.v) < 2
        error('read_M_FR_from_spreadsheet: Less than 2 measurement points left after removing rows with NaNs in spreadsheet %s.', filename);
    end

    % Ensure even row is with measurement frequency, even row is with base frequency %<<<1
    if M_FR.f.v(1) < M_FR.f.v(2)
        % if first frequency is smaller than second, swap even and odd rows:
        M_FR.f.v = swap_even_odd_rows(M_FR.f.v);
        M_FR.M.v = swap_even_odd_rows(M_FR.M.v);
        M_FR.t.v = swap_even_odd_rows(M_FR.t.v);
        M_FR.A.v = swap_even_odd_rows(M_FR.A.v);
        M_FR.A.u = swap_even_odd_rows(M_FR.A.u);
        M_FR.Udc.v = swap_even_odd_rows(M_FR.Udc.v);
        M_FR.Udc.u = swap_even_odd_rows(M_FR.Udc.u);
        M_FR.Udc.r = swap_even_odd_rows(M_FR.Udc.r);
        if verbose
            printf('read_M_FR_from_spreadsheet: data starts with base (low) frequency, swapping even and odd rows.\n');
        end
    end
    M_FR.label.v = filename;

end % function read_M_FR_from_spreadsheet(filename)

function res = shift_limits_get_matrix(idx, limits, M) %<<<1
    % Function 'xlsread' returns numeric matrix trimmed around. So if first
	% number in spreadsheet is at position 5,7, xlsread will cut 4 rows and 7 collums
	% so An(1,1) is equal to str(Ra(5,7)). This subfunction fixes the issue.
    % (An is first output of xlsread - numarray)
    % (Ra is third output of xlsread - rawarray, that is not shifted by xlsread in any way.)

    rowshift = limits(2, 1) - 1;
    colshift = limits(1, 1) - 1;
    idx(1) =      idx(1) - rowshift; % row start
    idx(2) =      idx(2) - colshift; % col start
    idx(3) = min( idx(3) - rowshift, size(M, 1) ); % row end
    idx(4) = min( idx(4) - colshift, size(M, 2) ); % col end
    res = M( idx(1) : idx(3), idx(2) : idx(4) );
end % function shift_limits_get_matrix

function res = swap_even_odd_rows(M)
    % Swap even and odd rows in a matrix
    res = M;
    res(1:2:end-1, :) = M(2:2:end, :);
    res(2:2:end, :) = M(1:2:end-1, :);
end % function swap_even_odd_rows

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
