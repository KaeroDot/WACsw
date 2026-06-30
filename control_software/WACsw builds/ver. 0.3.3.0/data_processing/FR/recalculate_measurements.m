% Script calculates results of measurement data collected by the TWM system. It
% searches recursively for all TWM measurements within a specified directory
% `search_dir`, and calculate result if result is missing. Processesing is
% parallelized. Algorithm TWM-WRMS is selected.
%
% When to use: if you have measred Frequency Response measurements without
% calculating results.

function recalculate_measurements()

% ----------- USER SETTINGS -----------
% Add your path to the octprog directory in the TWM installation.
path_to_octproc = '/home/martin/metrologie/TWM_github/octprog/';
% Directory to search for TWM measurements:
% FINISHED: search_dir = '/home/martin/winshareM/winshareM/pracovni/martin/wac/FR measurements/mereni_slope/FR 5730 new T 3458 rem guard no battery 15 MHz meas 1_data/';
% FINISHED: search_dir = '/home/martin/winshareM/winshareM/pracovni/martin/wac/FR measurements/mereni_slope/2026-02-10 Tkx old T no 10MHz no batt K2182 10 MSs_data/';
% FINISHED: search_dir = '/home/martin/winshareM/winshareM/pracovni/martin/wac/FR measurements/mereni_slope/NOT_CALCULATED/2026-02-07 FR 5730 old T no 10MHz no batt 10 MSs_data/';
% FINISHED 2026-02-19 search_dir = '/home/martin/winshareM/winshareM/pracovni/martin/wac/FR measurements/mereni_slope/NOT_CALCULATED/2026-06-02 FR 5730 old T no 10MHz no batt 15 MSs_data/';
% FINISHED search_dir = '/home/martin/winshareM/winshareM/pracovni/martin/wac/FR measurements/mereni_slope/NOT_CALCULATED/2026-02-07 FR 5730 old T no 10MHz no batt 15 MSs_data/';
% FINISHED search_dir = '/home/martin/winshareM/winshareM/pracovni/martin/wac/FR measurements/mereni_slope/K2182_v2/2026-02-20 K2182 GPIBgroudingFix 15MSs_data';
% FINISHED search_dir = '/home/martin/winshareM/winshareM/pracovni/martin/wac/FR measurements/measurements/2026-02-24 K2182 GrdDisGnd digit ch2 15 MHz_data';
search_dir = '_data';

% number of processors to be used:
nproc = 3;
% ----------- END OF USER SETTINGS -----------

% Initialization
pkg load statistics;
pkg load multicore;
% add path to info in TWM:
addpath(path_to_octproc);
addpath(fullfile(path_to_octproc, 'info'));
addpath(fullfile(path_to_octproc, 'qwtb'));

% Search for all directories with session.info
fileList = getAllFiles(search_dir, 'session.info', 1)
% create parameters cell - every cell contains cell of strings, first string is
% path to the session.info file, second string is path to the octproc
% directory:
parc = {};
for j = 1:numel(fileList)
    parc{j} = {fileList{j}, path_to_octproc};
end % for j = 1:numel(fileList)

% Calculation
% run parallel calculation using multicore:
opt.master_is_worker = 0;
opt.user_paths = {path_to_octproc};
% res = runmulticore('multicore', @calc_result, parc, nproc + 1, 'multicore_temp', 2, opt);
res = runmulticore('parcellfun', @calc_result, parc, nproc + 1, 'multicore_temp', 2, opt);
% (nproc + 1 is because master is not worker)
        % optionally one can run in for cycle:
        % for j = 1:numel(parc)
        %     res{j} = calc_result(parc{j});
        % end % for j = 1:numel(parc)

end % function recalculate_measurements

%% subfunction calc_result
function finished = calc_result(paths_cell)
    session_info_path = paths_cell{1};
    path_to_octproc = paths_cell{2};
    finished = 0;
    % directory with TWM measurement:
    meas_dir = fileparts(session_info_path);
    % initialization:
    pkg load statistics;
    % add path to info in TWM:
    addpath(path_to_octproc);
    addpath(fullfile(path_to_octproc, 'info'));
    addpath(fullfile(path_to_octproc, 'qwtb'));
    % check if results.info exist, if not, try to calculate
    if ~exist(fullfile(meas_dir, 'results.info'), 'file')
        % check if qwtb.info exist
        if ~exist(fullfile(meas_dir, 'qwtb.info'), 'file')
            % if not, create it
            create_qwtb_info(fullfile(meas_dir, 'qwtb.info'));
        end
        % run calculation using TWM processing:
        qwtb_exec_algorithm(session_info_path, '', 1);
    end % if ~exist(fullfile(meas_dir, 'results.info'), 'file')
    finished = 1;
end % function calc_result(session_info_path)

%% subfunction create_qwtb_info
function create_qwtb_info(filepath)
% create new qwtb.info file with given path for calculation using TWM-WRMS
    fid = fopen(filepath, 'w');
    s = sprintf('%% === QWTB processing setup ===\n\n#startsection:: QWTB processing setup\n        algorithm id:: TWM-WRMS\n\n        calculate whole average at once:: 0\n        uncertainty mode:: none\n        level of confidence [-]:: 95.45\n        #startmatrix:: list of parameter names\n               \n        #endmatrix:: list of parameter names\n       \n       \n        #startsection:: algorithm configuration\n                        %%       name;     fmt;abs;rel\n        #startmatrix:: number formats\n                rms;      si; 1e-9; 1e-7\n                dc;       si; 1e-9; 1e-7\n                spec_f;   si; 1e-9; 1e-7\n                spec_A;   si; 1e-9; 1e-7\n        #endmatrix:: number formats\n        #startmatrix:: graphs\n                spec_f; spec_A\n        #endmatrix:: graphs\n        spectrum:: spec_A\n        #endsection:: algorithm configuration\n#endsection:: QWTB processing setup');
    fprintf(fid, '%s', s);
    fclose(fid);
end % function create_qwtb_info

%% subfunction getAllFiles
function fileList = getAllFiles(dirName, fileMask, appendFullPath)
% returns list of all files, recursively
% version 2

  dirData = dir(fullfile(dirName, fileMask));      %# Get the data for the current directory
  dirWithSubFolders = dir(dirName);
  dirIndex = [dirWithSubFolders.isdir];  %# Find the index for directories
  fileList = {dirData.name}';  %'# Get a list of the files
  if ~isempty(fileList)
    if appendFullPath
      fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
                       fileList,'UniformOutput',false);
    end
  end
  subDirs = {dirWithSubFolders(dirIndex).name};  %# Get a list of the subdirectories
  validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories
                                               %#   that are not '.' or '..'
  for iDir = find(validIndex)                  %# Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
    fileList = [fileList; getAllFiles(nextDir, fileMask, appendFullPath)];  %# Recursively call getAllFiles
  end

end

