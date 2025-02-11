function [A_rms, A_fft, t_sorted, y_sorted] = P_SS(M_SS, verbose);

    % Check inputs %<<<1
    % XXX check M_SS
    if ~exist('verbose', 'var')
        verbose = [];
    end
    if isempty(verbose)
        verbose = 0;
    end
    % ensure verbose is logical:
    verbose = ~(~(verbose));

    % Cut out data with too high voltage (thus too much influenced by digitizer
    % gain):
    % signal meant to be used for processing:
    % number of steps per one period of pjvs signal:
    steps_in_envelope = M_SS.f_step.v/M_SS.f_envelope.v;
    % votlage limit needed to cover whole signal by subsampling:
            % XXX where to get the amplitude of uknown DUT signal?!!!
            % limit = 2.*A./steps_in_envelope;
            % limit = 2.*1./steps_in_envelope;
    limit = mean(abs(diff(M_SS.Upjvs.v)));
    idx = not(and(M_SS.y.v < limit, M_SS.y.v > -1.*limit));
    y_usefull = M_SS.y.v;
    y_usefull(idx) = NaN;
                                                t_usefull = M_SS.t.v;
                                                t_usefull(idx) = NaN;

    % Split data by PJVS steps %<<<1
    % For all PJVS steps, split samples by PJVS step and put data into cells.
    % Must be cells because different step lengths can happen (especially at
    % start and end of the smapled record).
    % XXX check numel(x) does not return 1!
    for j = 1:numel(M_SS.Spjvs.v) - 1
        % indexes from-to of actual PJVS step:
        ids = M_SS.Spjvs.v(j);
        ide = M_SS.Spjvs.v(j + 1) - 1;
        % cell with time samples:
        t{j} = M_SS.t.v(ids : ide);
        % First we calculate time shift to properly align sections one after
        % another:
        t_shift = fix(t{j}(1)/( 1/(2.*M_SS.f_envelope.v) ) )./M_SS.f_step.v;
        % To properly concatenate waveform by time, one has to subtract time
        % delta based on phase of DUT signal. By dividing the actual time shift
        % by period of the DUT signal period we get ratio, and remainder has to
        % be added to keep the correct phase:
        t_fix = rem((t{j}(1) - M_SS.t.v(1)) + t_shift, 1/M_SS.f.v);
        t{j} = t{j} - t{j}(1) + t_shift; % this one puts all onto each other
        % t{j} = t{j} - t{j}(1) + t_fix + t_shift;
        % cell with samples corrected by PJVS voltage:
        y{j} = y_usefull(ids : ide) - M_SS.Upjvs.v(j);
        yf{j} = M_SS.y.v(ids : ide) - M_SS.Upjvs.v(j);

        idx = isnan(y{j});
        y{j}(idx) = [];
        t{j}(idx) = [];


        % remove transients:
        if M_SS.Rs.v > 0
            t{j} = t{j}(M_SS.Rs.v + 1 : end);
            y{j} = y{j}(M_SS.Rs.v + 1 : end);
        end
        if M_SS.Re.v > 0
            t{j} = t{j}(1 : end - M_SS.Re.v);
            y{j} = y{j}(1 : end - M_SS.Re.v);
        end
    end % for j

    % sort data:
    t_sorted = [t{:}];
    [t_sorted, idx] = sort(t_sorted);
    y_sorted = [y{:}];
    y_sorted = y_sorted(idx);

    % check correctness of data:
    tmp = diff(t_sorted);
    if not(all(tmp - tmp(1) < 1e-15))
        disp('---')
        warning('Reconstruction of the subsampled data probably failed. Too large values in differences of the sample times.')
        if verbose
            figure()
            plot(tmp)
            xlabel('index of sorted time samples')
            ylabel('difference (t(n) - t(n-1))')
            title('Differences of sample times after reconstruction and sorting')
        end
    end

    % calculate amplitude from RMS value %<<<1
    A_rms = sqrt(mean(y_sorted.^2)).*sqrt(2);
    [tmp1, tmp2] = ampphspectrum(y_sorted, M_SS.fs.v, verbose);
    A_fft = max(tmp2);

    % Verbose info and figure %<<<1
    if verbose
        % print out some information
        disp('---')
        disp('P_SS verbose informations:')
        printf('Amplitude calculated from RMS value of limited samples: %.7f\n', A_rms)
        tmp = sqrt(mean([yf{:}].^2)).*sqrt(2);
        printf('RMS value of all samples: %.7f\n', tmp)

        % overview plots
        % markers should not be overlapping if reconstruction went well
        figure()
        hold on
        cmap = 'rgbk';
        % mmap = 'o_|sd^v<>><v^ds|_o';
        for j = 1:numel(t);
            plot(t{j}, y{j}, ...
                ['-x' cmap(rem(j, numel(cmap))+1)] ...
                        % [mmap(rem(j, numel(mmap))+1) cmap(rem(j, numel(cmap))+1)], ...
                        % 'markersize', 20 ...
                );
        end
        xlabel('time (s)')
        ylabel('voltage (V)')
        title(sprintf('P_SS.m\nreconstructed subsampled waveform'), 'interpreter', 'none')
        hold off

        figure()
        hold on
        plot([yf{:}],'-xr')
        hold off
        xlabel('sample count')
        ylabel('voltage (V)')
        title(sprintf('P_SS.m\nDUT signal (samples withjjt PJVS steps)'), 'interpreter', 'none')
    end % if verbose

end % function P_SS

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
