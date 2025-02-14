function y_all = piecewise_FR_evaluate(piecewise_fit, f, fs)
    % Check inputs %<<<1
% evaluate piecewise fit piecewise_fit for absolute frequencies f
    y_all = NaN.*zeros(size(f));
    f_rel = f./fs.v;
    if strcmp(piecewise_fit.method, 'spline') %<<<1
        % Spline method
        y_all = ppval(piecewise_fit.fit, f_rel);
    elseif strcmp(piecewise_fit.method, 'polynomial') %<<<1
        % Polynomial method
        for j = 1:numel(piecewise_fit.fit.limits) - 1
            f_low_rel = piecewise_fit.fit.limits(j)./fs.v;
            f_high_rel = piecewise_fit.fit.limits(j + 1)./fs.v;
            idx = and(f_rel >= f_low_rel, f_rel <= f_high_rel);
            % evaluate:
            tmp = polyval(piecewise_fit.fit.polP{j}, f_rel(idx), piecewise_fit.fit.polS{j}, piecewise_fit.fit.polMU{j});
            y_all(idx) = tmp;
        end % for j
    else
        error(sprintf('piecewise_FR_fit: unknown method `%s`!', piecewise_fit.method))
    end % if method
end % function piecewise_FR_evaluate

% vim settings modeline: vim: foldmarker=, fdm=marker fen ft=matlab
