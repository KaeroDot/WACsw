[M_FR, simulated_digitizer_FR] = G_FR(0);


f.v = M_FR.f.v;
FR.v = simulated_digitizer_FR.v;
fs_struct = struct('v', M_FR.fs.v);


regions_min = 10;
regions_max = 150;
regions_list = regions_min:1:regions_max;

errors = NaN(size(regions_list));


for k = 1:numel(regions_list)
    r = regions_list(k);
    pw = piecewise_FR_fit(f, FR, M_FR, 0, r);
    errors(k) = pw.total_error;
end


figure;
semilogy(regions_list, errors, '-r', 'MarkerSize', 4)
xlabel('Počet regiónov (n)')
ylabel('Celková chyba fitu (V)')
title('Zavislost erroru na poctu regions')

%plot(M_FR.f.v, simulated_digitizer_FR.v - 1, '.b', f.v, measured_digitizer_FR.v - 1, '-r')
%title(sprintf('selftest.m\nsimulated and measured frequency response of the digitizer'))
%legend('simulated FR', 'measured FR')
saveas(gcf(),'15mhz_graf.fig')
