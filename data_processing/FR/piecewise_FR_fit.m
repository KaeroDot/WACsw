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
    method = 'polynomial';
    % method = 'spline';

    % number of intervals of the piecewise fitting:
    intervals = 30;
    % maximum frequency considered in the frequency range:
    f_max_rel = 0.45;
    % degree of polynomials:
    max_pol_degree = 3;

    % Calculation %<<<1
    % convert frequency to relative to sampling:
    f_rel = f.v ./ M_FR.fs.v;

    % Create first part of output structure
    piecewise_fit.method = method;
    piecewise_fit.intervals = intervals;

    if strcmp(method, 'spline') %<<<1
        piecewise_fit.fit = splinefit(f_rel, FR.v, intervals);
    elseif strcmp(method, 'polynomial')
    % Polynomial method %<<<1
        % find limits of the piece intervals:
        limits = linspace(min(f_rel), max(f_rel), intervals + 1);
        % absolute limits of the piece intervals:
        limitsabs = limits .* M_FR.fs.v;

        % for every part of frequency range 0 to nyquist range:
        for j = 1:numel(limits) - 1
            idx = and(f_rel >= limits(j), f_rel <= limits(j+1));
            x = f_rel(idx);
            y = FR.v(idx);
            % make polynomial fit
            [P{j} S{j} MU{j}] = polyfit(x, y, min(numel(y), max_pol_degree) );
        end
        % Create output structure
        piecewise_fit.fit.limits = limitsabs;
        piecewise_fit.fit.max_pol_degree.v = max_pol_degree;
        piecewise_fit.fit.polP = P;
        piecewise_fit.fit.polS = S;
        piecewise_fit.fit.polMU = MU;
    else
        error(sprintf('piecewise_FR_fit: unknown method `%s`!', method))
    end % if method


    % Verbose plots %<<<1
    if verbose
        % make number of fit points 10x the number of measurement points 
        % XXX 2DO
            % c15fitvalues{i} = polyval(c15P{i}, c15x, c15S{i}, c15MU{i});
            % c15rms(i) = sum(sqrt(mean((c15fitvalues{i} - c15y).^2)));
        fit_line_x = linspace(0, f_max_rel, 10*numel(f_rel));
        fit_line_x = fit_line_x.*M_FR.fs.v;
        fit_line_y = piecewise_FR_evaluate(piecewise_fit, fit_line_x, M_FR.fs);

        fit_data_y = piecewise_FR_evaluate(piecewise_fit, f.v, M_FR.fs);

        figure()
        hold on
        plot(f.v, FR.v, '-xb');
        plot(f.v, fit_data_y, 'or');
        plot(fit_line_x, fit_line_y, '-r');
        legend('measured result', 'fit at measured data', 'fit line')
        xlabel('measurement frequency (Hz)')
        ylabel('digitizer gain (V/V)')
        % total error:
        idx = not(isnan(fit_data_y));
        err = sum(abs(fit_data_y(idx) - FR.v(idx)))
        title(sprintf('piecewise_FR_fit.m\ntotal error sum(abs((fit - measured))) = %.7g', err), 'interpreter', 'none')
        hold off
    end

end % function fit_FR_piecewise

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
