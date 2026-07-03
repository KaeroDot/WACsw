% This script variates the number of regions used in piecewise frequency
% response fitting to find out optimal number of regions.

clear all;

% variate number of regions:
regions_list = 10:250;
fit_errors = NaN(size(regions_list));

% generate simulated frequency response measurement:
[M_FR, simulated_digitizer_FR] = G_FR([], 0);
f = M_FR.f;

for k = 1:numel(regions_list)
    r = regions_list(k);
    piecewise_fit(k) = piecewise_FR_fit(f, simulated_digitizer_FR, M_FR, r, 0);
    fit_errors(k) = piecewise_fit(k).total_error;
end

figure;
semilogy(regions_list, fit_errors, '-r', 'MarkerSize', 4)
xlabel('Number of fitting regions')
ylabel('Total fit error')
title('Total errors of the frequency response fit')

% saveas(gcf(),'variate_FR_regions.fig')
% saveas(gcf(),'variate_FR_regions.png')

freqs = linspace(10, 0.4.*M_FR.fs.v, 1000);
figure;
hold on
for k = 1:numel(piecewise_fit)
    tmp = piecewise_FR_evaluate(piecewise_fit(k), freqs, M_FR.fs);
    % this is needed so the plotting library do not complain about extremely
    % large numbers:
    tmp(tmp>1e3) = NaN;
    tmp(tmp<1e-3) = NaN;
    plot(tmp, '-')
end
ylim([0.998 1.005])
