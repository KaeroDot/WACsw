function [M_SS]=conditions_M_SS(M_SS)

  % Setting parameters of the DUT
  f=100.e3; % [Hz] DUT signal frequency
  A=1.;     % [V] DUT signal amplitude
  ph=0.;    % [rad] DUT signal phase
  ratio=1.; % [V/V] Division ratio of voltage divider
  A=A/ratio;  % [V] DUT amplitude after voltage divider

  % Condition 1: Setting PJVS steps that fit with the given PJVS and DUT signal
  limit=.1;  % [V] Sampling limit (+-) for the sub-sampling
  fm=75.e9;  % [Hz] MW frequency for the PJVS
  V_JJ=2.06783901104e-15*fm;  % [V] per JJ
  n_JJstep=floor(limit/V_JJ); % [] Number of JJs to fit within sampling limit. This constitutes half of the PJVS steps.
  %n_JJstep*V_JJ
  n_PJVSsteps=ceil((2*A-2*limit)/(2*n_JJstep*V_JJ))+1; % Number of PJVS steps necessary in the triangular sweep
  PJVSstepvalues=2*2*(n_PJVSsteps-1)*n_JJstep:-2*n_JJstep:n_JJstep;
  PJVSstepvalues=abs(PJVSstepvalues-2*(n_PJVSsteps-1)*n_JJstep)-(n_PJVSsteps-1)*n_JJstep;

  % Condition 2: The sampling rate must be a multiple of the DUT signal frequency.
  % This multiple corresponds to number of samples per period of the DUT signal.
  % In addition, the sample rate must also be large enough to guarantee at least
  % one sample at each PJVS-step. This means, the sample-to-sample time must be small enough
  % that the maximum expected sample-to-sample voltage change is smaller than the sample band (2 x limit).
  % To ensure that this condition is always met, we decrease the limit of
  % the  maximum expected sample-to-sample voltage change by the given factor, limit_margin
  limit_margin=1.1; % Effective limit: limit -> limit/limit_margin
  fs_min=f*A*limit_margin/limit;  % [Sa/s] Minimum limit to fulfill condition 2.2
  fs_max=16.e6; % [Sa/s] Maximum allowed sampling frequency
  select_sP=false; % If true, select number of samples per period, and appropriate fs is calculated. If false, the pre-set fs is selected
  nsP=10;  % [] Number of sample points per period of the DUT signal. Used if select_sP==true
  fs=4.e6;  % [Sa/s] Sampling rate. Used if select_sP==false


  if fs_max<fs_min
    error('The maximum condition of the sampling rate has been set lower than the required minimum limit.');
  end

  if select_sP==true
    fs=f*nsP;
  else
    if mod(fs,f)!=0
      error('The selected fs is not an integer number of f');
    endif
    nsP=fs/f;
  end

  if fs<fs_min
    error('The sampling rate has been set lower than the required minimum limit.');
  end

  if fs>fs_max
    error('The sampling rate has been set above the maximum condition set.');
  end

  % Consider making a routine to select/calculate appropriate number of periods
  % Set DUT to a zero, and skip between steps of PJVSstepvalues in a random pattern,
  % and track the number of samples needed to stabilize the the digitizer within e.g. 1 uV
  % of the various PJVS transitions, take the highest number of samples needed
  % to stabilize the digitizer. Ceil the number of samples to the number of periods of the DUT
  % This is the number needed for Rs and Re


  % Condition 3: Make the PJVS steps are wide enough to sample over an entire period of the DUT signal.
  % We must shave off one period on each side of the transition between two PJVS-step to avoid dubious data,
  % sampled when the PJVS is not properly quantised.
  nT=5; % [] Number of periods to sample
  Rs=1; % [] Number of periods to skip at the start of the PJVS step
  Re=1; % [] Number of periods to skip at the end of the PJVS step
  Tstep=(nT+Rs+Re)/f;  % [s] Time spent on a PJVS step.
  fstep=1./Tstep; % [Hz]
  f_envelope=fstep/length(PJVSstepvalues);  % [Hz]
  A_envelope=max(PJVSstepvalues(:))*V_JJ; % [V]
  ph_envelope = 0*pi; % [rad] No phase shift here.
  L = 1.*fs./f_envelope;



  % Create output structure %<<<1
  %M_SS = check_gen_M_SS();
  % Generate measurement data structure:
  M_SS.fs.v = fs;
  %M_SS.y.v = y;
  %M_SS.t.v = tsamples;
  %M_SS.Upjvs.v = Upjvs;
  %M_SS.Upjvs1period.v = Upjvs1period;
  %M_SS.Spjvs.v = Spjvs;
  M_SS.f.v = f;
  M_SS.f_envelope.v = f_envelope;
  M_SS.f_step.v = fstep;
  M_SS.A_nominal.v = A;
  M_SS.Rs.v = Rs;
  M_SS.Re.v = Re;

end
