% create a two collumn csv file of coherent frequencies and corresponding harmonic numbers
% each frequency is repeated twice 
[f_selected M_selected N_selected f_selected_u M_selected_u N_selected_u] = find_nearest_coherent_frequency(15e6, linspace(1e3, 1e6, 100), 100, 3, 0.2, 0.2, 0);
fmat = [f_selected_u(:), f_selected_u(:)];
fmat = fmat'(:);
Mmat = [M_selected_u(:), M_selected_u(:)];
Mmat = Mmat'(:);
Smat = repmat([0 1]', numel(fmat)./2, []);
csvwrite('CE_table.csv', [fmat(:), Mmat(:), Smat(:)]);
