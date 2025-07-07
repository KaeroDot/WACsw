function piecewise_fit = piecewise_FR_fit(f, FR, M_FR, verbose)
    % XXX should fit error or fit gain? gain: 1+err, error: err
    % XXX maybe replace M_FR by only fs, other things are not needed at all, or take f and FR from M_FR!

    % Check inputs %<<<1
    % XXX check also other inputs
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Constants 
    % method = 'polynomial';
    method = 'spline';

    % number of regions of the piecewise fitting:
    regions = 30;
    % degree of polynomials:
    max_pol_degree = 3;

    % Calculation %<<<1
    % convert frequency to relative to sampling:
    f_rel = f.v ./ M_FR.fs.v;

    % Create first part of output structure
    piecewise_fit.method = method;
    piecewise_fit.regions = regions;

    if strcmp(method, 'spline') %<<<1
        piecewise_fit.fit = splinefit(f_rel, FR.v, regions - 1);
        piecewise_fit.limits = piecewise_fit.fit.breaks .* M_FR.fs.v;
    elseif strcmp(method, 'polynomial')
    % Polynomial method %<<<1
        % find limits of the piece regions:
        limits_rel = linspace(min(f_rel), max(f_rel), regions + 1);
        % absolute limits of the piece regions:
        piecewise_fit.limits = limits_rel .* M_FR.fs.v;

        % for every part of frequency range 0 to nyquist range:
        for j = 1:numel(limits_rel) - 1
            idx = and(f_rel >= limits_rel(j), f_rel <= limits_rel(j+1));
            x = f_rel(idx);
            y = FR.v(idx);
            % make polynomial fit
            [P{j} S{j} MU{j}] = polyfit(x, y, min(numel(y), max_pol_degree) );
        end
        % Create output structure
        piecewise_fit.fit.max_pol_degree.v = max_pol_degree;
        piecewise_fit.fit.polP = P;
        piecewise_fit.fit.polS = S;
        piecewise_fit.fit.polMU = MU;
    else
        error(sprintf('piecewise_FR_fit: unknown method `%s`!', method))
    end % if method

    % Verbose plots %<<<1
    if verbose
        % fit at measurement points:
        fit_data_y = piecewise_FR_evaluate(piecewise_fit, f.v, M_FR.fs);
        % fit for 10x multiple points to make a line:
        fit_line_x = linspace(min(f_rel), max(f_rel), 10*numel(f_rel));
        fit_line_x = fit_line_x.*M_FR.fs.v;
        fit_line_y = piecewise_FR_evaluate(piecewise_fit, fit_line_x, M_FR.fs);

        % overview plot
        figure()
        hold on
        plot(f.v, FR.v, '-xb');
        plot(f.v, fit_data_y, 'or');
        plot(fit_line_x, fit_line_y, '-r');
        for j = 1:numel(piecewise_fit.limits)
            plot([piecewise_fit.limits(j) piecewise_fit.limits(j)], ylim, 'k--');
        end
        legend('measured result', 'fit at measured data', 'fit line', 'limits of fit regions')
        xlabel('measurement frequency (Hz)')
        ylabel('digitizer gain (V/V)')
        % total error:
        idx = not(isnan(fit_data_y));
        err = sum(abs(fit_data_y(idx) - FR.v(idx)));
        title(sprintf('piecewise_FR_fit.m\nmeasured data and fit\ntotal error sum(abs((fit - measured))) = %.3g', err), 'interpreter', 'none')
        hold off

        % error plot
        figure()
        hold on
        plot(f.v, fit_data_y - FR.v, '-r');
        for j = 1:numel(piecewise_fit.limits)
            plot([piecewise_fit.limits(j) piecewise_fit.limits(j)], ylim, 'k--');
        end
        legend('fit error (fit - measured)', 'limits of fit regions')
        xlabel('measurement frequency (Hz)')
        ylabel('fit error of the digitizer gain (V/V)')
        % total error:
        title(sprintf('piecewise_FR_fit.m\nfit errors\ntotal error sum(abs((fit - measured))) = %.3g', err), 'interpreter', 'none')
        hold off

    end

end % function fit_FR_piecewise

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
