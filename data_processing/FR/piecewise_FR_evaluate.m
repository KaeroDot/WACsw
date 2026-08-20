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
%          (NaN if randomize<=1, populated only when randomize > 1)
%     .r - randomized fit values with dimensions [size(f.v), randomize]
%          (empty if randomize=0)

function y = piecewise_FR_evaluate(ppfit, f, fs, randomize)

    % Check inputs %<<<1
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

    % Prepare inputs and outputs %<<<1
    % piecewise fit will be evaluated at relative frequencies f:
    f_rel.v = f.v./fs.v;
    f_sz = size(f_rel.v);
    % make frequencies flat for simplicity of evaluation:
    f_flat = f_rel.v(:);
    % Prepare output structure
    % initialize matrix with values to nans:
    y.v = NaN.*zeros(f_sz);
    % initialize matrix with uncertainties to nans:
    y.u = NaN.*zeros(size(y.v));
    % initialize matrix with randomized values to nans:
    y.r = y.u;

    % Calculate %<<<1
    % Directly evaluate the fit for y.v:
    y_flat = ppval(ppfit.fit, f_flat);
    % fix size of output structure:
    y.v = reshape(y_flat, f_sz);
    % initialize matrix with uncertainties to nans:
    y.u = NaN.*zeros(size(y.v));
    % initialize matrix with randomized values to nans:
    y.r = y.u;

    if randomize > 0 
        % Do MCM randomizaiton
        y_r_flat = NaN.*zeros(numel(f_flat), randomize);
        % get random values of ramdomizations:
        if randomize < ppfit.MCM
            % randomly select indexes from possible Monte Carlo iterations:
            mcm_idx = 1 + fix(rand(randomize, 1) .* ppfit.MCM);
        else
            % take all available indexes up to ppfit.MCM value:
            mcm_idx = 1:ppfit.MCM;
            if randomize > ppfit.MCM
                warning('piecewise_FR_evaluate: requested %d Monte Carlo evaluations, but only %d are available! Using all available.', randomize, ppfit.MCM)
            end
        end
        % display MCM info (only if large MCM requested):
        if numel(mcm_idx) > 999 fprintf('piecewise_FR_evaluate: evaluating %d monte carlo results...', numel(mcm_idx)); end
        % The actual MCM. Use randomly selected Monte Carlo coefficients
        for ii = 1:numel(mcm_idx)
            if not(rem(ii, 1000))
                fprintf('%d...', ii)
            end
            % get coefficients for this Monte Carlo iteration:
            ppfit.fit.coefs = ppfit.coeffs_r(:, :, mcm_idx(ii));
            % calculate
            y_r_flat(:, ii) = ppval(ppfit.fit, f_flat);
        end
        % display final MCM info (only if large MCM requested):
        if numel(mcm_idx) > 999 fprintf(' finished.\n', numel(mcm_idx)); end
        % reshape randomized values using vector-specific conventions:
        % if f.v was scalar, y.r should be [1, M], column vector -> [N, M], row
        % vector -> [1, N, M], matrix/N-D -> [size(f.v), M]
        if isscalar(f_rel.v)
            y_r_sz = [1 randomize];
        elseif isvector(f_rel.v)
            if size(f_rel.v, 1) > 1
                y_r_sz = [numel(f_rel.v) randomize];
            else
                y_r_sz = [1 numel(f_rel.v) randomize];
            end
        else
            y_r_sz = [f_sz randomize];
        end
        y.r = reshape(y_r_flat, y_r_sz);
        % calculate uncertainty only when at least two MC samples are available:
        if numel(mcm_idx) > 1
            y.u = reshape(std(y_r_flat, 1, 2), f_sz);
            % TODO now the question is if y.v and mean(y.r, 2) differs significantly.
            if any(isnan(y.u(:)))
                warning('piecewise_FR_evaluate: fit uncertainties resulted in NaN values! These values were replaced by 1!')
                y.u(isnan(y.u)) = 1;
            end
        end
        if any(isnan(y.r(:)))
            warning('piecewise_FR_evaluate: fit randomized values resulted in NaN values! These values were replaced by 1!')
            y.r(isnan(y.r)) = 1;
        end
    end

    if any(isnan(y.v(:)))
        warning('piecewise_FR_evaluate: fit evaluation resulted in NaN values! These values were replaced by 1!')
        y.v(isnan(y.v)) = 1;
    end



end % function piecewise_FR_evaluate

% Tests %<<<1
%!test
%! % Test 1: Create a simple mock ppfit structure for testing
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
%! assert(all(isnan(y.u(:))), 'randomize=0 should keep uncertainty as NaN');
%! assert(all(isnan(y.r(:))), 'randomize=0 should keep randomized results full of nans');

