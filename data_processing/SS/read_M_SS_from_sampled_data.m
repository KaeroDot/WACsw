function [M_SS, FR_fit, CE_fit] = read_M_SS_from_sampled_data(SS_info_filename, verbose)
    % Check inputs %<<<1
    if ~exist('verbose', 'var')
        verbose = 0;
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));
    % check the SS_info_filename exists and print error if not
    if ~isfile(SS_info_filename)
        error('read_M_SS_from_sampled_data: info file %s does not exist!', SS_info_filename);
    end

    % M_SS.A             M_SS.f             M_SS.fs            M_SS.ph            M_SS.Re            M_SS.t             M_SS.waveformtype  
    % M_SS.A_envelope    M_SS.f_envelope    M_SS.f_step        M_SS.ph_envelope   M_SS.Rs            M_SS.Upjvs         M_SS.y             
    % M_SS.A_nominal     M_SS.fm            M_SS.L             M_SS.ph_step       M_SS.Spjvs         M_SS.Upjvs1period 

    % load basic data %<<<1
    M_SS = struct();
    % get only directory of SS info file:
    SS_info_dir = fileparts(SS_info_filename);
    % load SS session data:
    SS_info = infoload(SS_info_filename);
    % get PJVS step voltages of 1 period:
    M_SS.Upjvs1period.v = infogetmatrix(SS_info, 'Set PJVS reference voltages (1 period, V)');
    % get PJVS frequency:
    % TODO step frequency or envelope frequency?
    M_SS.f_envelope.v = infogetnumber(SS_info, 'Set PJVS frequency (Hz)');
    M_SS.f_step.v = M_SS.f_envelope.v .* numel(M_SS.Upjvs1period.v);
    M_SS.f.v = infogetnumber(SS_info, 'Signal frequency (Hz)');
    M_SS.Rs.v = infogetnumber(SS_info, 'Rs');
    M_SS.Re.v = infogetnumber(SS_info, 'Re');

    % FR fit
    new_FR_fit_path_relative = infogettext(SS_info, 'new FR fit path relative');
    FR_fit_loaded = load(fullfile(SS_info_dir, new_FR_fit_path_relative));
    FR_fit = FR_fit_loaded.FR_fit;

    % CE fit
    measure_CE = infogetnumber(SS_info, 'Measure CE');
    if measure_CE
        measure_CE_before = infogetnumber(SS_info, 'Measure CE before');
        measure_CE_after = infogetnumber(SS_info, 'Measure CE after');
        if measure_CE_before
            new_CE_template_path_before_relative = infogettext(SS_info, 'new CE template path before relative');
            % load template, and calculate CE fit:
            if verbose disp(' read_M_SS_from_sampled_data: loading and calculating CE template (measurement before SS) from file...'); end
            M_CE_before = read_M_CE_from_spreadsheet(new_CE_template_path_before_relative, verbose);
            CE_fit_before = P_CE(M_CE_before, verbose);
        end % measure_CE_before
        if measure_CE_after
            new_CE_template_path_after_relative = infogettext(SS_info, 'new CE template path after relative');
            % load template, and calculate CE fit:
            if verbose disp(' read_M_SS_from_sampled_data: loading and calculating CE template (measurement after SS) from file...'); end
            M_CE_after = read_M_CE_from_spreadsheet(new_CE_template_path_after_relative, verbose);
            CE_fit_after = P_CE(M_CE_after, verbose);
        end % measure_CE_after
        if measure_CE_before && measure_CE_after
            % combine both CE fits by interpolation:
            CE_fit = CE_fits_interpolate([CE_fit_before CE_fit_after]);
        elseif measure_CE_before
            CE_fit = CE_fit_before;
        elseif measure_CE_after
            CE_fit = CE_fit_after;
        else
            error('read_M_SS_from_sampled_data: inconsistent CE measurement settings!');
        end % if measure_CE_before && measure_CE_after
    else
        % no CE measurement, load fit from fit file:
        new_CE_fit_path_relative = infogettext(SS_info, 'new CE fit path relative');
        CE_fit_loaded = load(fullfile(SS_info_dir, new_CE_fit_path_relative));
        CE_fit = CE_fit_loaded.CE_fit;
    end

    % sampled data:
    % get directory with sampled data:
    TWM_data_directory_relative = infogettext(SS_info, 'TWM data directory relative');
    % Convert Windows-style backslashes to system-dependent file separator
    TWM_data_directory_relative = strrep(TWM_data_directory_relative, '\', filesep);
    % load TWM session info file:
    TWM_info = infoload(fullfile(SS_info_dir, TWM_data_directory_relative, 'session.info'));
    % get measurement section:
    samplessection = infogetsection(TWM_info, 'measurement group 1');
    % get sampling frequency:
    M_SS.fs.v = infogetnumber(samplessection, 'sampling rate [Sa/s]');
    % get path to the sampled data:
    samplesdatapath = infogettextmatrix(samplessection, 'record sample data files');
    % Convert Windows-style backslashes to system-dependent file separator
    samplesdatapath = strrep(samplesdatapath{1}, '\', filesep);
    samplesdatapath = fullfile(SS_info_dir, TWM_data_directory_relative, samplesdatapath);
    % load sampled data:
    data = load(samplesdatapath);
    M_SS.y.v = data.y;

    % calculate derived data %<<<1
    L = numel(M_SS.y.v);
    trianglesinrecord = L./M_SS.fs.v.*M_SS.f_envelope.v;
    M_SS.Upjvs.v = repmat(M_SS.Upjvs1period.v, trianglesinrecord);

    % time vector (TODO think out if really needed for next processing)
    M_SS.t.v = [0 : numel(M_SS.y.v) - 1] ./ M_SS.fs.v;
    M_SS.t.v = reshape(M_SS.t.v, size(M_SS.y.v));

end % function read_M_SS_from_sampled_data

%!demo
%! addpath('../FR')
%! addpath('../FR/info')
%! addpath('../CE')
%! [M_SS, FR_fit, CE_fit] = read_M_SS_from_sampled_data('SS_measurement/SS_measurement_001.info', 0);
%! P_SS(M_SS, FR_fit, CE_fit, 0);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
