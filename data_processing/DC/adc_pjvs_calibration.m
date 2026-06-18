% Calculate ADC offset and gain from sampled PJVS signal.
% The function does a linear fit by calling algorithm wlsfit as part of QWTB. If
% this fails, a fallback wlsfit is used, however this fallback algorithm was not
% validated.
%
% Inputs:
% Uref  - PJVS reference voltages for segments (V), numeric vector.
% s_mean - Measured segment means (V), numeric vector, same size as Uref.
% s_uA  - Standard uncertainties of segment means (V), numeric vector,
%         same size as Uref, non-negative.
% dbg   - Optional debug structure. If missing/empty, debugging is disabled
%         (dbg.v = 0).
%
% Outputs:
% cal - Calibration result structure. If qwtb/wlsfit is not available, a local
%       not-validated weighted least-squares fallback is used.
%   cal.coefs.v = beta coefficients of the fit [offset gain].
%   cal.coefs.u = coefficients uncertainties (sqrt(diag(covb))).
%   cal.exponents.v = exponents of the polynomial used to fit.
%   cal.func.v = function of the fit.
%   cal.model.v = string, description of the used model.
%   cal.yhat.v = fitted values at the input Uref points.
%   cal.yhat.u = uncertainties of the fitted values.

function [cal] = adc_pjvs_calibration(Uref, s_mean, s_uA, dbg)
    % check inputs %<<<1
    if nargin < 3
        error('adc_pjvs_calibration: at least 3 inputs are required: Uref, s_mean, s_uA');
    end
    if nargin < 4 || isempty(dbg)
        dbg = struct();
        dbg.v = 0;
    end

    if ~isnumeric(Uref) || ~isvector(Uref)
        error('adc_pjvs_calibration: `Uref` must be a numeric vector');
    end
    if ~isnumeric(s_mean) || ~isvector(s_mean)
        error('adc_pjvs_calibration: `s_mean` must be a numeric vector');
    end
    if ~isnumeric(s_uA) || ~isvector(s_uA)
        error('adc_pjvs_calibration: `s_uA` must be a numeric vector');
    end

    if numel(Uref) ~= numel(s_mean) || numel(Uref) ~= numel(s_uA)
        error('adc_pjvs_calibration: `Uref`, `s_mean`, and `s_uA` must have the same number of elements');
    end
    if any(~isfinite(Uref)) || any(~isfinite(s_mean)) || any(~isfinite(s_uA))
        error('adc_pjvs_calibration: input vectors must contain finite values only');
    end
    if any(s_uA < 0)
        error('adc_pjvs_calibration: `s_uA` must be non-negative');
    end

    % use row vectors to avoid orientation issues in fitting and plotting
    Uref = Uref(:).';
    s_mean = s_mean(:).';
    s_uA = s_uA(:).';

    % debug defaults
    if ~isstruct(dbg)
        error('adc_pjvs_calibration: `dbg` must be a structure');
    end
    if ~isfield(dbg, 'v') || isempty(dbg.v)
        dbg.v = 0;
    end
    dbg.v = ~(~dbg.v);

    % initialize %<<<1
    PRef = [];
    C = [];
    uC = [];
    plot_Uref = [];

    PRef = Uref;
    C = s_mean;
    uC = s_uA;

    % sort data based on x axis? is it needed? CCC does it or not?

    % calculate calibration curve %<<<1
    if numel(PRef) < 2
        % no or only one suitable step found, return empty result:
        warning(['adc_pjvs_calibration: found ' num2str(numel(PRef)) ...
                 ' PJVS steps. Cannot fit by line.']);
        cal.coefs = [];
        cal.exponents = [];
        cal.func = [];
        cal.model = [];
        cal.yhat = [];
        cal.yhat.v = [];
        cal.yhat.u = [];
    else
        % at least two steps found, can fit by line:
        DI.x.v = PRef;
        DI.y.v = C;
        DI.y.u = uC;

        % Fitting using wlsfit if available; otherwise use a simple weighted
        % least-squares fallback that keeps the script self-contained.
        DI.n.v = 1; % order of the polynomial to fit
        if exist('qwtb', 'file') == 2
            try
                cal = qwtb('wlsfit', DI);
            catch
                warning('adc_pjvs_calibration: algorithm wlsfit or QWTB failed, probably not found, using fallback method.')
                cal = local_wlsfit_fallback(DI);
            end
        else
            cal = local_wlsfit_fallback(DI);
        end

        % Another possibility: Fitting using CCC:
        % DI.exponents.v = [0 1];
        % cal = qwtb('CCC', DI);
        
        % Old method: fitting using polyfit:
        % [P, S] = polyfit(DI.x.v, DI.y.v, 1);
        % cal.coefs.v = [P(2) P(1)]; % proper coefficients order, first one have to be offset, the second gain
        % cal.coefs.u = 1e-6.*ones(size(P)); % this is not correct uncertainty!
        % cal.exponents.v = [0 1];
        % cal.func.v = [];
        % cal.model.v = 'Ordinary Least Squares using polyfit function';
        % [cal.yhat.v cal.yhat.u] = polyval(P, DI.x.v, S);
    end

    % debug plot fit data and fit result %<<<1
    if dbg.v
        ssec = sprintf('%03d-%03d_', dbg.section(1), dbg.section(2));
        tmpy = cal.coefs.v(1) + DI.x.v.*cal.coefs.v(2);

        if dbg.adc_calibration_fit
            figure('visible',dbg.showplots)
            hold on
                plot(DI.x.v, DI.y.v,'xb')
                % XXX make this general polynom
                plot(DI.x.v, tmpy, '-r')
                legend('Segment averages', 'Linear fit', 'location', 'southeast')
                xlabel('PJVS reference voltage (V)')
                ylabel('Segment average (V)')
                title(sprintf('Digitizer calibration, section %03d-%03d\n%d segment averages', dbg.section(1), dbg.section(2), numel(DI.y.v)), 'interpreter', 'none')
            hold off
            fn = fullfile(dbg.plotpath, [ssec 'adc_calibration_fit']);
            if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
            if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
            close
        end % if dbg.adc_calibration_fit

        if dbg.adc_calibration_fit_errors
            % plot fit errors
            figure('visible',dbg.showplots)
            hold on
                plot(DI.x.v, 1e6.*(DI.y.v - tmpy),'xb')
                xlabel('PJVS reference voltage (V)')
                ylabel('Segment average: error from linear fit (uV)')
                title(sprintf('Digitizer calibration, section %03d-%03d\nfit errors of %d segment averages', dbg.section(1), dbg.section(2), numel(DI.y.v)), 'interpreter', 'none')
            hold off
            fn = fullfile(dbg.plotpath, [ssec 'adc_calibration_fit_errors']);
            if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
            if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
            close
        end % if dbg.adc_calibration_errors

        if dbg.adc_calibration_fit_errors_time
            % plot fit errors versus segment number
            figure('visible',dbg.showplots)
            hold on
                plot(1e6.*(DI.y.v - tmpy),'xb')
                xlabel('PJVS segment index')
                ylabel('Segment average: error from linear fit (uV)')
                title(sprintf('Digitizer calibration, section %03d-%03d\nfit errors of %d segment averages', dbg.section(1), dbg.section(2), numel(DI.y.v)) , 'interpreter', 'none')
            hold off
            fn = fullfile(dbg.plotpath, [ssec 'adc_calibration_fit_errors_time']);
            if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
            if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
            close
        end % if dbg.adc_calibration_fit_errors_time
    end % if dbg.v

