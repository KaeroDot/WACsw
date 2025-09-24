function [A_rms, A_fft, t_sorted, y] = P_CE(M_CE, piecewise_fit, verbose);
    calcualte ratio, relate to lowest frequency, fit by line, display error at
    100 kHz.

    % % ensure nan package is loaded:
    % % This should be in some top-layer script XXX
    % pkg load nan
    %
    % % Check inputs %<<<1
    % % XXX check M_SS
    % if ~exist('verbose', 'var')
    %     verbose = [];
    % end
    % if isempty(verbose)
    %     verbose = 0;
    % end
    % % ensure verbose is logical:
    % verbose = ~(~(verbose));
    %
    % % Correct for digitizer frequency response %<<<1
    % % Build frequency vector (spacing is df=fs/N):
    % N = numel(M_SS.y.v);
    % % XXX suppose even number of samples!
    % f = M_SS.fs.v./N.*[0:N/2 - 1];
    % % Evaluate FR fit for fft frequencies:
    % fitfreqs = piecewise_FR_evaluate(piecewise_fit, f, M_SS.fs);
    % % Get inverse values to achieve compensation of the digitizer frequency response:
    % fitfreqs = -1.*(fitfreqs - 1) + 1;
    % % Construct the whole filter for both negative and positive frequencies:
    % % XXX is the filter correct? most probably yes!
    % % XXX what if numel(F) is odd number?!
    % fftfilter = [fitfreqs conj(fliplr(fitfreqs))];
    % % Calculate fft:
    % F = fft(M_SS.y.v);
    % % Apply filter:
    % F = F.*fftfilter;
    % % Calculate inverse fft
    % y_filtered = real(ifft(F));
    %
    % % Process waveform %<<<1
    % % This is strictly coherent method. Anything else will fail drastically.
    % % number of steps per one period of pjvs signal:
    % steps_in_envelope = M_SS.f_step.v/M_SS.f_envelope.v;
    % % number of samples in one triangle period:
    % samplesintriangle = M_SS.fs.v./M_SS.f_envelope.v;
    % % how many periods of the triangle waveform in the record?:
    % trianginrecord = numel(y_filtered)./samplesintriangle;
    %                     % check if everything here is integer! XXX
    % % votlage limit needed to cover whole signal by subsampling:
    %         % XXX where to get the amplitude of uknown DUT signal?!!!
    %         % limit = 2.*A./steps_in_envelope;
    % limit = mode(abs(diff(M_SS.Upjvs.v)))./2;
    % % Cut out data with too high voltage (thus remove samples too much
    % % influenced by digitizer gain)
    % idx = not(and(y_filtered <= limit, y_filtered > -1.*limit));
    % y_usefull = y_filtered;
    % y_usefull(idx) = NaN;
    % % XXX here should come some check that at least some data are not NaN. Or maybe later when split by PJVS steps?
    %
    % % for every triangle period:
    % for p = 1:trianginrecord
    %     % Cut out one triangle period:
    %     y = y_usefull(samplesintriangle .* (p-1) + 1 : samplesintriangle .* p);
    %
    %     % Split data by PJVS steps
    %     samples_in_step = M_SS.fs.v./M_SS.f_step.v;
    %     y = reshape(y, samples_in_step, [])';
    %     % Now every row is data from a single PJVS step.
    %     % Remove PJVS voltages:
    %     y = y - M_SS.Upjvs.v(:);
    %
    %     % Remove transients:
    %     if M_SS.Rs.v + M_SS.Re.v > size(y, 2)
    %         error(sprintf('P_SS: not enough samples to be removed in PJVS step! Rs: %d, Re: %d, samples in step: %d', M_SS.Rs.v, M_SS.Re.v, numel(y{j})))
    %     end
    %     if M_SS.Rs.v > 0
    %         y = y(:, M_SS.Rs.v + 1 : end);
    %     end
    %     if M_SS.Re.v > 0
    %         y = y(:, 1 : end - M_SS.Re.v);
    %     end
    %
    %     % Average all periods in a PJVS step into one period (that is reshape every
    %     % step so every matrix row contains only single period)
    %     samples_in_period = M_SS.fs.v/M_SS.f.v;
    %     y = reshape(y', samples_in_period, []);
    %     % Now average over collumns:
    %     y_avg = mean(y, 2);
    %     y_std = std(y, 0, 2);
    %     % time of the averaged period:
    %     t = [0 : 1 : numel(y_avg) - 1]'./M_SS.fs.v;
    %
    %     % Calculate amplitude %<<<1
    %     % amplitude from RMS:
    %     A_rms(p) = sqrt(mean(y_avg .^ 2)) .* sqrt(2);
    %     % amplitude from FFT:
    %     % [tmp1, tmp2] = ampphspectrum(y_avg, M_SS.fs.v, verbose, 'log'); % XXX this verbose cause two plots per every period!
    %     [tmp1, tmp2] = ampphspectrum(y_avg, M_SS.fs.v, 0, 'log'); % XXX this verbose cause two plots per every period!
    %     A_fft(p) = max(tmp2); % not the best idea! find proper frequency bin! XXX
    % end % for p = 1:trianginrecord
    %
    % % Verbose info and figure %<<<1
    % if verbose
    %     % print out some information for last triangle period:
    %     disp('---')
    %     disp('P_SS verbose informations:')
    %     printf('calculated limit: %.7f\n', limit)
    %     printf('mean of amplitudes calculated from RMS value of limited samples: %.7f\n', mean(A_rms))
    %     yf = reshape(M_SS.y.v, samples_in_step, [])';
    %     % XXX quick fix for multiple periods:
    %     periods_in_record = numel(yf)./samplesintriangle;
    %     yf = yf - repmat(M_SS.Upjvs.v(:), periods_in_record, 1);
    %     tmp = sqrt(mean([yf(:)].^2)).*sqrt(2);
    %     printf('RMS value of all samples: %.7f\n', tmp)
    %
    %     % overview plots
    %     % make plots for last triangle period
    %     figure()
    %     hold on
    %     errorbar(t, y_avg, y_std, '#~-x')
    %     xlabel('time (s)')
    %     ylabel('voltage (V)')
    %     title(sprintf('P_SS.m\naveraged subsampled waveform'), 'interpreter', 'none')
    %     hold off
    %
    %     % XXX an image with std of the averaged waveform, and number of points used to average, could be very usefull
    %
    %     % is it usefull anymore?:
    %             % figure()
    %             % hold on
    %             % plot(yf,'.r')
    %             % hold off
    %             % xlabel('sample count')
    %             % ylabel('voltage (V)')
    %             % title(sprintf('P_SS.m\nDUT signal (samples withjjt PJVS steps)'), 'interpreter', 'none')
    % end % if verbose
    %
end % function P_CE

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
