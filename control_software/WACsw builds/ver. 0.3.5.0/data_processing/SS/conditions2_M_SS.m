function [M_SS]=conditions2_M_SS(M_SS)

  % Setting parameters of the DUT
  f=100.e3; % [Hz] DUT signal frequency
  A=1.;     % [V] DUT signal amplitude
  ph=0.;    % [rad] DUT signal phase
  ratio=1.; % [V/V] Division ratio of voltage divider
  A=A/ratio;  % [V] DUT amplitude after voltage divider

  % Condition 1: Checking if there is an integer naumber of samples that goes into one period of the DUT signal:
  fs=10e6; % [Sa/s]
  if mod(fs,f)!=0
    error('The sampling rate has not been set to a multiple of the DUT signal. Suggestion: Set fs='+num2str(floor(fs/f)*f));
  endif

  % Condition 2: Set sub-sampling limit to be large enough to guarantee at least one sample at each step of the envelop function:
  limit=0.1;  % [V] +- limit
  limit_margin=1.1; % [] Margin to ensure overlap of sub-sampling limits
  if limit<pi*A*(f/fs)*limit_margin
    error('Sub-sampling is too small. Must be at least limit=pi*A*(f/fs)*limit_margin='+num2str(pi*A*(f/fs)*limit_margin));
  endif

  % Condition 3: Set the width of the sub-sampling step:
  nT=3; % [] Number of periods to sample
  Rs=1; % [] Number of periods to skip at the start of the PJVS step
  Re=1; % [] Number of periods to skip at the end of the PJVS step
  fstep=f/(nT+Rs+Re);  % [Hz] Rate of change for each PJVS step.

  if mod((nT+Rs+Re),5)!=0
    'Warning: Consider setting (nT+Rs+Re)=n*5';
  endif

  % Condition 4: Find maximum number of JJs to fit inside the limit
  fm=75.e9;  % [Hz] MW frequency for the PJVS
  V_JJ=2.06783901104e-15*fm;  % [V] per JJ
  limit_margin=1.1; % [] Margin to ensure overlap of sub-sampling limits. Reused!
  n_JJstep=floor((limit/limit_margin)/V_JJ); % [] Number of JJs to fit within sampling limit. This constitutes half of the PJVS steps.

  % Condition 5: Setting the PJVS-steps and frequency
  n_PJVSlevels=ceil((2*A-2*limit)/(2*n_JJstep*V_JJ))+1;  % [] (n_PJVSlevels-1)*2nJJstep*V_JJ+2*limit>=2*A
  n_PJVSsteps=2*n_PJVSlevels-2;
  PJVSstepvalues=2*2*(n_PJVSlevels-1)*n_JJstep:-2*n_JJstep:n_JJstep;
  PJVSstepvalues=abs(PJVSstepvalues-2*(n_PJVSlevels-1)*n_JJstep)-(n_PJVSlevels-1)*n_JJstep;
  fstep
  factor(fstep)
  length(PJVSstepvalues)
  nPJVSstepvalues=find_closest_b(fstep/2, length(PJVSstepvalues))
  nPJVSlevels=nPJVSstepvalues/2+1
  n_JJstep
  n_JJstep_min=ceil((A-limit)/((nPJVSlevels-1)*V_JJ))
  n_JJstep_max=ceil(A/((nPJVSlevels-1)*V_JJ))
  limit_margin
  limit_margin_min=limit/(n_JJstep_max*V_JJ)
  limit_margin_max=limit/(n_JJstep_min*V_JJ)

  function closest_b = find_closest_b(a, b)
    % Check if c = a / b is an integer
    if mod(a, b) == 0
        fprintf('c = %d/%d = %d is already an integer.\n', a, b, a/b);
        closest_b = b;
        return;
    end

    % Find the closest integer b such that a / b is an integer
    divisors = divisors(a); % Get all divisors of a
    [~, idx] = min(abs(divisors - b)); % Find the closest divisor to b
    closest_b = divisors(idx);

    fprintf('Original b: %d, Closest b: %d such that a/b is an integer.\n', b, closest_b);
  end

  function d = divisors(n)
    % Helper function to find all divisors of n
    d = find(mod(n, 1:n) == 0);
  end

  if mod(fstep,length(PJVSstepvalues))!=0
    fprintf('Warning! Consider changing the overlapping factor, limit_margin>1. to ensure f_envelopebecpmse an integer!');
    fprintf('Consider selecting limit_margin between ');
    fprintf(num2str(max(1.0,limit_margin_min)));
    fprintf(' and ');
    fprintf(num2str(limit_margin_max));
  endif
  f_envelope=fstep/length(PJVSstepvalues);

  %length(PJVSstepvalues)
  %n_JJstep

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