%!test
%! % Test 2: Create a simple mock ppfit structure for testing
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
%! % Test 2: row vector should produce [1, N, M] for M > 1
%! y = piecewise_FR_evaluate(ppfit, f, fs, 2);
%! assert(isfield(y, 'r'), 'Output should have .r field for randomize > 0');
%! assert(isequal(size(y.r), [1 numel(f.v) 2]), 'row vector should produce [1 N M]');

%! % Test 2b: randomize=1 should keep uncertainty as NaN
%! y = piecewise_FR_evaluate(ppfit, f, fs, 1);
%! assert(all(isnan(y.u(:))), 'randomize=1 should keep uncertainty as NaN');

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
%! assert(isequal(size(y.r), [size(f.v) ppfit.MCM]), 'randomize=Inf should use all MCM realizations in the last dimension');

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
%! assert(isequal(size(y.u), size(f.v)), 'y.u shape should match f.v shape');
%! assert(isequal(size(y.r), [size(f.v) 3]), 'y.r shape should be [size(f.v), randomize]');

%!test
%! % Test 5: scalar input should produce [1, M] randomized output
%! ppfit.method = 'spline';
%! ppfit.MCM = 4;
%! ppfit.fit = mkpp([0, 0.5, 1], [1, 1; 1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 4);
%! for i = 1:4
%!   ppfit.coeffs_r(:, :, i) = [1 + 0.01*randn(), 1 + 0.01*randn();
%!                               1 + 0.01*randn(), 1 + 0.01*randn()];
%! end
%! f.v = 0.5;
%! fs.v = 1;
%!
%! y = piecewise_FR_evaluate(ppfit, f, fs, 3);
%! assert(isequal(size(y.r), [1 3]), 'scalar input should produce [1 M]');

%!test
%! % Test 6: column vector input should produce [N, M] randomized output
%! ppfit.method = 'spline';
%! ppfit.MCM = 4;
%! ppfit.fit = mkpp([0, 0.5, 1], [1, 1; 1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 4);
%! for i = 1:4
%!   ppfit.coeffs_r(:, :, i) = [1 + 0.01*randn(), 1 + 0.01*randn();
%!                               1 + 0.01*randn(), 1 + 0.01*randn()];
%! end
%! f.v = linspace(0.1, 0.9, 5)';
%! fs.v = 1;
%!
%! y = piecewise_FR_evaluate(ppfit, f, fs, 2);
%! assert(isequal(size(y.r), [5 2]), 'column vector input should produce [N M]');

%!test
%! % Test 7: matrix input should preserve dimensions and randomize in the last one
%! ppfit.method = 'spline';
%! ppfit.MCM = 4;
%! ppfit.fit = mkpp([0, 0.5, 1], [1, 1; 1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 4);
%! for i = 1:4
%!   ppfit.coeffs_r(:, :, i) = [1 + 0.01*randn(), 1 + 0.01*randn();
%!                               1 + 0.01*randn(), 1 + 0.01*randn()];
%! end
%! f.v = reshape(linspace(0.1, 0.9, 6), [2, 3]);
%! fs.v = 1;
%!
%! y = piecewise_FR_evaluate(ppfit, f, fs, 2);
%! assert(isequal(size(y.v), [2, 3]), 'y.v should keep input matrix size');
%! assert(isequal(size(y.u), [2, 3]), 'y.u should keep input matrix size');
%! assert(isequal(size(y.r), [2, 3, 2]), 'y.r should append randomization dimension');

%!test
%! % Test 8: 3-D input should preserve dimensions and append randomization
%! ppfit.method = 'spline';
%! ppfit.MCM = 3;
%! ppfit.fit = mkpp([0, 0.5, 1], [1, 1; 1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 3);
%! for i = 1:3
%!   ppfit.coeffs_r(:, :, i) = [1 + 0.01*randn(), 1 + 0.01*randn();
%!                               1 + 0.01*randn(), 1 + 0.01*randn()];
%! end
%! f.v = reshape(linspace(0.1, 0.9, 24), [2, 3, 4]);
%! fs.v = 1;
%!
%! y = piecewise_FR_evaluate(ppfit, f, fs, 2);
%! assert(isequal(size(y.r), [2, 3, 4, 2]), '3-D input should produce [size(f.v), M]');

%!error
%! % Test 9: Invalid method should raise error
%! ppfit.method = 'invalid_method';
%! ppfit.MCM = 1;
%! ppfit.fit = mkpp([0, 1], [1, 1]);
%! ppfit.coeffs_r = zeros(2, 2, 1);
%! f.v = [0.5];
%! fs.v = 1;
%! piecewise_FR_evaluate(ppfit, f, fs, 0);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
