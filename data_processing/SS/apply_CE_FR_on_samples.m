% Applies or removes cable error (CE) and frequency response (FR) to/from
% samples using DFT filtering. CE and FR are represented by structures with
% results of fitting.
% Be sure to properly set direction parameter. direction set to 0 removes the
% effect of CE and FR from samples, set to 1 applies the effect!
%
% Usage:
%   y_filtered = apply_CE_FR_on_samples(M_SS, FR_fit, CE_fit, direction, verbose)
%
% Inputs:
%   M_SS      - Struct with sample data (fields: y.v for samples, t.v for time, fs.v for sampling frequency)
%   FR_fit    - Frequency Response fit, if empty, FR is not applied
%   CE_fit    - Channel Estimator fit, if empty, CE is not applied
%   direction - Logical; true to APPLY effect, false to REMOVE effect of CE and FR
%   verbose   - Logical; if true, plots and warnings are shown (optional)
%
% Output:
%   y_filtered - Filtered sample vector
%

function y_filtered = apply_CE_FR_on_samples(M_SS, FR_fit, CE_fit, direction, verbose)
    % Check inputs %<<<1
    % ensure direction is logical:
    direction = ~(~(direction));
    % verbose:
    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    verbose = ~(~(verbose));

    % Modify samples using DFT filtering %<<<1
    % Build frequency vector (spacing is df=fs/N):
    N = numel(M_SS.y.v);
    % XXX suppose even number of samples!
    f = M_SS.fs.v./N.*[0:N/2 - 1];

    % create DFT filter %<<<1
    % initialize:
    err_rel_total = ones(size(f));
    if not(isempty(FR_fit))
        % Evaluate FR fit for DFT frequencies:
        FR_gain = piecewise_FR_evaluate(FR_fit, f, M_SS.fs);
        if direction
            % add the effect of FR:
            err_rel_total = err_rel_total ./ FR_gain;
        else
            % remove the effect of FR:
            err_rel_total = err_rel_total .* FR_gain;
        end
    else
        FR_gain = ones(size(f));
        if verbose
            warning('apply_CE_FR_on_samples: FR_fit is empty! FR response will not be applied to the samples!')
        end
    end
    % TODO not good - piecewise_FR_evaluate returns 1.000something, but
    % curve_CE_evaluate returns 0.00something
    if not(isempty(CE_fit))
        % Evaluate CE fit for DFT frequencies:
        CE_gain = curve_CE_evaluate(CE_fit, f);
        CE_gain = 1 + CE_gain;
        if direction
            % add the effect of CE:
            err_rel_total = err_rel_total ./ (CE_gain);
        else
            % remove the effect of CE:
            err_rel_total = err_rel_total .* (CE_gain);
        end
    else
        CE_gain = ones(size(f));
        if verbose
            warning('apply_CE_FR_on_samples: CE_fit is empty! CE response will not be applied to the samples!')
        end
    end
    % Construct the whole filter for both negative and positive frequencies:
    % TODO is the filter correct?
    % TODO what if numel(F) is odd number?!
    dftfilter = [err_rel_total conj(fliplr(err_rel_total))];

    % apply DFT filter %<<<1
    % Calculate DFT of the samples:
    F = fft(M_SS.y.v);
    % Apply filter:
    F = F.*dftfilter;
    % Calculate inverse DFT:
    y_filtered = real(ifft(F));
    % Keep old values for plotting if verbose:
    if verbose
        y_old = M_SS.y.v;
    end
    % Return back values:
    M_SS.y.v = y_filtered;

    if verbose %<<<1
        if direction
            direction_str = 'Applying effect of: ';
        else
            direction_str = 'Removing effect of: ';
        end
        if not(isempty(FR_fit))
            direction_str = [direction_str 'FR ,'];
        end
        if not(isempty(CE_fit))
            direction_str = [direction_str 'CE ,'];
        end
        if isempty(FR_fit) && isempty(CE_fit)
            direction_str = [direction_str ' no effect applied!'];
        else
            direction_str = [direction_str(1:end - 2), '.'];
        end

        % plot figure showing full filter in frequency domain %<<<2
        figure;
        hold on
        plot(f, abs(CE_gain), '-b');
        plot(f, abs(FR_gain), '-r');
        plot(f, abs(err_rel_total), '-k', 'linewidth', 2);
        legend('CE fit', 'FR fit', 'Total DFT filter');
        xlabel('Frequency (Hz)');
        ylabel('Filter Magnitude');
        title(sprintf('apply_CE_FR_on_samples.m\nDFT Filter in Frequency Domain\n%s', direction_str), 'interpreter', 'none');
        hold off

        % plot time domain signals %<<<2
        figure;
        hold on
        plot(M_SS.t.v, y_old - M_SS.y.v, '-r');
        legend('filtered - original samples');
        xlabel('Time (s)');
        ylabel('Amplitude (V)');
        title(sprintf('apply_CE_FR_on_samples.m\nDifference between original and filtered samples.\n%s', direction_str), 'interpreter', 'none');
        hold off
    end % if verbose

end % function apply_CE_FR_on_samples

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
