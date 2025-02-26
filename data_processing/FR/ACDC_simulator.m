% -- [acdc_difference, dc_voltage] = ACDC_simulator(f)
% -- [acdc_difference, dc_voltage] = ACDC_simulator(f, verbose)
%    Very simple simulator of a Single Junction Thermoconverter (AC/DC transfer
%    standard). Works only from 10 Hz to 10 MHz. Outside the range outputs are set
%    to NaN. AC/DC transfer curve is similar to a real data.
%
%    Missing implementation: voltage dependence `n` as in this equation of AC/DC
%    difference: delta = (U_outAC - U_outDC)./(n.*U_outDC)
%
%    Inputs:
%      f - vector of input measurement frequencies (Hz).
%      verbose - if nonzero, a plot of AC/DC difference is created. optional
%
%    Outputs:
%      acdc_difference - AC/DC difference of the SJTC (V/V)
%      dc_voltage - DC output of the SJTC (V)
%
%    Example:
%      ACDC_simulator(logspace(1, 7, 1e3), 1);

function [acdc_difference, dc_voltage] = ACDC_simulator(f, verbose)
    % Check inputs %<<<1
    if ~isnumeric(f)
        error('ACDC_simulator: input `f` must be numeric.')
    end
    % values below and above limits are set to NaN:
    f(f < 10) = NaN;
    f(f > 1e7) = NaN;

    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Constants %<<<1
    % heating element voltage (V/V):
    % (for DC or rms AC on input of amplitude A, there is dc output A*hev)
    hev = 0.85; % Approximate value for CMI's Fluke 792A temelin

    % Calculate transfer function %<<<1
    % change to log space:
    x = log10(f);
    % Simulate transfer function using double error function:
    % (delta_acdc, log space of frequency, in uV/V)
    func = @(x, p) p(4) + p(3)./(erf(3*p(1)*(x-p(5)+p(2)))-erf(p(1)*(x-p(5)-p(2))));
    % manually estimated coefficients:
    p0 = [0.6, 1.1, 3, -4, 2.5]; % quite ok in range 1 Hz to 10 MHz
    % delta_acdc:
    acdc_difference = func(x, p0);
     % convert from uV to V:
    acdc_difference = acdc_difference .* 1e-6;
    % estimate DC voltage generated by thermoconverter:
    dc_voltage = hev .* (1 + acdc_difference);

    % Verbose figure %<<<1
    if verbose
        figure
        hold on
        semilogx(f, acdc_difference.*1e6, 'o')
        title(sprintf('ACDC_simulator.m\nSimulated AC/DC difference of a thermoconverter'), 'interpreter', 'none')
        xlabel('signal frequency (Hz)')
        ylabel('AC/DC differenece (uV/V)')
        hold off
    end % if verbose

end % function ACDC_simulator

%!demo %<<<1
%! ACDC_simulator(logspace(1, 7, 1e3), 1);

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
