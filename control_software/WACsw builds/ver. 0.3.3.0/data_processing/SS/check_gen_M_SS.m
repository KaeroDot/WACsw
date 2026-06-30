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
%      M_ SS - initialized structure with all required fields.
%
%    Example:
%      M_SS = check_gen_M_SS();

function M_SS = check_gen_M_SS(M_SS)
    % Constants %<<<1
	% quantities/parameters, that will get .v (value) field:
	fields = {...
		'fs' ...                    % sampling frequency
		'y' ...                     % samples
	};
                % XXX:
                % % quantities that also should get .u (uncertainty) field:
                % ufields = {...
                %     'A' ...
                %     'Udc' ...
                %     };
                % % quantities that also should get .r (readings) field:
                % rfields = {...
                %     'Udc' ...
                %     };

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
                % XXX:
                % % add .u fields if missing:
                % for j = 1:numel(ufields)
                %     if not(isfield(M_SS.(fields{j}), 'u'))
                %         M_SS.(fields{j}).u = [];
                %     end
                % end % for j
                % % add .r fields if missing:
                % for j = 1:numel(rfields)
                %     if not(isfield(M_SS.(fields{j}), 'u'))
                %         M_SS.(fields{j}).r = [];
                %     end
                % end % for j
end % function

%!demo %<<<1
%! M_SS = check_gen_M_SS()

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
