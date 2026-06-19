% -- [DC_fit, newPRs, newPRe] = P_DC(M_DC, verbose)
% Process data from digitizer DC gain calibration measurement.
% Identifies PJVS step segments in the sampled waveform, computes segment
% means and uncertainties, reconstructs PJVS reference voltages, and returns
% calibrated ADC gain coefficients.
%
%    Inputs:
%      M_DC    - structure with digitizer DC gain calibration measurement data.
%                Required fields:
%                  .y.v          - sampled waveform (V)
%                  .Uref1period.v - PJVS reference voltages for one period (V)
%                  .fs.v         - sampling frequency (Hz)
%                  .fseg.v       - frequency of PJVS segments (Hz)
%                  .MRs.v        - number of masked samples at record start
%                  .MRe.v        - number of masked samples at record end
%                  .PRs.v        - number of masked samples after PJVS step change
%                                  (set negative to auto-detect)
%                  .PRe.v        - number of masked samples before PJVS step change
%                                  (set negative to auto-detect)
%      verbose - if nonzero, diagnostic plots will be generated. Default: 0
%
%    Outputs:
%      DC_fit  - calibrated ADC gain coefficients (result of adc_pjvs_calibration)
%      newPRs  - auto-detected PRs value (samples masked after PJVS step change);
%                equals input M_DC.PRs.v if auto-detection was not triggered
%      newPRe  - auto-detected PRe value (samples masked before PJVS step change);
%                equals input M_DC.PRe.v if auto-detection was not triggered
%
%    Example:
%      [M_DC] = G_DC([], 0);
%      [DC_fit, newPRs, newPRe] = P_DC(M_DC, 0);

function [DC_fit, newPRs, newPRe] = P_DC(M_DC, verbose)

    % Initialize %<<<1
    % sigconfig structure is leftover from QuantumPower project.
    % (it was simpler to recreate the structure than to modify the functions)
    sigconfig.fs.v = M_DC.fs.v;
    sigconfig.fseg.v = M_DC.fseg.v;
    sigconfig.MRs = M_DC.MRs.v;
    sigconfig.MRe = M_DC.MRe.v;
    sigconfig.PRs = M_DC.PRs.v;
    sigconfig.PRe = M_DC.PRe.v;

    % dbg structure is leftover from QuantumPower project.
    % (it was simpler to recreate the structure than to modify the functions)
        dbg.v = 0;
        dbg.pjvs_ident_segments_10 = 1;
        dbg.pjvs_ident_segments_all = 1;
        dbg.pjvs_ident_Uref_phase = 1;
        dbg.pjvs_ident_Uref_all = 0;
        dbg.pjvs_segments_first_period = 1;
        dbg.pjvs_segments_mean_std = 1;
        dbg.pjvs_adev = 0;
        dbg.pjvs_adev_all = 0;
        dbg.adc_calibration_fit = 1;
        dbg.adc_calibration_fit_errors = 1;
        dbg.adc_calibration_fit_errors_time = 1;
        dbg.saveplotsfig = 1;
        dbg.saveplotspng = 1;
        dbg.section = [1 1];
        dbg.showplots = 'on';
        dbg.plotpath = '.';
    if verbose
        dbg.v = 1;
    end

    % Do calculation %<<<1
    % Get length of PJVS segments in samples (samples between two different PJVS steps):
    segmentlen = sigconfig.fs.v./sigconfig.fseg.v;
    % Find out indexes of PJVS segments automatically:
    tmpSpjvs = pjvs_ident_segments(M_DC.y.v, sigconfig.MRs, sigconfig.MRe, segmentlen, dbg);

    % automatically find PRs, PRe:
    if sigconfig.PRs < 0 || sigconfig.PRe < 0
        [newPRs, newPRe] = pjvs_find_PR(M_DC.y.v, tmpSpjvs, sigconfig, dbg);
        % set new values of PRs,PRe:
        sigconfig.PRs = newPRs;
        sigconfig.PRe = newPRe;
    end
    if any(diff(tmpSpjvs) == 0)
        error('Error in calculation of PJVS step changes in function "pjvs_ident_segments".')
    end
    % Split the pjvs section into segments, remove PRs,PRe,MRs,MRe, calculate means, std, uA:
    [s_y, s_mean, s_std, s_uA] = pjvs_split_segments(M_DC.y.v, tmpSpjvs, sigconfig.MRs, sigconfig.MRe, sigconfig.PRs, sigconfig.PRe, dbg);
    % Now Spjvs can be incorrect, because trailing
    % segments (first or last one with smaller number of
    % samples than typical) were neglected.
    % Recreate PJVS reference values for whole sampled PJVS waveform section:
    tmpUref = pjvs_ident_Uref(s_mean, M_DC.Uref1period.v, dbg);

    % ADEV calculation and plotting:
    pjvs_adev(s_y, tmpUref, M_DC.Uref1period.v, dbg); % not calculated if disabled by dbg
    % calibration of ADC:
    DC_fit = adc_pjvs_calibration(tmpUref, s_mean, s_uA, dbg);

    % debug plots %<<<1
    if dbg.v 
        if dbg.pjvs_segments_first_period
            % plot with segments minus reference value,
            % for first PJVS period:
            figure('visible',dbg.showplots)
            hold on
            legc = {};
            % this limit is to correctly set limits for
            % plot, because NaN values cause unnecesary
            % empty space on right side of the plot
            plotlim = 0;
            for k = 1:numel(M_DC.Uref1period.v)
                plot(1e6.*(s_y(:,k) - tmpUref(k)), '-x')
                legc{end+1} = sprintf('U_{ref}=%.9f', tmpUref(k));
                plotlim = max(plotlim, sum(~isnan(s_y(:,k))));
            end
            xlim([0.9 plotlim+0.1]);
            legend(legc, 'location', 'eastoutside')
            title(sprintf('Segment samples minus PJVS reference value\n(masked MRs, MRe, PRs, PRe)'))
            xlabel('Sample index')
            ylabel('Voltage difference (uV)')
            hold off
            fn = fullfile(dbg.plotpath, ['pjvs_segments_first_period']);
            if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
            if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
            close
        end % if dbg.pjvs_segments_first_period
        if dbg.pjvs_segments_mean_std
            % plot means and std of segments minus reference value,
            figure('visible',dbg.showplots)
            hold on
            legc = {};
            plot(1e6.*(s_mean - tmpUref), 'b-x', 1e6.*s_std, 'r-x')
            legend('Mean of segments', 'Std. of segments')
            title(sprintf('Segments samples minus PJVS reference value\n(masked MRs, MRe, PRs, PRe)'))
            xlabel('Segment index')
            ylabel('Voltage (uV)')
            hold off
            fn = fullfile(dbg.plotpath, ['pjvs_segments_mean_std']);
            if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
            if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
            close
        end % if dbg.pjvs_segments_first_period
    end % if dbg %>>>2

end % function

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
