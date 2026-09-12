function [k0, k1, k2]=InverterParameters(pac, Efficiency)
% Linearized least-squares fit of the Schmid model (Octave compatible)

    warning('off','all');
    % Linearized form: k0 + k1*p + k2*p^2 = p * (100/eta - 1)
    p = pac(:);
    eta = Efficiency(:);

    valid = (p > 0) & (eta > 0) & ~isnan(p) & ~isnan(eta);
    p = p(valid);
    eta = eta(valid);

    if numel(p) < 3
        error('InverterParameters: at least 3 valid curve points are required.');
    end

    y = p .* (100 ./ eta - 1);
    A = [ones(size(p)), p, p.^2];
    coefficients = (A' * A) \ (A' * y);

    k0 = coefficients(1);
    k1 = coefficients(2);
    k2 = coefficients(3);

    % Plot data and fitted model
    pfit = linspace(min(p), max(p), 100)';
    etafit = 100 * pfit ./ (pfit + k0 + k1 * pfit + k2 * pfit.^2);
    plot(pfit, etafit, '-k', p, eta, 'ko');
    warning('on','all');
end
