# Activity 1.3.1

<!-- vim-markdown-toc GFM -->

- [Measurement types](#measurement-types)
- [Digitizer filter function -- FF](#digitizer-filter-function----ff)
  - [Measurement procedure M_FF](#measurement-procedure-m_ff)
  - [Procedure settings](#procedure-settings)
  - [Simulated data generator G_FF](#simulated-data-generator-g_ff)
    - [G_FF procedure](#g_ff-procedure)
    - [G_FF inputs](#g_ff-inputs)
    - [G_FF outputs](#g_ff-outputs)
  - [Data processing P_FF](#data-processing-p_ff)
    - [P_FF Procedure](#p_ff-procedure)
    - [P_FF inputs](#p_ff-inputs)
    - [P_FF outputs](#p_ff-outputs)
- [Cable error correction -- CE](#cable-error-correction----ce)
  - [Measurement procedure](#measurement-procedure)
  - [Measurement procedure settings](#measurement-procedure-settings)
  - [Simulated data generator G_CE](#simulated-data-generator-g_ce)
    - [G_CE procedure](#g_ce-procedure)
    - [G_CE inputs](#g_ce-inputs)
    - [G_CE outputs](#g_ce-outputs)
  - [Data processing P_CE](#data-processing-p_ce)
    - [P_CE procedure](#p_ce-procedure)
    - [P_CE inputs](#p_ce-inputs)
    - [P_CE Outputs](#p_ce-outputs)
- [DS, SS](#ds-ss)
  - [Measurement procedure](#measurement-procedure-1)
  - [Procedure settings](#procedure-settings-1)
  - [Simulated data generator G_DS](#simulated-data-generator-g_ds)
    - [G_DS procedure](#g_ds-procedure)
    - [G_DS/G_SS inputs](#g_dsg_ss-inputs)
    - [G_DS outputs](#g_ds-outputs)
  - [Data processing P_DS](#data-processing-p_ds)
    - [P_DS/P_SS Procedure](#p_dsp_ss-procedure)
    - [P_DS/P_SS inputs](#p_dsp_ss-inputs)
    - [P_DS/P_SS outputs](#p_dsp_ss-outputs)
- [Hic sunt leones -- images of dataflow](#hic-sunt-leones----images-of-dataflow)

<!-- vim-markdown-toc -->

## Measurement types
1. FF -- Calibration of the digitizer filter function
2. CE -- Calibration of the cable error correction
3. DS -- Calibration of DUT using differential sampling
4. SS -- Calibration of DUT using sub-sampling

Prefixes:
- **M_** is measurement,
- **G_** is simulated data generator,
- **P_** is processing.

## Digitizer filter function -- FF
Measurement takes a long time. It is supposed to be run from time to time,
maybe only once for a selected piece of digitizer. Integration into the main
software welcome but not needed.

### Measurement procedure M_FF
1. Set AC source (calibrator/synthesizer) at base frequency ($10^2$ or $10^3$ Hz).
1. Sample waveform, optionally simultaneously measure output of AC/DC (F792A-> voltmeter). At least 10 periods of signal with 1000 points. If possible coherent (noncoherency can be mitigated by data processing).
1. Set calibrator ac voltage at higher frequency.
1. Repeat point 2.
1. Repeat points 1--5 for frequencies through digitizer bandwidth.

- Number of measured frequencies: $10^3$--$10^4$.
- Each frequency: $N$ periods, each record $M$ samples.
- Recommended to keep $M/N > 100 \land N>10$. (Recomendation based on data processing. Is it needed for simple RMS? **CHECK**)
- Overall about $2\cdot 10^4 \cdot 10^4$ samples for whole FF measurement, that is about 2 GB file size.

### Procedure settings
1. Type and address of the digitizer.
1. Type and address of AC source (calibrator, synthesizer).
1. Type of reference value:
    1. AC source (for the case of calibrator).
    1. voltmeter (for the case of AC/DC transfer standard).
1. Value of $M/N$ (number of samples in record divided by number of periods).
1. Number/list of frequency points.
1. Base frequency.
1. Final frequency.

### Simulated data generator G_FF
Simulation of measurement stability: not required.

#### G_FF procedure
1. Generate filter function -- arbitrary with nice values based on example data. The filter function can be represented by simple (sine)wave + cut off filter with defined fall-off slope.
1. Generate sampled data based on definition in Data processing. For each frequency generate sine wave with amplitude corrected according the filter function. Add noise.
1. Save data according definition in FF data processing.

#### G_FF inputs
1. f -- calibrator frequencies (Hz), $N$ values.
1. A -- calibrator nominal amplitude (V), scalar.
1. noise -- simulation of calibrator + digitizer noise (V), scalar (frequency independent).
1. digitizer amplitude error function (optional?)
1. digitizer phase error function (optional?)
1. ratio -- value of $M/N$ (samples), scalar
1. Unom -- nominal voltage measured by voltmeter on ac--dc standard (V), scalar)
1. ac--dc transfer function of the ac--dc standard (V/V), matrix with frequency vs voltage axis.

#### G_FF outputs
1. Data saved to a file according definition in P_FF data processing.

### Data processing P_FF
#### P_FF Procedure
1. Calculate amplitude at selected frequency. Should be peak, however ac--dc methods gives only RMS, so sampling should be treated the same.
1. Calculate ratio of the measured amplitude at higher frequency to the amplitude at base frequency to prevent drifts.
1. Measured ratios: fit the curve (ratio vs frequency) using Piecewise spline (PTB method, no algorithm with uncertainties) or using polynomial by CCC/OEFPIL (with uncertainties).
1. Output calibration data. Should contain:
    1. device, measurement conditions etc.
    1. dependence of amplitude error to the frequency (reduced by the sampling fr.)
    1. picewice representation or polynomial fit.

#### P_FF inputs
1. f -- set freuqencies (Hz), scalar. Values should be: [$f_0$, $f_n$, $f_0$, $f_{(n+1)}$, ...].
1. Uref -- reference values of amplitudes for the case of calibrator only measurement (V), vector. Value and uncertainty based on calibrator specifications.
1. y -- digitizer records (V), matrix. $2\cdot N$ records -- rows.
1. u -- voltage measured on the multimeter connected to the ac-dc transfer standard, if used, (V), matrix. $2\cdot N\cdot R$ values, $R$ is the number of readouts. Uncertainty based on ac-dc and voltmeter specifications.

#### P_FF outputs
1. E -- errors of the digitizer amplitude (V), $N$ numbers
2. FF -- filter function. piecewice or polynomial? **to be specified**

## Cable error correction -- CE
Measurement must be run often, should not be time consuming. It has to be integrated into the main measurement software.

### Measurement procedure
1. Set switch to short.
1. Set AC calibrator to a selected amplitude and frequency.
1. Sample waveform. At least 10 periods of the signal with 1000 points. Should be coherent, calibrator is easy to lock.
1. Set switch to PJVS.
1. Repeat point 2.
1. Repeat points 1--5 for frequencies through digitizer bandwidth? **Whole bandwidth or smaller range is ok?**.

- Number of measured frequencies: 200 -- 300.
- Each frequency: $2\cdot M$ samples.
- Recommended to keep $M/N > 100 \land N>10$.
- Overall about $2\cdot 10^4 \cdot 300$ samples for whole CF measurement, that is about 8 MB file size.

### Measurement procedure settings
1. Type and address of AC source (calibrator, synthesizer).
1. Type and address of switch.
1. Value of $M/N$ (number of samples in record divided by number of periods).
1. Number of frequency points.

### Simulated data generator G_CE
The proper way would be to simulate cable and calculate results of the
measurement. That is time consuming, so simple data simulation was selected.
Simulation of measurement stability is not required.

#### G_CE procedure
1. Generate cable error function -- arbitrary with nice values based on example data. The cable error function can be represented e.g. by simple increasing parabolic function.
1. Generate sampled data based on definition in Data processing. For each frequency generate sine wave with and without amplitude corrected according the filter function. Add noise.
1. Save data according definition in CE data processing.

#### G_CE inputs
1. f -- calibrator frequencies (Hz), vector, $N$ values.
1. A -- calibrator nominal amplitude (V), scalar.
1. noise -- simulation of calibrator + digitizer noise (V), scalar, same in whole bandwidth.
1. cable error function (optional?), curve parameter (optional?) **DECIDE**.

#### G_CE outputs
1. Data saved to a file according definition in CE data processing.

### Data processing P_CE
#### P_CE procedure
1. Calculate amplitude at selected frequency for both short settings. Should be peak. If coherent measurement, FFT should be enough.
1. Calculate ratio of measured amplitudes.
1. Measured ratios vs frequency: fit the curve (ratio vs frequency) using polynomial? Cable function? **DECIDE**.
1. Output cable error data. Should contain:
    1. device, measurement conditions etc.
    1. dependence of amplitude error vs signal frequency.
    1. fit results.

#### P_CE inputs
1. y -- record values, no uncertainties(?). $2\cdot N$ records -- rows.
1. f -- calibrator set freuqency. Value and uncertainty based on calibrator specifications.

#### P_CE Outputs
1. E -- errors of the cable, $N$ numbers
2. CE -- cable error function. piecewice/polynomial? **XXX**

## Differential Sampling DS, Sub-sampling SS
Measurement takes a long time due to 96 % of the samples are thrown away.

### Measurement procedure
1. Calculate waveform parameters
1. Check if sampling possible:
    1. coherency:
        1. DS: $S$ PJVS steps must fit into one signal period
        1. SS: $S$ signal periods must fit into one PJVS step
    1. signal amplitude
        1. DS: less than max(PJVS) + 0.1 V
        1. SS: less than 1.75 V rms without divider for NI5922
    1. enough remaining samples:
        1. DS in PJVS step after removing ringing.
        1. SS: must remain at least 2(?**XXX**) samples for every singal period in the $\pm 0.1$ V range.
1. Setup timing hw
1. Setup PJVS
1. Setup ac source
1. Set switch to connect
1. Get samples

### Procedure settings
1. ac signal source/type/address
1. timing hw type/address
1. signal frequency, amplitude
1. no of steps in PJVS period
1. digitizer sampling rate, range, record length
1. number of samples to delete before/after ringing

### Simulated data generator G_DS
#### G_DS procedure
1. Generate DUT sinewave with noise
1. Generate reference PJVS steps
1. Diff both signals, add noise DUT+digitizer

#### G_DS/G_SS inputs
1. f -- DUT frequency (Hz), scalar
1. A -- DUT amplitude (V), scalar
1. ph -- DUT phase (rad), scalar
1. L -- record length (samples), scalar
1. fs -- sampling frequency (Hz), scalar
1. noise -- signal noise sigma (DUT + digitizer) (V), scalar
1. fm -- microwave frequency (Hz), scalar
1. fseg -- frequency of PJVS segments (Hz), scalar
1. phseg -- phase of PJVS segments (rad), scalar
1. apply_filter -- apply filter simulating sigma--delta digitizer (bool), parameter scalar
1. PJVS waveform -- sine (0) or triangle (1) (bool), parameter scalar

#### G_DS outputs
1. y -- waveform (V), vector
1. Uref -- reference voltages of segments for whole signal(V), vector
1. Uref1period -- reference voltages of segments for one period of PJVS signal(V), vector
1. Spjvs -- sample indexes of PJVS switches -- switch happen before or at the sample, vector

### Data processing P_DS
#### P_DS/P_SS Procedure
1. Identify PJVS steps -- only coherent measurement so only searching for actual samples. However system from QuantumPower can be utilized.
1. Delete (ringing) points
1. Split signal into PJVS steps (use from QP)
1. Match PJVS reference values to the splitted signal. (use from QP)
1. Add PJVS reference values to the splitted signal.
1. P_SS only: 
    1. cut out all values over $\pm 0.1$ V
    1. remove error of the digitizer filter function -- iFFT->multiply->FFT.
    1. remove cable error (same method as previous one? **XXX**)
1. Calculate RMS value. 2 ways:
    1. DS only: average per PJVS step, RMS value, apply sinc correction.
    1. both DS/SS: just RMS of all samples (what is caveat here? **XXX**).

Single measurement typically 120 MB (40 periods of PJVS triangular waveform).

#### P_DS/P_SS inputs
1. y -- sampled data (V), vector
1. fs -- sampling frequency (Hz), scalar
1. fseg -- frequency of changing PJVS steps (Hz), scalar
1. PRe -- deleted before PJVS step change (samples), scalar
1. PRs -- deleted after PJVS step change (samples), scalar
1. MRs -- deleted after record start (samples), scalar
1. MRe -- deleted before record start (samples), scalar
1. Uref1period -- reference values of PJVS voltages for one PJVS period (V), vector
1. calibration curve of the digitizer filter (P_FF).
1. calibration curve of the cable error (PF_CE).

#### P_DS/P_SS outputs
1. A_rms_total -- RMS amplitude of the DUT signal calculated from whole data
1. A_rms_t -- RMS amplitude calculated from every signal period

## Hic sunt leones -- images of dataflow
