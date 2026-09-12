%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GridInverterParameters.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [k0_g, k1_g, k2_g]=GridInverterParameters(pac_g, Efficiency_g)
% Linearized least-squares fit of the Schmid model (Octave compatible)

    warning('off','all');
    % Linearized form: k0 + k1*p + k2*p^2 = p * (100/eta - 1)
    p = pac_g(:);
    eta = Efficiency_g(:);

    valid = (p > 0) & (eta > 0) & ~isnan(p) & ~isnan(eta);
    p = p(valid);
    eta = eta(valid);

    if numel(p) < 3
        error('GridInverterParameters: at least 3 valid curve points are required.');
    end

    y = p .* (100 ./ eta - 1);
    A = [ones(size(p)), p, p.^2];
    coefficients = (A' * A) \ (A' * y);

    k0_g = coefficients(1);
    k1_g = coefficients(2);
    k2_g = coefficients(3);

    % Plot data and fitted model
    pfit = linspace(min(p), max(p), 100)';
    etafit = 100 * pfit ./ (pfit + k0_g + k1_g * pfit + k2_g * pfit.^2);
    plot(pfit, etafit, '-k', p, eta, 'ko');
    warning('on','all');
end
