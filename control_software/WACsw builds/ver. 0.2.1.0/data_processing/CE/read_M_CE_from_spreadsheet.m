% -- M_CE = read_M_CE_from_spreadsheet(filename, verbose)
%     Reads measurement of a cable error from a spreadsheet 
%     template defined in `Example of CE meter template.xlsx`.
%     Inputs:
%      filename - path and name of a spreadsheet file
%      verbose - if nonzero, verbose output is printed
%     Outputs:
%      M_CE - structure with measurement data. Structure is defined in function 'check_gen_M_CE.m'.
%
%     Example:
%      M_CE = read_M_CE_from_spreadsheet('Example of CE meter template.xlsx')

function M_CE = read_M_CE_from_spreadsheet(filename, verbose)
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
    idx_A_nominal           = [ 2,  5,    2,  5]; % Nominal amplitude
    idx_fs                  = [ 3,  5,    3,  5]; % Sampling frequency
    idx_ac_source_settle_time   = [4, 5,  4,  5]; % AC source settle time
    idx_L_long              = [ 5,  5,    5,  5]; % cable length of long (PJVS)
    idx_L_long_unc          = [ 6,  5,    6,  5]; % cable length of long (PJVS)
    idx_L_short             = [ 7,  5,    7,  5]; % cable length of short
    idx_L_short_unc         = [ 8,  5,    8,  5]; % cable length of short
    idx_alg_id              = [ 9,  5,    9,  5]; % Algorithm ID
    idx_FR_fit_path         = [10,  5,   10,  5]; % path to mat file with FR fit
    idx_ac_source_id        = [ 2,  8,    2,  8]; % AC source ID
    idx_digitizer_id        = [ 4,  8,    4,  8]; % Digitizer ID
    idx_f                   = [14,  2, 2000,  2]; % Signal frequency
    idx_M                   = [14,  3, 2000,  3]; % Record length in periods
    idx_sw                  = [14,  4, 2000,  4]; % Switch position
    idx_t                   = [14,  5, 2000,  5]; % TIme of reading
    idx_A_v                 = [14,  6, 2000,  6]; % Amplitude values
    idx_A_u                 = [14,  7, 2000,  7]; % Amplitude uncertainties

    % Read and extract data %<<<1
    % Read the Excel file and extract numeric and raw data
    [An, Tn, Ra, limits] = xlsread(filename);

    % Get row offset of measured data:
    data_row_offset = idx_f(1) - limits.numlimits(1,1) + 1;
    % Parse data and populate the M_CE structure
    M_CE.A_nominal.v            = shift_limits_get_matrix(idx_A_nominal,          limits.numlimits, An)(:);
    M_CE.fs.v                   = shift_limits_get_matrix(idx_fs,                 limits.numlimits, An)(:);
    M_CE.ac_source_settle_time.v = shift_limits_get_matrix(idx_ac_source_settle_time ,  limits.numlimits, An)(:);
    FR_fit_path                 = shift_limits_get_matrix(idx_FR_fit_path,        limits.txtlimits, Ra){1};
    M_CE.alg_id.v               = shift_limits_get_matrix(idx_alg_id,             limits.txtlimits, Ra){1};
    M_CE.L.v                    = [shift_limits_get_matrix(idx_L_long,            limits.txtlimits, Ra){1} ...
                                   shift_limits_get_matrix(idx_L_short,           limits.txtlimits, Ra){1}];
    M_CE.L.u                    = [shift_limits_get_matrix(idx_L_long_unc,        limits.txtlimits, Ra){1} ...
                                   shift_limits_get_matrix(idx_L_short_unc,       limits.txtlimits, Ra){1}];
    % TODO missing uncertainties for L_short and L_long
    M_CE.ac_source_id.v         = shift_limits_get_matrix(idx_ac_source_id,       limits.txtlimits, Ra){1};
    M_CE.digitizer_id.v         = shift_limits_get_matrix(idx_digitizer_id,       limits.txtlimits, Ra){1};

    % Extract matrix data for frequency, measurements, time, etc.
    M_CE.f.v   = shift_limits_get_matrix(idx_f,     limits.numlimits, An)(:);
    M_CE.M.v   = shift_limits_get_matrix(idx_M,     limits.numlimits, An)(:);
    M_CE.sw.v  = shift_limits_get_matrix(idx_sw,    limits.numlimits, An)(:);
    M_CE.t.v   = shift_limits_get_matrix(idx_t,     limits.numlimits, An)(:);
    M_CE.A.v   = shift_limits_get_matrix(idx_A_v,   limits.numlimits, An)(:);
    M_CE.A.u   = shift_limits_get_matrix(idx_A_u,   limits.numlimits, An)(:);

    % Load FR fit %<<<1
    % first check if path is absolute or relative:
    % (checks for / at start (linux case) or X:/ or X:\ at start (windows case))
    is_absolute = ~isempty(regexp(FR_fit_path, '^(\/|[A-Za-z]:[\\/])', 'once'));
    if not(is_absolute)
        % relative path - make it relative to the spreadsheet file location
        [spreadsheet_path, ~, ~] = fileparts(filename);
        FR_fit_path = fullfile(spreadsheet_path, FR_fit_path);
    end
    if exist(FR_fit_path, 'file') ~= 2
        error('read_M_CE_from_spreadsheet: FR fit file `%s` does not exist.', FR_fit_path);
    end
    tmp = load(FR_fit_path);
    if ~isfield(tmp, 'FR_fit')
        error('read_M_CE_from_spreadsheet: FR fit file `%s` does not contain variable `FR_fit`.', FR_fit_path);
    end
    M_CE.FR_fit = tmp.FR_fit;

    % Properly convert excell time to octave time %<<<1
    % Convert time from Excel's format (days since 0/0/1900) to Unix time
    % (seconds since 1/1/1970) (this date does not exist - Excell stupid
    % format)
    t_delta = datenum(1900,01,00,0,0,0); % Offset for Excel time, that is 693961
    M_CE.t.v = M_CE.t.v + t_delta;
    for j = 1:numel(M_CE.t.v)
        if ~isnan(M_CE.t.v(j))
            tmp = datestr(M_CE.t.v(j), 31);
            tmp2 = strptime(tmp, '%Y-%m-%d %H:%M:%S');
            M_CE.t.v(j) = mktime(tmp2);
        end
    end

    % Validate data for type, NaNs, and empty values %<<<1
    % Define expected field types
    mandatory_fields = {'fs', 'f', 'M', 't', 'sw', 'A'};
    % Ensure mandatory fields in M_CE are properly validated
    for i = 1:numel(mandatory_fields)
        data = M_CE.(mandatory_fields{i}).v;
        % Check for empty data
        if isempty(data)
            error('read_M_CE_from_spreadsheet: Quantity `%s.v` is empty. The spreadsheet is probably not according expected template.', mandatory_fields{i});
        end
        if ~isnumeric(data)
            error('read_M_CE_from_spreadsheet: Quantity `%s.v` should be numeric but is not. The spreadsheet is probably not according expected template.', mandatory_fields{i});
        end
    end

    % Remove rows with NaNs in any of f, M, t, A, sw %<<<1
    % Find rows with NaNs
    nan_rows = any([...
                    isnan(M_CE.f.v) ...
                    isnan(M_CE.M.v) ...
                    isnan(M_CE.t.v) ...
                    isnan(M_CE.sw.v) ...
                    isnan(M_CE.A.v) ...
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
            printf('read_M_CE_from_spreadsheet: removing %d rows with NaNs in f, M, t, sw or A. Numbers of rows in excell spreadsheet:\n', numel(rows_to_remove));
            disp(data_row_offset + rows_to_remove(:)');
        end
    end
    % if number of rows is odd, remove also the last one:
    if rem(numel(M_CE.f.v), 2)
        rows_to_remove(end+1) = numel(M_CE.f.v);
        if verbose
            printf('read_M_CE_from_spreadsheet: odd number of rows (%d), removing last one.\n', numel(M_CE.f.v));
        end
    end
    % this should not happen, but just in case:
    rows_to_remove(rows_to_remove > numel(M_CE.f.v)) = []; % Ensure no out-of-bounds indices

    % Remove rows from each field
    M_CE.f.v(rows_to_remove, :)   = [];
    M_CE.M.v(rows_to_remove, :)   = [];
    M_CE.t.v(rows_to_remove, :)   = [];
    M_CE.sw.v(rows_to_remove, :)  = [];
    M_CE.A.v(rows_to_remove, :)   = [];
    M_CE.A.u(rows_to_remove, :)   = [];

    % check if at least one measurement point is left
    if numel(M_CE.f.v) < 1
        error('read_M_CE_from_spreadsheet: Less than 1 measurement point left after removing rows with NaNs in spreadsheet %s.', filename);
    end

    % add label to be used for filenames of next processing steps %<<<1
    [spreadsheet_path, spreadsheet_name, ~] = fileparts(filename);
    M_CE.label.v = fullfile(spreadsheet_path, spreadsheet_name);

end % function read_M_CE_from_spreadsheet(filename)

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

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
