% Feature-way generation of AC-DC errors
% Works from 10 Hz to 100 MHz
%
% Inputs:
%   f - list of measurement frequencies
% Outputs:
%   acdc_error_rel - gain errors of the AC-DC measurement

% list of measurement frequencies:
f = logspace(0, 9, 1000);

% check inputs
% values below and above limits are set to NaN:
f(f < 10) = NaN;
f(f > 100e6) = NaN;

% high side with error about ~300 ppm at 100 MHz
highside = 300.*f.^3./max(f.^3);
% low side with error of ~50 ppm at 10 Hz:
lowside = 5e4./f.^3;
% ac-dc error:
acdc_error_rel = (highside + lowside)./1e6;
plot(f, acdc_error_rel)
