clear all, close all
% data for a SJTC:
data = [...
10 21; ...
12  5; ...
14 -1; ...
100 -2;...
1000 -2; ...
6e3 -2; ...
1e4 -0.5; ...
2e4 1;...
3e4 4;...
5e4 9;...
1e5 20;...
];

x = log10(data(:,1));
y = data(:,2);

x_data = linspace(0, 7, 50)';
% double error function:
% (in log space of frequency!)
func = @(x, p) p(4) + p(3)./(erf(3*p(1)*(x-p(5)+p(2)))-erf(p(1)*(x-p(5)-p(2))));
% manually estimated coefficients:
% p0 = [1.1, 1, 0.5, -2, 2.5]; % very good in range 10 Hz to 100 kHz
p0 = [0.6, 1.1, 3, -4, 2.5]; % quite ok in range 1 Hz to 10 MHz

y_fit = func(x_data, p0);
fprintf('at 1 Hz: %d\n', y_fit(8))
fprintf('at 316 Hz: %d\n', y_fit(18))
fprintf('at 1 MHz: %d\n', y_fit(end))
fprintf('is nan?: %d\n', any(isnan(y_fit)))

figure; hold on
plot(x, y, 'x-r');
plot(x_data, y_fit,'-b');
hold off
legend('Real data of SJTC', 'simulated curve')
xlim([0 7]);
ylim([-3, 100]);
xlabel('log10(f)')
ylabel('AC/DC difference uV/V')
title('Simulated curve of AC/DC difference')

% --------------------------------------------
% OLD TESTS, UNSUCCESSFULL FITTING OF A CURVE:


% p0 = [3, 0.2, 2, 1];
%
% % Define the double exponential function
% doubleExp = @(p, x) p(1) .* exp(-p(2) .* (x - p(3)).^2) + p(4);
% % Fit the model using non-linear least squares (lsqcurvefit equivalent in Octave)
% options = optimset('Display', 'iter'); % Display optimization progress
% [p_fit, resnorm] = leasqr(x', y', doubleExp, p0, 1e-6, 20);
% % Generate fitted values
% xplot = linspace(min(x), max(x), 100);
% y_fit = doubleExp(p_fit, x_fit);
%
% poldegree = 1:30;
% figure
% hold on
% % semilogx(x, y, 'x')
% plot(x, y, 'x')
% plot(xplot, y_fit, 'x')
%         % % xplot = logspace(1, 5, 30);
%         % xplot = linspace(1, 5, 30);
%         % for i = 1:numel(poldegree)
%         %     [P{i} S{i} MU{i}] = polyfit(x, y, poldegree(i));
%         %     fitvalues{i} = polyval(P{i}, xplot, S{i}, MU{i});
%         %     rms(i) = sum(sqrt(mean((fitvalues{i} - y).^2)));
%         %     % semilogx(xplot, fitvalues{i}, '-')
%         %     plot(xplot, fitvalues{i}, '-')
%         % end
%         % % semilogx(x, y, '-k', x, fitvalues{21},'-r')
% hold off
% title('SJTC')
% xlabel('f (Hz)')
% ylabel('acdc difference delta V (uV/V)')
% % xlim([10 1e5])
% ylim([-10 30])
% rms


%
% Simulated data (example)

% % Define the double exponential function
% doubleExp = @(x, p) p(1) * exp(-p(2) * (x - p(3)).^2) + p(4);

% sine function:
% doubleExp = @(x, p) 1./(p(1)./pi*sin(pi./(2*p(1))).*1./(1+x.^(2*p(1)))) + p(2); hill
% x_data = linspace(-1, 1, 50)'; % Independent variable
% doubleExp = @(x, p) (p(1).*pi*sin(pi./(2*p(1))).*(1+x.^(2*p(1)))) + p(2); % u-shape
% p0 = [5, 2]; % Initial guess for parameters
% y_data = doubleExp(x_data, [2, 2]) + normrnd(1,0.00001, size(x_data));

% % double exponential function:
% x_data = linspace(-3, 3, 50)'; % Independent variable
% % doubleExp = @(x, p) 1./p(2) .* 1./( 1+exp(p(1)*(x-p(2))) ) .* 1./( 1+exp(-p(1).*(x+p(2))) ) % hill
% doubleExp = @(x, p) p(4) + p(2) .* ( 1+exp(p(1)*(x-p(2))) ) .* ( 1+exp(-p(1).*(x+p(2))) ) % u-shape
% p0 = [2, 2, 2, 1];
% y_data = doubleExp(x_data, [2, 2, 2, 1]) + normrnd(1,0.00001, size(x_data));


