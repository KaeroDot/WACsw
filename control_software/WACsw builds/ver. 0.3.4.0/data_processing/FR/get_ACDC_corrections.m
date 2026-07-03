% -- [acdc_diff acdctransfer] = get_ACDC_corrections(M_FR)
% -- [acdc_diff acdctransfer] = get_ACDC_corrections(M_FR, verbose)
% Loads AC/DC transfer standard data and corrects the measured data for errors
% of the AC/DC transfer standard.
%    Inputs:
%      M_FR - structure with frequency response measurement.
%      verbose - if nonzero, a figure with results will be plotted.
%
%    Outputs:
%      acdc_diff - AC/DC corrections for each reading in M_FR
%      acdctransfer - structure with all data for AC/DC transfer standard
%
%    Example:
%      [acdc_diff acdctransfer] = get_ACDC_corrections(G_FR(), 1);

function [acdc_diff acdctransfer] = get_ACDC_corrections(M_FR, verbose)
    % Check inputs %<<<1
    if not(isstruct(M_FR))
        error('correct_M_FR_for_ACDC: first input must be a structure!')
    end

    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));
    if not(exist(M_FR.acdc_corrections_path.v, 'file'))
        error('get_ACDC_corrections: no AC/DC transfer standard corrections file specified or found! Please specify a valid file with corrections in M_FR.acdc_corrections_path.v.')
    end

    % Load and interpolate AC/DC transfer standard data %<<<1
    % load acdc transfer standard data
    acdctransfer = correction_load_acdctransfer(M_FR.acdc_corrections_path.v);
    % calculate rms amplitudes because AC/DC correction file is in rms:
    amplitudes_rms = M_FR.A.v.*sqrt(2);
    % interpolate
    tbl = correction_interp_table(acdctransfer.acdc_diff, M_FR.A.v, M_FR.f.v, '', '', 'linear');
    % reshape ACDC errors to proper size:
    acdc_diff = reshape(tbl.acdc_diff, size(M_FR.A.v, 1), []);
    % check output
    if any(isnan(acdc_diff))
        warning('correct_M_FR_for_ACDC: Interpolation of AC/DC errors returned NaN values. Check the AC/DC transfer standard file if it covers all measured values.');
        warning('correct_M_FR_for_ACDC: NaN values will be replaced with zero (no correction).');
        idx = isnan(acdc_diff);
        acdc_diff(idx) = 0; % set NaN to zero
    else
        idx = false(size(acdc_diff));
    end
    % apply errors
    M_FR.A.v = M_FR.A.v.*(1 + acdc_diff);

    % Plot corrections if verbose %<<<1
    if verbose
        figure;
        hold on;
        plot(M_FR.f.v(not(idx)), 1e6.*acdc_diff(not(idx)), 'bx');
        plot(M_FR.f.v(idx),      1e6.*acdc_diff(idx),      'ro');
        hold off;
        xlabel('Frequency (Hz)');
        ylabel('AC/DC correction (uV/V)');
        title(sprintf('correct_M_FR_for_ACDC\napplied AC/DC corrections using file:\n"%s"', M_FR.acdc_corrections_path.v), 'interpreter', 'none');
        legend('value interpolated using data from the file', 'value causing NaN in interpolation and set to 0');
        grid on;
    end
end % function

% Test case for correct_M_FR_for_ACDC function %<<<1
%!test
%! M_FR.f.v = [100, 1000]; % Frequency in Hz
%! M_FR.A.v = [1, 1]; % Frequency in Hz
%! expected_result = [10e-6, 0];
%! M_FR.acdc_corrections_path.v = 'acdc_standard_data/dummy_acdc_standard/dummy_acdc.info';
%! [acdc_diff acdctransfer] = get_ACDC_corrections(M_FR);
%! assert(acdc_diff, expected_result, 0.001e-6);
