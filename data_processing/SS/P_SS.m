function [A_rms_full, A_fft_full, y_without_nans] = P_SS(M_SS, FR_fit, CE_fit);
    % ensure nan package is loaded:
    % This should be in some top-layer script XXX
    pkg load nan

    % Check inputs %<<<1
    % XXX check M_SS

    % Correct for cable error and digitizer freqquency response %<<<1
    % direction set to zero to remove errors
    % This takes a looooong time: TODO FIX IMPROVE XXX
    y = apply_CE_FR_on_samples(M_SS, FR_fit, CE_fit, 0, M_SS.verbose.v);

    % Process the waveform %<<<1
    % Calculate constants %<<<2
    % This is strictly coherent method. Anything else will fail drastically.
    % number of steps per one period of pjvs signal:
    steps_in_triangle = M_SS.f_step.v/M_SS.f_envelope.v;
    % number of samples in one triangle period:
    samples_in_triangle = M_SS.fs.v./M_SS.f_envelope.v;
    % how many periods of the triangle waveform in the record?:
    triangles_in_record = numel(M_SS.y.v)./samples_in_triangle;
    % number of samples in one PJVS step:
    samples_in_step = M_SS.fs.v./M_SS.f_step.v;
    % number of samples in one period of the DUT signal:
    samples_in_period = M_SS.fs.v/M_SS.f.v;
    % number of signal periods in one PJVS step:
    signal_periods_in_step = samples_in_step/samples_in_period;

    % Check if values are integer %<<<2
    if fix(steps_in_triangle) ~= steps_in_triangle
        error('P_SS: number of steps in PJVS envelope (triangle) is not integer! %.3f', steps_in_triangle)
    end
    if fix(samples_in_triangle) ~= samples_in_triangle
        error('P_SS: number of samples in PJVS envelope (triangle) is not integer! %.3f', samples_in_triangle)
    end
    if fix(triangles_in_record) ~= triangles_in_record
        error('P_SS: number of PJVS envelope (triangle) periods in record is not integer! %.3f', triangles_in_record)
    end
    if fix(samples_in_step) ~= samples_in_step
        error('P_SS: number of samples in PJVS step is not integer! %.3f', samples_in_step)
    end
    if fix(samples_in_period) ~= samples_in_period
        error('P_SS: number of samples in DUT signal period is not integer! %.3f', samples_in_period)
    end
    if fix(signal_periods_in_step) ~= signal_periods_in_step
        error('P_SS: number of DUT signal periods in PJVS step is not integer! %.3f', signal_periods_in_step)
    end
    % Check sufficient number of samples to be removed in PJVS step:
    if M_SS.Rs.v + M_SS.Re.v > samples_in_step
        error(sprintf('P_SS: not enough samples to be removed in PJVS step! Rs: %d, Re: %d, samples in step: %d', M_SS.Rs.v, M_SS.Re.v, samples_in_step))
    end

    % Estimate votlage limit needed to cover whole signal by subsampling %<<<2
            % XXX where to get the amplitude of uknown DUT signal?!!!
            % limit = 2.*A./steps_in_triangle;
            % XXX TODO This results in bad value, because it takes into account
            % only steps, not actual dut voltage, thus for largest step it does
            % not cover whole peak of waveform because steps can be calculated
            % insufficiently.
            % limit = mode(abs(diff(M_SS.Upjvs.v)))./2;
    limit = 0.1; % based on tests by PTB & Supracon.

    % Replace data with too high absolute voltage by NaN %<<<2
    % (thus remove samples too much influenced by digitizer gain)
    idx = not(and(y <= limit, y > -1.*limit));
    if M_SS.verbose.v y_corrected = y; end % save data for plotting if needed
    y = y;
    y(idx) = NaN;
    % Check that at least some data are not NaN after applying the limit:
    if all(isnan(y))
        error('P_SS: all samples are NaN after applying voltage limit! Limit: %.7f V, samples in triangle: %d, triangle periods in record: %d, samples range: %.3f - %.3f V.',
        limit,
        samples_in_triangle,
        triangles_in_record,
        min(y),
        max(y))
    end

    % Replace data at start and end of PJVS step transtions by NaN %<<<2
    y = reshape(y, samples_in_step, [])';
    % Now every row is data from a single PJVS step.
    % Remove transients:
    y(:, 1 : M_SS.Rs.v) = NaN;
    y(:, end - M_SS.Re.v + 1 : end) = NaN;
    % save data for plotting if needed:
    if M_SS.verbose.v y_filtered_no_pjvs = y; end

    % Remove PJVS voltages from the whole signal %<<<2
    y = y - repmat(M_SS.Upjvs1period.v(:), triangles_in_record, 1);
    % save data for plotting if needed
    if M_SS.verbose.v y_filtered_w_pjvs = y; end

    % Calculate results from whole data %<<<2
    y_reconstructed = mean(y, 1);
    A_rms_full = sqrt(mean(y_reconstructed.^2));
    % remove nans to calculate FFT:
    y_without_nans = mean(y_reconstructed, 1);
    y_without_nans(isnan(y_without_nans)) = [];
    [F_full, AMP_full, ~, ~] = ampphspectrum (y_without_nans, M_SS.fs.v);
    idx_signal = find(F_full == M_SS.f.v);
    A_fft_full = AMP_full(idx_signal);
    [~, idx_signal_max] = max(AMP_full);
    if idx_signal ~= idx_signal_max
        warning('P_SS: signal frequency %.3f Hz is not the maximum in FFT spectrum! Maximum is at %.3f Hz.', M_SS.f.v, F_full(idx_signal_max))
    end

    % Calculate results from triangle by triangle %<<<2
    % Reshape back to vector:
    y = reshape(y', 1, []);
    % For every triangle period:
    for p = 1:triangles_in_record
        % Cut out one triangle period:
        y_triangle_period = y(samples_in_triangle .* (p-1) + 1 : samples_in_triangle .* p);
        % reshape and calculate average of single DUT period:
        y_triangle_period = reshape(y_triangle_period, samples_in_period, []);
        y_avg = mean(y_triangle_period, 2);
        y_std = std(y_triangle_period, 0, 2);
        % reconstructed time of the averaged period:
        t = [0 : 1 : numel(y_avg) - 1]'./M_SS.fs.v;

        % Calculate amplitude
        % amplitude from RMS:
        A_rms(p) = sqrt(mean(y_avg .^ 2));
    end % for p = 1:trianginrecord

    % Verbose info and figure %<<<1
    if M_SS.verbose.v
        % some informations %<<<2
        res = '';
        res = [res sprintf('--- %s, %s ---\n', M_SS.label.v, datestr(now, 'yyyy-mm-dd HH:MM:SS'))];
        res = [res sprintf('P_SS verbose informations:\n')];
        res = [res sprintf('applied limit (V): %.7f\n', limit)];
        res = [res sprintf('number of steps in one PJVS triangle period: %.3f\n', steps_in_triangle)];
        res = [res sprintf('number of samples in one PJVS triangle period: %.3f\n', samples_in_triangle)];
        res = [res sprintf('number of PJVS triangles in record: %.3f\n', triangles_in_record)];
        res = [res sprintf('number of samples in one PJVS step: %d\n', samples_in_step)];
        res = [res sprintf('number of samples in one DUT signal period: %d\n', samples_in_period)];
        res = [res sprintf('number of DUT signal periods in one PJVS step: %.3f\n', signal_periods_in_step)];
        res = [res sprintf('RMS amplitude based on the whole record (V): %.7f\n', A_rms_full)];
        res = [res sprintf('RMS amplitude by triangles (V):\n')];
        res = [res sprintf('%s\n', mat2str(A_rms, 7))];
        res = [res sprintf('FFT amplitude based on the whole record (V): %.7f\n', A_fft_full)];
        disp(res)
        fid = fopen(fullfile(M_SS.output_path.v, [M_SS.label.v '_result.txt']), 'w');
        fdisp(fid, res);
        fclose(fid);
    end % if M_SS.verbose.v

    if M_SS.plot.v > 0
        % overview plots %<<<2
        % reconstructed whole waveform:
        figure('visible', M_SS.plot_visible.v)
        hold on
        tmpt = [0 : 1 : size(y_reconstructed, 2) - 1]./M_SS.fs.v;
        % plot averaged waveform and standard deviation of the averaged waveform:
        ax = plotyy(tmpt, y_reconstructed, tmpt, 1e6.*std(y_filtered_w_pjvs, 0, 1));
        legend('signal', 'std')
        xlabel('t, reconstructed (s)')
        ylabel(ax(1), 'signal voltage (V)')
        ylabel(ax(2), 'signal std (uV)')
        title(sprintf('P_SS.m, reconstructed subsampled signal (overlaps averaged)\nall signal periods (%g) in single PJVS step, from whole record\nA_rms_full = %.7f', signal_periods_in_step, A_rms_full), 'interpreter', 'none')
        saveas(gcf(), fullfile(M_SS.output_path.v, [M_SS.label.v '_reconstructed_averaged.png']))
        saveas(gcf(), fullfile(M_SS.output_path.v, [M_SS.label.v '_reconstructed_averaged.fig']))
        hold off
    end % if M_SS.plot.v > 0

    if M_SS.plot.v > 1
        % reconstructed averaged waveform:
        figure('visible', M_SS.plot_visible.v)
        hold on
        % plot averaged waveform and standard deviation of the averaged waveform:
        ax = plotyy(t, y_avg, t, 1e6.*y_std);
        xlabel('t, reconstructed (s)')
        ylabel(ax(1), 'signal voltage (V)')
        ylabel(ax(2), 'signal std (uV)')
        legend('signal', 'std')
        title(sprintf('P_SS.m, reconstructed subsampled signal (overlaps averaged)\naveraged to single signal period, from last PJVS triangle\nA_rms = %.7f', A_rms(p)), 'interpreter', 'none')
        saveas(gcf(), fullfile(M_SS.output_path.v, [M_SS.label.v '_reconstructed_averaged_to_single_period.png']))
        saveas(gcf(), fullfile(M_SS.output_path.v, [M_SS.label.v '_reconstructed_averaged_to_single_period.fig']))
        hold off

        % signal in last triangle period:
        figure('visible', M_SS.plot_visible.v)
        hold on
        % last triangle period of the original signal:
        tmpt = M_SS.t.v(samples_in_triangle .* (p-1) + 1 : samples_in_triangle .* p);
        % here are real samples, not corrected!
        tmpy = y_corrected(samples_in_triangle .* (p-1) + 1 : samples_in_triangle .* p);
        plot(tmpt, tmpy, '-b', 'linewidth', 2, 'displayname', 'samples')
        % filtered signal:
        tmpy = reshape(y_filtered_no_pjvs', 1, []);
        tmpy = tmpy(samples_in_triangle .* (p-1) + 1 : samples_in_triangle .* p);
        plot(tmpt, tmpy, '-r', 'linewidth', 2, 'displayname', 'samples in voltage limit and Rs, Re ')
        % signal without PJVS steps and transients:
        plot(tmpt, y_triangle_period(:)', '-g', 'linewidth', 2, 'displayname', 'samples (in limits, Rs, Re) without PJVS steps')
        xlabel('time (s)')
        ylabel('voltage (V)')
        legend()
        title(sprintf('P_SS.m\nsignals in last triangle period\nvoltage limit = %g, Rs = %d, Re = %d', limit, M_SS.Rs.v, M_SS.Re.v), 'interpreter', 'none')
        saveas(gcf(), fullfile(M_SS.output_path.v, [M_SS.label.v '_signals_in_last_triangle.png']))
        saveas(gcf(), fullfile(M_SS.output_path.v, [M_SS.label.v '_signals_in_last_triangle.fig']))
        hold off

        % FFT spectrum of the averaged signal:
        figure()
        hold on
        % this part is only to prevent warning about loglog with negative
        % values:
        tmpf = F_full;
        tmpf(tmpf <= 0) = NaN;
        tmpy = AMP_full;
        tmpy(tmpy <= 0) = NaN;
        loglog(tmpf, tmpy, '-k', 'displayname', 'spectrum')
        xlabel('frequency (Hz)')
        ylabel('amplitude (V)')
        legend()
        title(sprintf('P_SS.m, FFT spectrum\nof reconstructed subsampled signal (overlaps averaged)\nA_fft_full = %.7f', A_fft_full), 'interpreter', 'none')
        saveas(gcf(), fullfile(M_SS.output_path.v, [M_SS.label.v '_spectrum_of_reconstructed.png']))
        saveas(gcf(), fullfile(M_SS.output_path.v, [M_SS.label.v '_spectrum_of_reconstructed.fig']))
        hold off
    end % if M_SS.plot.v > 1

end % function P_SS

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