% % double error function:
% x_data = linspace(-2.5, 2.5, 50)'; % Independent variable
% doubleExp = @(x, p) p(4) + p(3)./(erf(p(1)*(x+p(2)))-erf(p(1)*(x-p(2))))
% p0 = [2, 2, 0.5, 0]
% y_data = doubleExp(x_data, p0) + normrnd(1,0, size(x_data));
%
% x_data = linspace(1, 5, 50)'; func = @(x, p) p(4) + p(3)./(erf(p(1)*(x+p(2)))-erf(p(1)*(x-p(2)))); p0 = [2, 2, 0.5, 0]; plot(x_data, func(x_data, p0));
%
% % d/dp_1(p_4 + p_3/(erf(p_1 (x + p_2)) - erf(p_1 (x - p_2)))) = -(2 p_3 (e^(-p_1^2 (x - p_2)^2) (p_2 - x) + e^(-p_1^2 (p_2 + x)^2) (p_2 + x)))/(sqrt(π) (erf(p_1 (p_2 + x)) - erf(p_1 (x - p_2)))^2)
% % d/dp_2(p_4 + p_3/(erf(p_1 (x + p_2)) - erf(p_1 (x - p_2)))) = -(2 p_1 p_3 (e^(-p_1^2 (x - p_2)^2) + e^(-p_1^2 (p_2 + x)^2)))/(sqrt(π) (erf(p_1 (p_2 + x)) - erf(p_1 (x - p_2)))^2)
% % d/dp_3(p_4 + p_3/(erf(p_1 (x + p_2)) - erf(p_1 (x - p_2)))) = 1/(erf(p_1 (p_2 + x)) - erf(p_1 (x - p_2)))
% % d/dp_4(p_4 + p_3/(erf(p_1 (x + p_2)) - erf(p_1 (x - p_2)))) = 1
% plot(x_data, y_data)
% % ylim([-1 20])


% % Fit the model using non-linear least squares (lsqcurvefit equivalent in Octave)
% options = optimset('Display', 'iter'); % Display optimization progress
% [p_fit, resnorm] = leasqr(x_data, y_data, p0, doubleExp, 1e-10, 100);
%
% % Generate fitted values
% x_fit = linspace(min(x_data), max(x_data), 100);
% y_fit = doubleExp(x_fit, p_fit);
%
% % Plot the data and the fit
% figure;
% scatter(x_data, y_data, 'bo', 'DisplayName', 'Data'); % Original data
% hold on;
% plot(x_fit, y_fit, 'r-', 'LineWidth', 2, 'DisplayName', 'Fit'); % Fitted curve
% title('Double Exponential Fit in GNU Octave');
% xlabel('x');
% ylabel('y');
% legend('show');
% xlim([min(x_data) max(x_data)])
% ylim([-1 10])
% grid on;
% hold off
%
%
%  %
%  %
%  % % Define functions
%  % % leasqrfunc = @(x, p) p(1) * exp (-p(2) * x);
%  % % leasqrdfdp = @(x, f, p, dp, func) [exp(-p(2)*x), -p(1)*x.*exp(-p(2)*x)];
%  %
%  % % generate test data
%  % t = [1:10:100]';
%  % p = [1; 0.1; 2; 1];
%  % data = leasqrfunc (t, p);
%  %
%  % rnd = [0.352509; -0.040607; -1.867061; -1.561283; 1.473191; ...
%  %        0.580767;  0.841805;  1.632203; -0.179254; 0.345208];
%  %
%  % % add noise
%  % % wt1 = 1 /sqrt of variances of data
%  % % 1 / wt1 = sqrt of var = standard deviation
%  % wt1 = (1 + 0 * t) ./ sqrt (data);
%  % data = data + 0.05 * rnd ./ wt1;
%  %
%  % F = leasqrfunc;
%  % % dFdp = leasqrdfdp; % exact derivative
%  % % dFdp = dfdp;     % estimated derivative
%  % dp = [0.001; 0.001; 0.001; 0.001];
%  % pin = [.8; .05; 0.1; 0.1];
%  % stol=0.001; niter=50;
%  % % minstep = [0.01; 0.01];
%  % % maxstep = [0.8; 0.8];
%  % % options = [minstep, maxstep];
%  %
%  % [f1, p1, kvg1, iter1, corp1, covp1, covr1, stdresid1, Z1, r21] = leasqr (t, data, pin, F, stol, niter, wt1, dp) %, [], options)
