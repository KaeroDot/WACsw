% -- [M_DC] = G_DC(S_DC, verbose)
% Simulates digitizer gain measurement data. First simulates PJVS signal, than
% applies digitizer nonlineairity. Nonlinearity is simulated as a polynomial of
% applided on the input voltage, with coefficients specified in S_DC.dig_lin.v.
%
% Inputs:
%   S_DC    - Structure with simulation parameters. If empty or not provided,
%             default values will be used. Fields (all as Q.v substructures):
%               .f.v - main signal frequency (Hz), default: 50
%               .A.v - 'triangular' wave amplitude (V), default: 1
%               .ph.v - 'triangular' wave phase (rad), default: 0
%               .L.v - record length (samples), default: 160e3
%               .fs.v - sampling frequency (Hz), default: 4e6
%               .noise.v - signal noise sigma (V), default: 0.05e-6
%               .fseg.v - frequency of PJVS segments (Hz), default: 1000
%               .phseg.v - phase of PJVS segments (rad), default: 0
%               .fm.v - microwave frequency (Hz), default: 70e9
%               .apply_filter.v - apply filter simulating sigma-delta digitizer (bool), default: 1
%               .dig_FSR.v - digitizer full scale range (V), default: 10 V (i.e. -5..5 V)
%               .dig_lin.v - digitizer voltage linearity parameters as input P
%                   into polyval() (e.g. [linear_gain offset]), default: [+1e-8 0 1-1e-6 0]
%   verbose - If nonzero, generates diagnostic plots (optional)
%
% Outputs:
%   M_DC    - Structure containing simulated digitizer gain measurement data
%
% Usage:
%   [M_DC, ~] = G_DC([], 0);
%   [~, ~, ~, DC_fit] = P_DC(M_DC, 0);
%
%   TODO MISSING: digitizer drift

