% -- M_SS = check_gen_M_SS()
% -- M_SS = check_gen_M_SS(M_SS)
%    Returns full structure M_SS with fields initialized to [], or adds all needed
%    fields to an existing structure M_SS.
%    Structure M_SS is used to store data generated during measurement/simulation
%    of subsampling.
%
%    Inputs:
%      M_SS - structure with subsampling measurement. Optional.
%
%    Outputs:
%      M_SS - initialized structure with all required fields.
%
%    Example:
%      M_SS = check_gen_M_SS();

function M_SS = check_gen_M_SS(M_SS)
	% quantities/parameters, that will get .v (value) field:
	fields = {...
		% 'A_nominal', ... % nominal DUT amplitude (V)                     NOT NEEDED FOR P_SS
		'f', ...         % DUT signal frequency (Hz)                     NEEDED
		% 'A', ...         % DUT signal amplitude (V)                      NOT NEEDED FOR P_SS
		% 'ph', ...        % DUT signal phase (rad)                        NOT NEEDED FOR P_SS
		'fs', ...        % sampling rate (Sa/s)                          NEEDED
		'f_envelope', ...% PJVS envelope (triangle) frequency (Hz)       NEEDED
		% 'A_envelope', ...% PJVS envelope amplitude (V)                   NOT NEEDED FOR P_SS
		% 'ph_envelope', ...% PJVS envelope phase (rad)                    NOT NEEDED FOR P_SS
		'f_step', ...    % PJVS step repetition frequency (Hz)           NEEDED
		% 'L', ...         % record length (samples)                       NOT NEEDED FOR P_SS
		% 'ph_step', ...   % PJVS step phase offset (rad)                  NOT NEEDED FOR P_SS
		% 'fm', ...        % microwave frequency for PJVS waveform (Hz)    NOT NEEDED FOR P_SS
		% 'waveformtype', ... % PJVS waveform type selector                NOT NEEDED FOR P_SS
		'Rs', ...        % samples removed at start of PJVS step         NEEDED
		'Re', ...        % samples removed at end of PJVS step           NEEDED
		% 'Upjvs', ...     % full PJVS waveform values (V)                 NOT NEEDED FOR P_SS
		'Upjvs1period', ... % one-period PJVS reference waveform (V)     NEEDED
		% 'Spjvs', ...     % PJVS segment indices / step boundaries        NOT NEEDED FOR P_SS
		% 't', ...         % time vector (s)                               NOT NEEDED FOR P_SS
		'y', ...         % sampled signal values (V)                     NEEDED
        'label', ...    % prefix for output files (plots, results)
        'verbose', ...   % verbosity level (0=quiet, 1=verbose)
        'plot', ...      % plot level (0=no plots, 1=important plots, 2=all plots)
        'plot_visible', ... % plots visibility ('off'=hidden, 'on'=visible)
        'output_path', ... % path for outputs (plots, results)
	};
	% quantities that also should get .u (uncertainty) field:
	ufields = {...
	};
	% quantities that also should get .r (readings) field:
	rfields = {...
	};

    % Check inputs %<<<1
	if not(exist('M_SS', 'var'))
		% create empty structure
		M_SS = struct();
	end

    % Make structure %<<<1
	% add .v field if missing:
	for j = 1:numel(fields)
		if not(isfield(M_SS, fields{j}))
			M_SS.(fields{j}).v = [];
		end
	end % for j
	% add .u fields if missing:
	for j = 1:numel(ufields)
		if not(isfield(M_SS.(ufields{j}), 'u'))
			M_SS.(ufields{j}).u = [];
		end
	end % for j
	% add .r fields if missing:
	for j = 1:numel(rfields)
		if not(isfield(M_SS.(rfields{j}), 'r'))
			M_SS.(rfields{j}).r = [];
		end
	end % for j

    % Check values of selected fields %<<<1
    % label is string:
    if not(ischar(M_SS.label.v))
        warning('Field Label M_SS.label.v must be a string. Setting to empty string.')
        M_SS.label.v = '';
    end
    % plot is numeric:
    if not(isnumeric(M_SS.plot.v))
        warning('Flag M_SS.plot.v must be a string. Setting to 0.')
        M_SS.plot.v = 0;
    end
    % plot_visible is valid string:
    if strcmp(M_SS.plot_visible.v, "on") && strcmp(M_SS.plot_visible.v, "off")
        warning('Flag plot visibility M_SS.plot_visible.v must be "on" or "off". Setting to "off".')
        M_SS.plot_visible.v = "off";
    end
end % function

%!demo %<<<1
%! M_SS = check_gen_M_SS()

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
