% -- M_CE = check_gen_M_CE()
% -- M_CE = check_gen_M_CE(M_CE)
%    Returns full structure M_CE with fields initialized to [], or adds all needed
%    fields to an existing structure M_CE.
%    Structure M_CE is used to store data generated during measurement/simulation
%    of cable error.
%
%    Inputs:
%      M_CE - structure with cable error measurement. Optional.
%
%    Outputs:
%      M_CE - initialized structure with all required fields.
%
%    Example:
%      M_CE = check_gen_M_CE();

function M_CE = check_gen_M_CE(M_CE)
    % Constants %<<<1
	% quantities/parameters, that will get .v (value) field:
	fields = {...
		'A_nominal' ...
		'fs' ...
		'alg_id' ...
		'ac_source_id' ...
		'digitizer_id' ...
		'f' ...
		'M' ...
		't' ...
		'Ac' ...
		'As' ...
		'FR_fit' ...
	};
	% quantities that also should get .u (uncertainty) field:
	ufields = {...
		'Ac' ...
		'As' ...
		};

    % Check inputs %<<<1
	if not(exist('M_CE', 'var'))
		% create empty structure
		M_CE = struct();
	end

    % Make structure %<<<1
	% add .v field if missing:
	for j = 1:numel(fields)
		if not(isfield(M_CE, fields{j}))
			M_CE.(fields{j}).v = [];
		end
	end % for j
	% add .u fields if missing:
	for j = 1:numel(ufields)
		if not(isfield(M_CE.(fields{j}), 'u'))
			M_CE.(fields{j}).u = [];
		end
	end % for j
end % function

%!demo %<<<1
%! M_CE = check_gen_M_CE()

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
