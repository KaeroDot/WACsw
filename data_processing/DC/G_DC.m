% -- [M_DC] = G_DC(S_DC, verbose)
% Simulates digitizer gain measurement data. First simulates PJVS signal, than
% applies digitizer nonlineairity. Nonlinearity is simulated as an additive
% antisymmetric S-curve: error = nl_amplitude * A * tanh(y / A) 
% At y = A the relative error is nl_amplitude * tanh(1) ~ 0.76 * nl_amplitude.
%
% Inputs:
%   S_DC    - Structure with simulation parameters. If empty or not provided,
%             default values will be used. Fields (all as Q.v substructures):
%               .f.v - main signal frequency (Hz), default: 50
%               .A.v - 'triangular' wave amplitude (V), default: 1
%               .ph.v - 'triangular' wave phase (rad), default: 0
%               .L.v - record length (samples), default: 4e6
%               .fs - sampling frequency (Hz), default: 4e6
%               .noise - signal noise sigma (V), default: 1e-6
%               .fseg - frequency of PJVS segments (Hz), default: 1000
%               .phseg - phase of PJVS segments (rad), default: 0
%               .fm - microwave frequency (Hz), default: 70e9
%               .apply_filter - apply filter simulating sigma-delta digitizer (bool), default: 1
%               .nl_amplitude.v - nonlinearity amplitude (V/V) (peak deviation at full scale), default: 1e-6 uV/V
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
        error('G_DC: S_DC must be a structure!')
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
        S_DC.noise.v = 1e-6;
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
    % nonlinearity amplitude (V/V, antisymmetric S-curve peak relative error at full scale):
    if ~isfield(S_DC, 'nl_amplitude') || ~isfield(S_DC.nl_amplitude, 'v') || isempty(S_DC.nl_amplitude.v)
        S_DC.nl_amplitude.v = 1e-6;
    end

    % Basic input validation:
    required_scalar_fields = {'f','A','ph','L','fs','noise','fseg','phseg','fm','apply_filter','nl_amplitude'};
    for k = 1:numel(required_scalar_fields)
        key = required_scalar_fields{k};
        if ~isnumeric(S_DC.(key).v) || ~isscalar(S_DC.(key).v) || ~isfinite(S_DC.(key).v)
            error('G_DC: S_DC.%s.v must be a finite numeric scalar.', key)
        end
    end
    if S_DC.f.v <= 0 || S_DC.L.v <= 0 || S_DC.fs.v <= 0 || S_DC.noise.v < 0 || S_DC.fseg.v <= 0 || S_DC.fm.v <= 0
        error('G_DC: S_DC.f.v, S_DC.L.v, S_DC.fs.v, S_DC.fseg.v and S_DC.fm.v must be positive; S_DC.noise.v must be non-negative.')
    end
    S_DC.L.v = round(S_DC.L.v);
    S_DC.apply_filter.v = logical(S_DC.apply_filter.v);

    % Simulate measurement %<<<1
    % generate PJVS triangular signal for digitizer gain calibration:
    [y, n, Uref, Uref1period, Spjvs, t] = pjvs_wvfrm_generator(S_DC.f.v, S_DC.A.v, S_DC.ph.v, S_DC.L.v, S_DC.fs.v, S_DC.noise.v, S_DC.fseg.v, S_DC.phseg.v, S_DC.fm.v, S_DC.apply_filter.v);

    % Apply digitizer nonlinearity (additive antisymmetric S-curve) %<<<1
    % dev(y) = nl_amplitude * A * tanh(y / A)
    % Antisymmetric: dev(-y) = -dev(y); S-shaped via tanh.
    % At y = A the peak relative error is nl_amplitude * tanh(1) ~ 0.76 * nl_amplitude.
    y_ideal = y;
    y = y + S_DC.nl_amplitude.v .* S_DC.A.v .* tanh(y ./ S_DC.A.v);

    % Set output structure %<<<1
    M_DC.y.v = y;
    M_DC.Uref1period.v = Uref1period;
    M_DC.fs = S_DC.fs;
    M_DC.fseg = S_DC.fseg;
    M_DC.label.v = 'simulated_DC_measurement';
    M_DC.MRs.v = 0; % no samples masked at start of record
    M_DC.MRe.v = 0; % no samples masked at end of record
    M_DC.PRs.v = 100; % samples masked after change of PJVS step
    M_DC.PRe.v = 100; % samples masked before change of PJVS step
    M_DC.nl_amplitude = S_DC.nl_amplitude;

    % Verbose figure %<<<1
    if verbose
        figure
        hold on
        plot(t, y_ideal, '-b');
        plot(t, y, '-r');
        plot(t, 1e6.*(y - y_ideal), '-r');
        xlabel('time (s)');
        ylabel('samples (V, uV)');
        legend('PJVS', 'with nonlinearity', 'difference');
        grid on
        title(sprintf('G_DC.m\nsimulated PJVS signal for digitizer error calibration'), 'interpreter', 'none');
        hold off

        % nonlinearity curve: deviation vs. voltage
        y_axis = linspace(-S_DC.A.v, S_DC.A.v, 500);
        nl_dev_ppm = 1e6 .* S_DC.nl_amplitude.v .* S_DC.A.v .* tanh(y_axis ./ S_DC.A.v) ./ S_DC.A.v;
        figure
        plot(y_axis, nl_dev_ppm, '-b');
        xlabel('input voltage (V)');
        ylabel('nonlinearity deviation (uV/V)');
        grid on
        title(sprintf('G_DC.m\ndigitizer nonlinearity S-curve (nl\_amplitude = %.3g V/V)', S_DC.nl_amplitude.v), 'interpreter', 'none');
    end
end % function G_CE

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
