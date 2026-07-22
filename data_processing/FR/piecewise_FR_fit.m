% Fit frequency response data with piecewise polynomials or splines.
%
% Output:
%   ppfit - structure containing:
%     .method   - fitting method used ('spline' or 'polynomial')
%     .no_fit_regions  - number of regions for piecewise fitting
%     .breaks   - frequency limits of each region (Hz)
%     .fit      - fit parameters:
%       For 'spline':
%         .fit - spline structure as returned by splinefit, with fields:
%            .breaks   - vector of breakpoints between regions
%                       (Hz relative to sampling frequency)
%            .coefs    - matrix of spline coefficients for each region
%            .order    - order of the spline
%            .pieces   - number of spline pieces (regions)
%       For 'polynomial':
%         .fit.max_pol_degree.v - degree of polynomial
%         .fit.polP            - cell array of polynomial coefficients for each region
%         .fit.polS            - cell array of polynomial structure for each region
%         .fit.polMU           - cell array of centering/scaling for each region
%
% Usage:
%   ppfit = piecewise_FR_fit(f, FR, M_FR, verbose)
%
    % TODO should fit error or fit gain? gain: 1+err, error: err

function ppfit = piecewise_FR_fit(FR, M_FR, verbose)
    % Constants %<<<1
    method = 'spline'; % method will be always spline. Polynomial deliver worse results.
    MCM = 1e3; % Monte Carlo iterations

    % Check inputs %<<<1
    % validate verbose
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    else
        verbose = logical(verbose(1));
    end

    % Initialize %<<<1
    ppfit.method = method;
    ppfit.no_fit_regions = M_FR.no_fit_regions.v;
    ppfit.MCM = MCM;
    % freuencies of measurement points:
    % frequencies in M_FR are interleaved with reference frequency. First value
    % is measurement ferquency, second value is reference frequency.
    f_meas = reshape(M_FR.f.v, 2, [])';
    f.v = f_meas(:,1);

    % Calculation %<<<1
    % convert frequency to relative to sampling:
    f_rel = f.v ./ M_FR.fs.v;

    % calculate non randomized fit:
    ppfit.fit = splinefit(f_rel, FR.v, ppfit.no_fit_regions - 1);
    ppfit.breaks = ppfit.fit.breaks .* M_FR.fs.v;

    % Do monte carlo method
    ppfit.coeffs_r = NaN.*zeros(size(ppfit.fit.coefs, 1), size(ppfit.fit.coefs, 2), MCM);
    fprintf('piecewise_FR_fit.m: starting %g monte carlo iterations\n', MCM);
    for ii = 1:MCM
        if not(rem(ii, 100))
            fprintf('%d..', ii)
        end
        % randomize values using FR.v and FR.u
        val = FR.v + randn(size(FR.v)) .* FR.u;
        % make fit:
        tmp = splinefit(f_rel, val, ppfit.no_fit_regions - 1);
        ppfit.coeffs_r(:, :, ii) = tmp.coefs;
    end
    fprintf('\npiecewise_FR_fit.m: finished monte carlo\n', MCM);

    % Calculate total fit error for the non-randomized fit:
    fit_at_data = piecewise_FR_evaluate(ppfit, f.v, M_FR.fs, 100);
    idx = not(isnan(fit_at_data.v));
    ppfit.total_error = trapz(f.v, abs(fit_at_data.v(idx) - FR.v(idx)));

    % Verbose plots %<<<1
    if verbose
        % fit for 10x multiple points to make a line:
        interpolated_x = linspace(min(f_rel), max(f_rel), 10*numel(f_rel));
        interpolated_x = interpolated_x.*M_FR.fs.v;
        interpolated_fit = piecewise_FR_evaluate(ppfit, interpolated_x, M_FR.fs, 1e2);

        % overview plot
        figure()
        hold on
        plot(f.v, FR.v, '-xb', 'displayname', 'measured data');
        plot(interpolated_x, interpolated_fit.v, '-r', 'displayname', 'fit');
        plot(interpolated_x, interpolated_fit.v + interpolated_fit.u, '--r', 'displayname', 'fit uncertainty');
        plot(interpolated_x, interpolated_fit.v - interpolated_fit.u, '--r', 'displayname', 'fit uncertainty');
        for jj = 1:numel(ppfit.breaks)
            if jj == 1
                leg = {'displayname', 'breaks of fit regions'};
            else
                leg = {'handlevisibility', 'off'};
            end
            plot([ppfit.breaks(jj) ppfit.breaks(jj)], ylim, 'k--', leg{:});
        end
        legend()
        xlabel('measurement frequency (Hz)')
        ylabel('digitizer gain (V/V)')
        title(sprintf('piecewise_FR_fit.m\nmeasured data and fit\ntotal error trapz(abs((fit - measured))) = %.3g',...
                      ppfit.total_error), 'interpreter', 'none')
        hold off

        % error plot
        figure()
        hold on
        plot(f.v, fit_at_data.v - FR.v, '-r', 'displayname', 'fit - measured');
        plot(f.v, +1.*fit_at_data.u, '--r', 'displayname', 'fit uncertainty');
        plot(f.v, -1.*fit_at_data.u, '--r', 'displayname', 'fit uncertainty');
        for j = 1:numel(ppfit.breaks)
            if jj == 1
                leg = {'displayname', 'breaks of fit regions'};
            else
                leg = {'handlevisibility', 'off'};
            end
            plot([ppfit.breaks(j) ppfit.breaks(j)], ylim, 'k--', leg{:});
        end
        legend();
        xlabel('measurement frequency (Hz)')
        ylabel('fit error of the digitizer gain (V/V)')
        title(sprintf('piecewise_FR_fit.m\nfit errors\ntotal error trapz(abs((fit - measured))) = %.3g',...
                      ppfit.total_error), 'interpreter', 'none')
        hold off
    end

end % function fit_FR_piecewise

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
