function [M_DG] = read_M_DG_from_sampled_data(DG_info_filename, verbose)
    % Check inputs %<<<1
    if ~exist('verbose', 'var')
        verbose = 0;
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));
    % check the DG_info_filename exists and print error if not
    if ~isfile(DG_info_filename)
        error('read_M_DG_from_sampled_data: info file %s does not exist!', DG_info_filename);
    end

    % load basic data %<<<1
    M_DG = struct();
    % get only directory of DG info file:
    DG_info_dir = fileparts(DG_info_filename);
    % load DG session data:
    DG_info = infoload(DG_info_filename);
    % get PJVS step voltages of 1 period:
    M_DG.Uref1period.v = infogetmatrix(DG_info, 'Set PJVS reference voltages (1 period, V)'); % TODO Uref1period or Upjvs1period? (should be the same)
    % get PJVS frequency:
    % TODO step frequency or envelope frequency?
    M_DG.f_envelope.v = infogetnumber(DG_info, 'Set PJVS frequency (Hz)');
    M_DG.fseg.v = M_DG.f_envelope.v .* numel(M_DG.Uref1period.v);
    M_DG.MRs.v = infogetnumber(DG_info, 'Rs'); % Rs, Re vs MRs, MRe?
    M_DG.MRe.v = infogetnumber(DG_info, 'Re'); % Rs, Re vs MRs, MRe?
    M_DG.PRs.v = 0; % TODO use this property? 
    M_DG.PRe.v = 0; % TODO use this property? 

    % sampled data:
    % get directory with sampled data:
    TWM_data_directory_relative = infogettext(DG_info, 'TWM data directory relative');
    % Convert Windows-style backslashes to system-dependent file separator
    TWM_data_directory_relative = strrep(TWM_data_directory_relative, '\', filesep);
    % load TWM session info file:
    TWM_info = infoload(fullfile(DG_info_dir, TWM_data_directory_relative, 'session.info'));
    % get measurement section:
    samplessection = infogetsection(TWM_info, 'measurement group 1');
    % get sampling frequency:
    M_DG.fs.v = infogetnumber(samplessection, 'sampling rate [Sa/s]');
    % get path to the sampled data:
    samplesdatapath = infogettextmatrix(samplessection, 'record sample data files');
    % Convert Windows-style backslashes to system-dependent file separator
    samplesdatapath = strrep(samplesdatapath{1}, '\', filesep);
    samplesdatapath = fullfile(DG_info_dir, TWM_data_directory_relative, samplesdatapath);
    % load sampled data:
    data = load(samplesdatapath);
    M_DG.y.v = data.y;

    % calculate derived data %<<<1
    L = numel(M_DG.y.v);
    trianglesinrecord = L./M_DG.fs.v.*M_DG.f_envelope.v;
    M_DG.Upjvs.v = repmat(M_DG.Uref1period.v, trianglesinrecord);

    % time vector (TODO think out if really needed for next processing)
    M_DG.t.v = [0 : numel(M_DG.y.v) - 1] ./ M_DG.fs.v;
    M_DG.t.v = reshape(M_DG.t.v, size(M_DG.y.v));

end % function read_M_DG_from_sampled_data

%!demo
%! addpath('..')
%! check_and_set_environment()
%! [M_DG] = read_M_DG_from_sampled_data('DG_measurement/DG_measurement_001.info', 0);
%! P_DG(M_DG, 0);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
