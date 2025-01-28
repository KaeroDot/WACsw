addpath('acdc')
addpath('info')

			% meas.ranges_count = 1;
			% meas.range_names = {'2.2', 7};
			% meas.meas_folder = '';
			%
			% file = '/home/martin/metrologie/WAC/WACsw_github/data_processing/FF/acdc_data/F792temelin/f792temelin';
			% acdc = correction_load_acdctransfer(file, meas);
			% tbl = correction_interp_table(acdc.acdc_diff,[2 3 4 5 6],15);

verbose = 0;
% generate simulated measurement data:
[M_FR, simulated_digitizer_FR] = G_FR(verbose);
% process measurement:
[f, measured_digitizer_FR, ac_source_stability] = P_FR(M_FR, verbose);

figure
plot(M_FR.f.v, simulated_digitizer_FR.v - 1, '.b', f.v, simulated_digitizer_FR.v - 1, '-r')
title(sprintf('selftest.m\nsimulated and measured frequency response of the digitizer'))
legend('simulated FR', 'measured FR')
xlabel('signal frequency (Hz)')
ylabel('gain error ()')