function [M_DC] = G_DC(S_DC, verbose);

    % Check inputs %<<<1
    if ~exist('S_DC', 'var')
        S_DC = struct();
    end
    if isempty(S_DC)
        S_DC = struct();
    end
    if not(isstruct(S_DC))
        error('G_DC: S_DC must be a structure or empty matrix!')
    end
    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    verbose = logical(verbose(1));

    % Set default simulation parameters %<<<1
    % main signal frequency (Hz):
    if ~isfield(S_DC, 'f') || ~isfield(S_DC.f, 'v') || isempty(S_DC.f.v)
        S_DC.f.v = 50;
    end
    % wave amplitude (V):
    if ~isfield(S_DC, 'A') || ~isfield(S_DC.A, 'v') || isempty(S_DC.A.v)
        S_DC.A.v = 1;
    end
    % wave phase (rad):
    if ~isfield(S_DC, 'ph') || ~isfield(S_DC.ph, 'v') || isempty(S_DC.ph.v)
        S_DC.ph.v = 0;
    end
    % record length (samples):
    if ~isfield(S_DC, 'L') || ~isfield(S_DC.L, 'v') || isempty(S_DC.L.v)
        S_DC.L.v = 160e3;
    end
    % sampling frequency (Hz):
    if ~isfield(S_DC, 'fs') || ~isfield(S_DC.fs, 'v') || isempty(S_DC.fs.v)
        S_DC.fs.v = 4e6;
    end
    % signal noise sigma (V):
    if ~isfield(S_DC, 'noise') || ~isfield(S_DC.noise, 'v') || isempty(S_DC.noise.v)
        S_DC.noise.v = 0.05e-6;
    end
    % frequency of PJVS segments (Hz):
    if ~isfield(S_DC, 'fseg') || ~isfield(S_DC.fseg, 'v') || isempty(S_DC.fseg.v)
        S_DC.fseg.v = 1e3;
    end
    % phase of PJVS segments (rad):
    if ~isfield(S_DC, 'phseg') || ~isfield(S_DC.phseg, 'v') || isempty(S_DC.phseg.v)
        S_DC.phseg.v = 0;
    end
    % microwave frequency (Hz):
    if ~isfield(S_DC, 'fm') || ~isfield(S_DC.fm, 'v') || isempty(S_DC.fm.v)
        S_DC.fm.v = 70e9;
    end
    % apply sigma-delta filter (bool):
    if ~isfield(S_DC, 'apply_filter') || ~isfield(S_DC.apply_filter, 'v') || isempty(S_DC.apply_filter.v)
        S_DC.apply_filter.v = 1;
    end
    % FSR - full scale range (V):
    if ~isfield(S_DC, 'dig_FSR') || ~isfield(S_DC.dig_FSR, 'v') || isempty(S_DC.dig_FSR.v)
        S_DC.dig_FSR.v = 10;
    end
    % digitizer linearity parameters (V):
    if ~isfield(S_DC, 'dig_lin') || ~isfield(S_DC.dig_lin, 'v') || isempty(S_DC.dig_lin.v)
        S_DC.dig_lin.v = [+1e-8 0 1-1e-6 0];
    end

    % Basic input validation:
    required_scalar_fields = {'f','A','ph','L','fs','noise','fseg','phseg','fm','apply_filter','dig_FSR'};
    for k = 1:numel(required_scalar_fields)
        key = required_scalar_fields{k};
        if ~isnumeric(S_DC.(key).v) || ~isscalar(S_DC.(key).v) || ~isfinite(S_DC.(key).v)
            error('G_DC: S_DC.%s.v must be a finite numeric scalar.', key)
        end
    end
    if S_DC.f.v <= 0 || S_DC.L.v <= 0 || S_DC.fs.v <= 0 || S_DC.noise.v < 0 || S_DC.fseg.v <= 0 || S_DC.fm.v <= 0 || S_DC.dig_FSR.v <= 0
        error('G_DC: S_DC.f.v, S_DC.L.v, S_DC.fs.v, S_DC.fseg.v, S_DC.fm.v and S_DC.dig_FSR.v must be positive; S_DC.noise.v must be non-negative.')
    end
    S_DC.L.v = round(S_DC.L.v);
    S_DC.apply_filter.v = logical(S_DC.apply_filter.v);

    % Validate digitizer linearity polynomial coefficients:
    if ~isnumeric(S_DC.dig_lin.v) || ~isvector(S_DC.dig_lin.v)
        error('G_DC: S_DC.dig_lin.v must be a numeric vector of polynomial coefficients for polyval().')
    end
    if ~isreal(S_DC.dig_lin.v) || any(~isfinite(S_DC.dig_lin.v))
        error('G_DC: S_DC.dig_lin.v must contain only finite real values.')
    end

    % Simulate measurement %<<<1
    % generate PJVS triangular signal for digitizer gain calibration: %<<<2
    [y, n, Uref, Uref1period, Spjvs, t] = pjvs_triangle_generator(S_DC.fs.v, S_DC.L.v, [], S_DC.f.v, S_DC.A.v, S_DC.ph.v, S_DC.fseg.v, S_DC.phseg.v, S_DC.fm.v, [], 0);

    % Apply digitizer noise and voltage linearity %<<<2
    y_ideal = y;
    if S_DC.noise.v > 0
        y = y + S_DC.noise.v .* randn(size(y));
    end
    % apply digitizer linearity as polynomial:
    y = polyval(S_DC.dig_lin.v , y);

    % Clip output according the FSR: %<<<2
    y(y > S_DC.dig_FSR.v/2) = S_DC.dig_FSR.v/2;
    y(y < -1.*S_DC.dig_FSR.v/2) = -1.*S_DC.dig_FSR.v/2;

    % Set output structure %<<<1
    M_DC.y.v = y;
    M_DC.t.v = t;
    M_DC.Uref1period.v = Uref1period;
    M_DC.fs = S_DC.fs;
    M_DC.fseg = S_DC.fseg;
    M_DC.label.v = 'simulated_DC_measurement';
    M_DC.MRs.v = 0; % no samples masked at start of record
    M_DC.MRe.v = 0; % no samples masked at end of record
    M_DC.PRs.v = 100; % samples masked after change of PJVS step
    M_DC.PRe.v = 100; % samples masked before change of PJVS step

    % Verbose figure %<<<1
    if verbose
        % signals %<<<2
        figure
        hold on
        plot(t, y_ideal, '-k');
        plot(t, y, '-b');
        plot(t, 1e6.*(y - y_ideal), '--r');
        xlabel('time (s)');
        ylabel('samples (V, uV)');
        legend('PJVS (V)', 'digitizer (V)', 'digitizer - PJVS (uV)');
        grid on
        title(sprintf('G_DC.m\nsimulated PJVS signal for digitizer error calibration'), 'interpreter', 'none');
        hold off

        % linearity curve: error vs. voltage %<<<2
        % first find out values and limits so the rectangle with used range of
        % the digitizer can be plotted first (background), then the FSR limit
        % lines (dashed), and finally the linearity curve (foreground)
        % overrange is a small factor to extend the plotted range slightly beyond the FSR limits:
        overrange = 1 + 1e-6;
        % x axis: input voltage (V):
        input_voltage = linspace(-overrange*S_DC.dig_FSR.v/2, +overrange*S_DC.dig_FSR.v/2, 1000);
        % values with digitizer gain error (uV):
        digitizer_output = polyval(S_DC.dig_lin.v, input_voltage);
        digitizer_output(digitizer_output > S_DC.dig_FSR.v/2) = S_DC.dig_FSR.v/2;
        digitizer_output(digitizer_output < -S_DC.dig_FSR.v/2) = -S_DC.dig_FSR.v/2;
        digitizer_error_uv = 1e6 .* (digitizer_output - input_voltage);

        % determine needed plotted ranges first:
        used_range_min_v = min(y_ideal(:));
        used_range_max_v = max(y_ideal(:));
        y_limits = [0.9.*min(digitizer_error_uv(:)), 1.1.*max(digitizer_error_uv(:))];
        if y_limits(1) == y_limits(2)
            % just to be safe:
            y_limits = y_limits + [-1 1];
        end
        fsr_limit_low_v = -S_DC.dig_FSR.v/2;
        fsr_limit_high_v = +S_DC.dig_FSR.v/2;

        % actual figure
        figure
        hold on
          % first plot used digitizer range rectangle (background)
          patch([used_range_min_v used_range_max_v used_range_max_v used_range_min_v], ...
              [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], [0.7 0.7 0.7], ...
              'FaceAlpha', 0.35, 'EdgeColor', 'none');
        % then plot vertical dashed FSR limit lines
        plot([fsr_limit_low_v fsr_limit_low_v], y_limits, '--k');
        plot([fsr_limit_high_v fsr_limit_high_v], y_limits, '--k');
        % and plot linearity curve as last one (foreground)
        plot(input_voltage, digitizer_error_uv, '-b');
        xlabel('input voltage (V)');
        ylabel('digitizer gain error (uV)');
        grid on
        s = 'digitizer linear. polynom. coeffs (x^n...x^0): ';
        s = [s sprintf('%g, ', S_DC.dig_lin.v)];
        s = s(1:end-2); % remove last comma and space
        s = [s '.'];
        title(sprintf('G_DC.m\ndigitizer voltage linearity\n%s', s), 'interpreter', 'none');
        ylim(y_limits);
        legend('range of the digitizer used by the signal', 'digitizer FSR limit low', 'digitizer FSR limit high', 'digitizer gain error', 'location', 'northwest')
        hold off
    end
end % function G_DC

%!test
%! S_DC = struct();
%! S_DC.dig_FSR.v = 10;
%! S_DC.L.v = 160e3;
%! M_DC = G_DC(S_DC, 0);
%! assert(max(M_DC.y.v) <= S_DC.dig_FSR.v/2);
%! assert(min(M_DC.y.v) >= -1.*S_DC.dig_FSR.v/2);
%! assert(numel(M_DC.y.v) == S_DC.L.v);
%! assert(numel(M_DC.t.v) == S_DC.L.v);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
