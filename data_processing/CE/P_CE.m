function [CE_fit] = P_CE(M_CE, FR_fit, verbose);
    % calcualte ratio, relate to lowest frequency, fit by line equation, display error at 100 kHz.


    % % ensure nan package is loaded:
    % % This should be in some top-layer script XXX
    % pkg load nan
    %
    % Check inputs %<<<1
    % XXX check M_CE
    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Reshape data %<<<1
    % check data are correct
    % suppose first measurement is for l_PJVS, every second measurement is for l_short
    % reshape measurement points
    % (first collumn will be l_PJVS frequency, second collumn will be l_short frequency)
    f = reshape(M_CE.f.v, 2, [])'; % signal frequencies
    t = reshape(M_CE.t.v, 2, [])'; % time of reading
    A = reshape(M_CE.A.v, 2, [])'; % amplitude as measured by digitizer, already corrected for digitizer FR

    % Correct for digitizer frequency response %<<<1
    % evaluate FR fit at measurement frequencies:
    % Evaluate FR fit for fft frequencies:
    fitfreqs = piecewise_FR_evaluate(FR_fit, f, M_CE.fs);
    % Get inverse values to achieve compensation of the digitizer frequency response:
    fitfreqs = -1.*(fitfreqs - 1) + 1;
    % Get corrected amplitudes:
    A = A .* fitfreqs;

    % Calculate cable error %<<<1
    % simplest case - suppose impedance of PJVS is Z_s ≈ 0, DUT is of high
    %TODO: more complex case even for higher frequencies.
    M_CE.L.v = M_CE.l_PJVS.v - M_CE.l_short.v; % length difference (m)
    % Make the fit:
    CE_fit = curve_CE_fit(f(:, 1), A(:, 2) - A(:, 1), M_CE);

    % plot figures if verbose %<<<1
    if verbose
        % fit at measurement points:
        fit_data_y = curve_CE_evaluate(CE_fit, f(:, 1));
        % fit for 10x multiple points to make a line:
        fit_line_x = linspace(min(f(:, 1)), max(f(:, 1)), 10*numel(f(:, 1)));
        fit_line_y = curve_CE_evaluate(CE_fit, fit_line_x);

        figure;
        hold on;
        plot(f(:, 1), 1e6.*(A(:, 2) - A(:, 1)), 'bo', 'DisplayName', 'Measured cable error');
        plot(f(:, 1), 1e6.*fit_data_y, 'r*', 'DisplayName', 'Fitted cable error at measurement points');
        plot(fit_line_x, 1e6.*fit_line_y, 'k-', 'DisplayName', 'Fitted cable error line');
        xlabel('Frequency (Hz)');
        ylabel('Cable error (uV)');
        title(sprintf('P_CE.m\nCable error vs frequency'), 'interpreter', 'none');
        legend('show');
        grid on;
    end % if verbose

end % function P_CE

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
