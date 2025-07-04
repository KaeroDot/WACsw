% -- M_FR = check_gen_M_FR()
% -- M_FR = check_gen_M_FR(M_FR)
%    Returns full structure M_FR with fields initialized to [], or adds all needed
%    fields to an existing structure M_FR.
%    Structure M_FR is used to store data generated during measurement/simulation
%    of transfer function of a digitizer.
%
%    Inputs:
%      M_FR - structure with frequency response measurement. Optional.
%
%    Outputs:
%      M_FR - initialized structure with all required fields.
%
%    Example:
%      M_FR = check_gen_M_FR();

function M_FR = check_gen_M_FR(M_FR)
    % Constants %<<<1
	% quantities/parameters, that will get .v (value) field:
	fields = {...
		'A_nominal' ...
		'fs' ...
		'acdc_settle_time' ...
		'acdc_warm_up_time' ...
		'dc_readings' ...
		'alg_id' ...
		'ac_source_id' ...
		'dc_meter_id' ...
		'digitizer_id' ...
		'f' ...
		'M' ...
		't' ...
		'A' ...
		'Udc' ...
		'acdc_corrections_path' ...
	};
	% quantities that also should get .u (uncertainty) field:
	ufields = {...
		'A' ...
		'Udc' ...
		};
	% quantities that also should get .r (readings) field:
	rfields = {...
		'Udc' ...
		};

    % Check inputs %<<<1
	if not(exist('M_FR', 'var'))
		% create empty structure
		M_FR = struct();
	end

    % Make structure %<<<1
	% add .v field if missing:
	for j = 1:numel(fields)
		if not(isfield(M_FR, fields{j}))
			M_FR.(fields{j}).v = [];
		end
	end % for j
	% add .u fields if missing:
	for j = 1:numel(ufields)
		if not(isfield(M_FR.(fields{j}), 'u'))
			M_FR.(fields{j}).u = [];
		end
	end % for j
	% add .r fields if missing:
	for j = 1:numel(rfields)
		if not(isfield(M_FR.(fields{j}), 'u'))
			M_FR.(fields{j}).r = [];
		end
	end % for j
end % function

%!demo %<<<1
%! M_FR = check_gen_M_FR()

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
