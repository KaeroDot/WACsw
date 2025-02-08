function [] = P_SS(M_SS, verbose);

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
    limit = 2.*1./steps_in_envelope;
    idx = not(and(M_SS.y.v < limit, M_SS.y.v > -1.*limit));
    y_usefull = M_SS.y.v;
    y_usefull(idx) = NaN;
                t_usefull = M_SS.t.v; % XXX not used
                t_usefull(idx) = NaN; % XXX not used

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
        t_fix = rem((t{j}(1) - t{1}(1)) + t_shift, 1/M_SS.f.v);
        t{j} = t{j} - t{j}(1) + t_shift; % this one puts all onto each other
        % t{j} = t{j} - t{j}(1) + t_fix + t_shift;
        % cell with samples corrected by PJVS voltage:
        y{j} = y_usefull(ids : ide) - M_SS.Upjvs.v(j);
        yf{j} = M_SS.y.v(ids : ide) - M_SS.Upjvs.v(j);
        % remove transients:XXX
                    % yf{j}(1:5) = NaN;
                    % yf{j}(end-5:end) = NaN;
    end % for j

    % Verbose info and figure %<<<1
    if verbose
        % print out some information
        disp('---')
        disp('P_SS verbose informations:')
        tmp = sqrt(mean([y{:}].^2)).*sqrt(2);
        printf('RMS value of limited samples: %.7f\n', tmp)
        tmp = sqrt(mean([yf{:}].^2)).*sqrt(2);
        printf('RMS value of all samples: %.7f\n', tmp)
        % overview plots
        % in this figure seems some parts can appear to be missing because the
        % markers are overlapping
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
        hold off
        title(sprintf('P_SS.m\nreconstructed waveform'), 'interpreter', 'none')

        figure()
        hold on
        plot([yf{:}],'-xr')
        hold off
        xlabel('sample count')
        ylabel('voltage (V)')
        title(sprintf('P_SS.m\nDUT signal (samples without PJVS steps)'), 'interpreter', 'none')
    end % if verbose


    % addpath('~/metrologie/Q-Wave/qwtb/qwtb')
    % [DI.t.v, idx] = sort([t{:}]);
    % % DI.t.v = [t{:}];
    % DI.y.v = [y{:}](idx);
    % % plot(DI.t.v,DI.y.v, '-x')
    % DI.fest.v = 1e5;
    % DO = qwtb('FPNLSF', DI);
    % DO.A.v
    %


    % % XXX
    % % plot with phase change: plot([deltat{j}])
    % % good for checking discontinuities
    %
    %                 % XXX check numel(x) does not return 1!
    %                 for j = 1:numel(M_SS.Spjvs.v) - 1
    %                     l = M_SS.Spjvs.v(j);
    %                     r = M_SS.Spjvs.v(j + 1);
    %                     t{j} = M_SS.t.v(l:r);
    %                     y{j} = M_SS.y.v(l:r);
    %                     U{j} = M_SS.Upjvs.v(j);
    %                 end % for j
    %
    %                 outt = [];
    %                 outy = [];
    %                 figure()
    %                 hold on
    %                 for j = 1:numel(t)-1
    %                     % time to subtract has to be based on phase of DUT signal:
    %                     % divide by period:
    %                     % XXX deltat = (t{j}(1) - t{1}(1)).*M_SS.f.v;
    %                     % get remainder:
    %                     deltat = rem((t{j}(1) - t{1}(1)), M_SS.f.v);
    %                     plot(t{j} - t{j}(1) + deltat, y{j} - U{j}, '-k')
    %                     cut = 1;
    %                     outt = [outt (t{j} - t{j}(1) + deltat)(1:end-cut)];
    %                     outy = [outy y{j}(1:end-cut) - U{j}];
    %                 end % for j
    %                 hold off
    %                 title(sprintf('P_SS.m\n outt outy cells'), 'interpreter', 'none')
    %                 sqrt(mean(outy.^2)).*sqrt(2)

end % function P_SS

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
