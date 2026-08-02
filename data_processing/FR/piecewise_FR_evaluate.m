% Evaluate a piecewise spline fit and optionally compute uncertainties using Monte Carlo method.
%
% Inputs:
%   ppfit - piecewise fit structure created by piecewise_FR_fit, containing:
%           .fit - the piecewise polynomial fit object
%           .coeffs_r - 3D array of Monte Carlo coefficient realizations
%           .MCM - number of Monte Carlo realizations available
%           .method - fitting method (must be 'spline')
%   f - structure with field .v containing frequency vector (Hz) at which to evaluate the fit
%   fs - structure with field .v containing sampling frequency (Hz) used to normalize f
%   randomize - (optional) number of Monte Carlo evaluations to return in y.r
%               Default: Inf (use all available MCM realizations)
%
% Outputs:
%   y - structure containing:
%     .v - evaluated fit values at the requested frequencies (always populated)
%     .u - standard uncertainty from randomized coefficient evaluation
%          (NaN if randomize=0, populated only when randomize > 0)
%     .r - matrix of randomized fit values (size: randomize x numel(f.v))
%          one row per Monte Carlo trial (empty if randomize=0)
function y = piecewise_FR_evaluate(ppfit, f, fs, randomize)
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
    f_rel = f.v./fs.v;
    y.v = ppval(ppfit.fit, f_rel);

    if any(isnan(y.v))
        warning('piecewise_FR_evaluate: fit evaluation resulted in NaN values! These values were replaced by 1!')
        y.v(isnan(y.v)) = 1;
    end

    % initialize matrix with randomized values to nans:
    y.u = NaN.*zeros(size(y.v));

    % do MCM randomizaiton
    if randomize > 0
        % get MCM randomized values:
        y.r = NaN.*zeros(size(y.v, 1), randomize);
        % determine value of ramdomizations:
        if randomize < ppfit.MCM
            % randomly select indexes from possible Monte Carlo iterations:
            idx = 1 + fix(rand(randomize, 1) .* ppfit.MCM);
        else
            % take all indexes:
            idx = 1:ppfit.MCM;
            if randomize > ppfit.MCM
                warning('piecewise_FR_evaluate: requested %d Monte Carlo evaluations, but only %d are available! Using all available.', randomize, ppfit.MCM)
            end
        end
        % display MCM info only if large MCM requested:
        if numel(idx) > 999 fprintf('piecewise_FR_evaluate: evaluating %d monte carlo results...', numel(idx)); end
        for ii = 1:numel(idx)
            if not(rem(ii, 1000))
                fprintf('%d...', ii)
            end
            % The MCM. Use randomly selected Monte Carlo coefficients
            ppfit.fit.coefs = ppfit.coeffs_r(:, :, idx(ii));
            y.r(:, ii) = ppval(ppfit.fit, f_rel);
        end
        % display MCM info only if large MCM requested:
        if numel(idx) > 999 fprintf(' finished.\n', numel(idx)); end
        % calculate uncertainty:
        y.u = std(y.r, 0, 2);
        % TODO now the question is if y.v and mean(y.r, 2) differs significantly.
        if any(isnan(y.u))
            warning('piecewise_FR_evaluate: fit uncertainties resulted in NaN values! These values were replaced by 1!')
            y.u(isnan(y.u)) = 1;
        end
        if any(any(isnan(y.r)))
            warning('piecewise_FR_evaluate: fit randomized values resulted in NaN values! These values were replaced by 1!')
            y.r(isnan(y.r)) = 1;
        end
    end
end % function piecewise_FR_evaluate

% Tests %<<<1
%!test
%! % Create a simple mock ppfit structure for testing
%! ppfit.method = 'spline';
%! ppfit.MCM = 10;
%! % Create a simple polynomial fit (degree 1)
%! ppfit.fit = mkpp([0, 0.5, 1], [1, 1; 1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 10);
%! for i = 1:10
%!   ppfit.coeffs_r(:, :, i) = [1 + 0.01*randn(), 1 + 0.01*randn(); 
%!                               1 + 0.01*randn(), 1 + 0.01*randn()];
%! end
%! f.v = linspace(0.1, 0.9, 5);
%! fs.v = 1;
%! 
%! % Test 1: Basic functionality with randomize=0 (no Monte Carlo)
%! y = piecewise_FR_evaluate(ppfit, f, fs, 0);
%! assert(isstruct(y), 'Output should be a structure');
%! assert(isfield(y, 'v'), 'Output structure should have .v field');
%! assert(numel(y.v) == numel(f.v), 'Output size should match input frequency size');
%! assert(all(~isnan(y.v)), 'Output values should not be NaN');

%!test
%! % Create a simple mock ppfit structure for testing
%! ppfit.method = 'spline';
%! ppfit.MCM = 10;
%! ppfit.fit = mkpp([0, 0.5, 1], [1, 1; 1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 10);
%! for i = 1:10
%!   ppfit.coeffs_r(:, :, i) = [1 + 0.01*randn(), 1 + 0.01*randn(); 
%!                               1 + 0.01*randn(), 1 + 0.01*randn()];
%! end
%! f.v = linspace(0.1, 0.9, 5);
%! fs.v = 1;
%! 
%! % Test 2: randomize=1 should have y.r with 1 row
%! y = piecewise_FR_evaluate(ppfit, f, fs, 1);
%! assert(isfield(y, 'r'), 'Output should have .r field for randomize > 0');
%! assert(size(y.r, 1) == 1, 'randomize=1 should produce 1 Monte Carlo realization');
%! assert(size(y.r, 2) == numel(f.v), 'y.r column count should match frequency count');

%!test
%! % Test 3: randomize=Inf should use all MCM realizations
%! ppfit.method = 'spline';
%! ppfit.MCM = 5;
%! ppfit.fit = mkpp([0, 0.5, 1], [1, 1; 1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 5);
%! for i = 1:5
%!   ppfit.coeffs_r(:, :, i) = [1 + 0.01*randn(), 1 + 0.01*randn(); 
%!                               1 + 0.01*randn(), 1 + 0.01*randn()];
%! end
%! f.v = linspace(0.1, 0.9, 5);
%! fs.v = 1;
%! 
%! y = piecewise_FR_evaluate(ppfit, f, fs, Inf);
%! assert(size(y.r, 1) == ppfit.MCM, 'randomize=Inf should use all MCM realizations');

%!test
%! % Test 4: Output structure has all required fields
%! ppfit.method = 'spline';
%! ppfit.MCM = 3;
%! ppfit.fit = mkpp([0, 0.5, 1], [1, 1; 1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 3);
%! for i = 1:3
%!   ppfit.coeffs_r(:, :, i) = [1, 1; 1, 1];
%! end
%! f.v = [0.2, 0.5, 0.8];
%! fs.v = 1;
%! 
%! y = piecewise_FR_evaluate(ppfit, f, fs, 3);
%! assert(isfield(y, 'v'), 'Output should have .v field');
%! assert(isfield(y, 'u'), 'Output should have .u field for uncertainties');
%! assert(isfield(y, 'r'), 'Output should have .r field for randomized values');

%!error
%! % Test 5: Invalid method should raise error
%! ppfit.method = 'invalid_method';
%! ppfit.MCM = 1;
%! ppfit.fit = mkpp([0, 1], [1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 1);
%! f.v = [0.5];
%! fs.v = 1;
%! piecewise_FR_evaluate(ppfit, f, fs, 0);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
