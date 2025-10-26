% Function calculates relative error caused by cable impedance for low frequencies.
% For equations see D. Zhao, H. E. van den Brom, and E. Houtzager, ‘Mitigating voltage lead errors of an AC Josephson voltage standard by impedance matching’, Measurement Science and Technology, vol. 28, no. 9, p. 095004, Sept. 2017, doi: 10.1088/1361-6501/aa7aba.
% 
% Inputs:
% f - frequency (Hz)
% L - cable length (m)
%
function err_rel = cable_error(f, L)
    % Some parameters for Browning Low Loss RG-58 Cable
    % https://www.buytwowayradios.com/browning-br-195-1.html#:~:text=Electrical%20Specifications&text=Capacitance%20-%2025.40%20pF%2Fft.,Inductance%20-%200.064%20uH%2Fft.
    % inductance per unit length
    % l = 0.064 uH/ft = 0.210 uH/m;
    l = 0.21e-6;
    % capacitance per unit length
    % c = 25.40 pF/ft = 83.33 pF/m;
    c = 83.33e-12;
    nu = 1/sqrt(l.*c); % propagation velocity in the cable (m/s)

    % cable error
    % simplest case - suppose impedance of PJVS is Z_s ≈ 0, DUT is of high
    % impedance, lambda >> L. Equation 2 in cited paper.
    %
    err_rel = 1 + 2.*pi.^2.*(f.*L./nu).^2; % err = V(L)./V_s

    %TODO: more complex case even for higher frequencies.
end % function

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab
