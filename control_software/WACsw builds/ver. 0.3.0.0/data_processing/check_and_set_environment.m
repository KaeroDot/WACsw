% Script checks if the environment is sane for running the data processing
% scripts. If not, it tries to fix it (e.g. by installing missing packages). If
% it cannot fix it, it throws an error with instructions on how to fix it.

function check_and_set_environment()
%% Check and set paths for data processing subdirectories %<<<1
script_path = fileparts(mfilename('fullpath'));
required_paths = {'FR', 'CE', 'SS', 'utils', fullfile('utils', 'info')};

for j = 1:numel(required_paths)
    full_path = fullfile(script_path, required_paths{j});
    if exist(full_path, 'dir')
        if not(any(strcmp(path, full_path)))
            addpath(full_path);
            if nargout == 0
                fprintf('Added to path: %s\n', full_path);
            end
        end
    else
        warning('Required directory not found: %s', full_path);
    end
end

%% Check for csv2cell function and io package %<<<1
if not(exist('csv2cell'))
    if isOctave()
        % check if octave io package is installed:
        listout = pkg('list');
        packages = {};
        for j = 1:numel(listout)
            packages{j} = listout(j).name;
        end
        if strmatch('io', packages)
            % io package is installed
            pkg load io
        else
            % try to install io package
            try
                pkg install -forge io
            catch
                error('"csv2cell" function is missing. Usually one needs Octave package "io". I have tried to install this package but failed. Please install it by yourself, typically command is: "pkg install -forge io".');
            end
            pkg load io
            % check if csv2cell is now available:
            if not(exist('csv2cell'))
                error('"csv2cell" function is missing. Usually one needs Octave package "io". I have tried to install this package but failed. Please install it by yourself, typically command is: "pkg install -forge io".');
            end
        end
    else % matlab case
        % TODO something to do for matlab?

    end % if isOctave
end % if not(exist('csv2cell'))

end % function check_and_set_environment