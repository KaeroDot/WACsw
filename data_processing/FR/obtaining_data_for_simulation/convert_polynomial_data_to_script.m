% Converts polynom properties from a file into a matlab script so it can be
% used directly without storing in an external file.

clear all

data_file = 'NI5922_FR_simulator_polynomial_data.mat';
load(data_file)

% Open a new script file for writing
fileID = fopen('polynomial_data_as_script.m', 'w');

variables = {...
			'fs4P', ...
			'fs4MU', ...
			'fs4S', ...
			'fs10P', ...
			'fs10MU', ...
			'fs10S', ...
			'fs15P', ...
			'fs15MU', ...
			'fs15S', ...
			};

for j = 1:numel(variables);
	variable = eval(variables{j});
	if isstruct(variable)
		% Loop through each field of the structure
		fields = fieldnames(variable);
		for i = 1:numel(fields)
			fieldName = fields{i};
			fieldValue = variable.(fieldName);
			% Write the field and its data to the file
			if isnumeric(fieldValue)
				s = sprintf('%s.%s = %s;\n', variables{j}, fieldName, mat2str(fieldValue));
				fprintf(fileID, s);
			else
				error(sprintf('non-numeric field: %s\n', fieldName));
			end
		end
	else
		fprintf(fileID, '%s = %s;\n', variables{j}, mat2str(variable));
	end % if isstruct(variable)
	fprintf(fileID, '\n');
end % for j

% Close the file
fclose(fileID);