end % function

function cal = local_wlsfit_fallback(DI)
    x = DI.x.v(:);
    y = DI.y.v(:);
    if isfield(DI.y, 'u') && ~isempty(DI.y.u)
        sigma = DI.y.u(:);
        sigma(sigma <= 0) = 1;
        w = 1 ./ (sigma .^ 2);
    else
        w = ones(size(y));
    end

    X = [ones(size(x)), x];
    W = diag(w);
    beta = (X' * W * X) \ (X' * W * y);
    yhat = X * beta;
    dof = max(numel(y) - 2, 1);
    residual = y - yhat;
    mse = sum(w .* residual .^ 2) / dof;
    covb = inv(X' * W * X) * mse;

    cal.coefs.v = beta.';
    cal.coefs.u = sqrt(diag(covb)).';
    cal.exponents.v = [0 1];
    cal.func.v = [];
    cal.model.v = 'Weighted least-squares fallback';
    cal.yhat.v = yhat;
    cal.yhat.u = zeros(size(yhat));
end

% demo %<<<1
%!demo
%! % Demo will generate a triangular stepwise PJVS signal with small digitizer errors and calibration it.
%! % Generate signal:
%! L = 100; % total number of digitizer samples
%! [y, n, Uref, Upjvs1period, Spjvs, tsamples] = pjvs_triangle_generator(100e3, L, [], 1e3, 1, 0, 20e3, 0, 75e9, 2, 0);
%!
%! % Add gain and offset of the digitizer and measurement noise:
%! % Fixed RNG seed for reproducible demo plot:
%! rand('seed', 1); ! randn('seed', 1);
%! y_meas = (1 + 5e-6) .* y(1:L) + 1e-6 + 1e-6 .* randn(1, L);
%! s_mean = mean(reshape(y_meas, Spjvs(2) - Spjvs(1), numel(Uref)), 1);
%! s_uA = 1e-6 .* ones(size(s_mean));
%!
%! cal = adc_pjvs_calibration(Uref, s_mean, s_uA);
%!
%! figure();
%! hold on;
%! plot(tsamples(1:L), y(1:L), 'xk', 'linewidth', 1.5);
%! plot(tsamples(1:L), y_meas, '+-b', 'linewidth', 1);
%! plot(tsamples(1:L), 1e6.*(y(1:L) - y_meas), '-r', 'linewidth', 1);
%! hold off;
%! xlabel('Time (s)');
%! ylabel('Voltage (V, uV)');
%! title('PJVS reference, measured signal and difference', 'interpreter', 'none');
%! legend('PJVS reference (V)', 'Measured signal (V)', 'Mesured - PJVS (uV)', 'location', 'northwest');
%! grid on;
%!
%! measured_err = 1e6 .* (s_mean - Uref);
%! fitted_err = 1e6 .* ((cal.coefs.v(1) + cal.coefs.v(2) .* Uref) - Uref);
%! figure();
%! hold on;
%! plot(Uref, measured_err, 'xb', 'markersize', 6);
%! plot(Uref, fitted_err, '-r', 'linewidth', 2);
%! hold off;
%! xlabel('PJVS reference voltage (V)');
%! ylabel('Digitizer gain error (uV/V)');
%! title(sprintf('adc_pjvs_calibration demo: offset = %.3g V, gain error = %.1f', cal.coefs.v(1), 1e6.*(cal.coefs.v(2) - 1)), 'interpreter', 'none');
%! legend('Measured digitizer error', 'Linear fit', 'location', 'northwest');
%! grid on;

% tests %<<<1
%!test
%! % Perfect synthetic data should recover unit gain and zero offset.
%! Uref = linspace(-1, 1, 20);
%! s_mean = Uref;
%! s_uA = 1e-6 .* ones(size(Uref));
%! dbg.v = 0;
%! cal = adc_pjvs_calibration(Uref, s_mean, s_uA, dbg);
%! assert(numel(cal.coefs.v), 2);
%! assert(cal.coefs.v(1), 0, 1e-10);
%! assert(cal.coefs.v(2), 1, 1e-10);

%!test
%! % Empty dbg should be accepted and treated as dbg.v = 0.
%! Uref = [-1 0 1];
%! s_mean = Uref;
%! s_uA = 1e-6 .* ones(size(Uref));
%! cal = adc_pjvs_calibration(Uref, s_mean, s_uA, []);
%! assert(numel(cal.coefs.v), 2);

%!test
%! % Single-point input should return empty fit fields.
%! cal = adc_pjvs_calibration(1, 1, 1e-6);
%! assert(isempty(cal.coefs));

%!error adc_pjvs_calibration([1 2 3], [1 2], [1 1 1], struct('v',0))
%!error adc_pjvs_calibration([1 2], [1 2], [1 -1], struct('v',0))
%!error adc_pjvs_calibration([1 NaN], [1 2], [1 1], struct('v',0))
%!error adc_pjvs_calibration([1 2], [1 2], [1 1], 1)
%!error adc_pjvs_calibration('abc', [1 2 3], [1 1 1], struct('v',0))

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
