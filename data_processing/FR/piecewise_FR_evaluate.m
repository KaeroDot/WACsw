% Evaluate a piecewise spline fit and optionally compute uncertainties using Monte Carlo method.
%
% Outputs:
%   y - structure containing:
%     .v - evaluated fit values at the requested frequencies
%     .u - standard uncertainty from randomized coefficient evaluation
%     .r - matrix of randomized fit values, one column per trial
%
% Inputs:
%   ppfit - piecewise fit structure created by piecewise_FR_fit
%   f - frequency vector at which to evaluate the fit
%   fs - sampling-frequency structure used to normalize f
%   randomize - number of Monte Carlo evaluations to return in y.r; if
%       omitted, all available Monte Carlo realizations are used
function [y, y_mcm] = piecewise_FR_evaluate(ppfit, f, fs, randomize)
    % Check inputs %<<<1
    % XXX
    if not(exist('randomize', 'var'))
        randomize = Inf;
    end
    randomize = round(randomize);
    if randomize < 0
        randomize = 0;
    end
    if randomize > ppfit.MCM
        randomize = ppfit.MCM;
    end
    if not(strcmp(ppfit.method, 'spline'))
        error(sprintf('piecewise_FR_evaluate: unknown method `%s`!', ppfit.method))
    end

    % evaluate piecewise fit ppfit for absolute frequencies f
    f_rel = f./fs.v;
    y.v = ppval(ppfit.fit, f_rel);
    y.v = y.v(:);

    if any(isnan(y.v))
        warning('piecewise_FR_evaluate: fit evaluation resulted in NaN values! These values were replaced by 1!')
        y.v(isnan(y.v)) = 1;
    end

    % initialize matrix with randomized values to nans:
    y.u = NaN.*zeros(size(y.v));
    y.r = NaN.*zeros(numel(y.v), randomize);

    % do MCM randomizaiton
    if randomize > 0
        if randomize < ppfit.MCM
            % randomly select indexes from possible Monte Carlo iterations:
            idx = 1 + fix(rand(randomize, 1) .* ppfit.MCM);
        else
            % take all indexes:
            idx = 1:ppfit.MCM;
        end
        if numel(idx) > 999 
            fprintf('piecewise_FR_evaluate: evaluating %d monte carlo results', numel(idx));
        end
        for ii = 1:numel(idx)
            if not(rem(ii, 1000))
                fprintf('%d...', ii)
            end
            ppfit.fit.coefs = ppfit.coeffs_r(:, :, idx(ii));
            y.r(:, ii) = ppval(ppfit.fit, f_rel)(:);
        end
        if numel(idx) > 999
            fprintf(' finished.\n', numel(idx));
        end
        if any(isnan(y.r))
            y.r(isnan(y.r)) = 1;
        end
        y.u = std(y.r, 0, 2);
        % TODO now the question is if y.v and mean(y.r, 2) differs significantly.
    end

end % function piecewise_FR_evaluate

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
