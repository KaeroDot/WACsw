% Linearly interpolates the parameters of multiple CE_fit structures.
%
% Inputs:
%   CE_fit - Array of CE_fit structures, each with identical fit methods and parameters.
%
% Outputs:
%   CE_fit_int - CE_fit structure with parameters averaged across input fits.
%
% Notes:
%   - Only works for vector parameters (no matrices).
%   - Does not interpolate R, COVB, or MSE fields of the nlinfit (set to []).
%   - All input CE_fit structures must use the same fit method.
%

function CE_fit_int = interpolate_CE_fits(CE_fit)
    % check inputs:
    all_methods = {CE_fit.method};

    if not(all(strcmp(CE_fit(1).method, all_methods)))
        all_methods
        error('interpolate_CE_fits: Different fit methods in CE_fit(i), cannot interpolate different fit methods!');
    end

    % Interpolate fit parameters linearly
    % (works only for vector of parameters. No matrices allowed here!)
    CE_fit_int = CE_fit(1); % initialize output structure
    all_params = nan.*zeros( numel(CE_fit(1).params), numel(CE_fit) );
    for j = 1:numel(CE_fit)
        all_params(:, j) = CE_fit(j).params(:);
    end
    CE.fit.params = mean(all_params, 2);
    CE.fit.params = reshape(CE.fit.params, size(CE_fit(1).params));
    CE.fit.R = []; % TODO I have no idea how to interpolate R, COVB, MSE
    CE.fit.J = []; % TODO I have no idea how to interpolate R, COVB, MSE
    CE.fit.COVB = []; % TODO I have no idea how to interpolate R, COVB, MSE
    CE.fit.MSE = []; % TODO I have no idea how to interpolate R, COVB, MSE

    % TODO time of measurments should be intput: t1, t2, and also t_int as time for which we want to interpolate
end % function interpolate_CE_fits
