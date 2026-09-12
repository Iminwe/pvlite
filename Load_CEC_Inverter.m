%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load_CEC_Inverter.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PInom, PImax, k0, k1, k2] = Load_CEC_Inverter(inverter_name, role)
    % Reads CEC Inverters.csv; role 'battery' warns if CEC_hybrid ~= 'Y'

    [script_dir, ~, ~] = fileparts(mfilename('fullpath'));
    db_path = fullfile(script_dir, 'ddbb', 'CEC_Inverters.csv');
    if ~isfile(db_path)
        error('CEC Inverters.csv not found in ddbb folder.');
    end

    % Read the CSV file as a table
    opts = detectImportOptions(db_path);
    opts.DataLines = [4 Inf];
    opts.VariableNamesLine = 1;
    opts.PreserveVariableNames = true;

    db = readtable(db_path, opts);

    % Find inverter by name, trimming leading/trailing whitespace
    inverter_name = strtrim(inverter_name);
    idx = find(strcmp(strtrim(db.Name), inverter_name));

    if isempty(idx)
        error(['Inverter ''', inverter_name, ''' not found in the CEC database.']);
    end

    % If multiple match, warn the user and take the first one
    if numel(idx) > 1
        warning('Load_CEC_Inverter:duplicateName', ...
            'Found %d entries named "%s" in the CEC database. Using the first one.', ...
            numel(idx), inverter_name);
    end
    idx = idx(1);

    % Optional role check: 'battery' expects CEC_hybrid = 'Y'
    if nargin >= 2 && ~isempty(role)
        expected = '';
        if strcmpi(role, 'battery')
            expected = 'Y';
        end

        if ~isempty(expected) && ismember('CEC_hybrid', db.Properties.VariableNames)
            actual = strtrim(char(db.CEC_hybrid(idx)));
            if ~strcmpi(actual, expected)
                warning('Load_CEC_Inverter:typeMismatch', ...
                    'Inverter "%s" has CEC_hybrid = "%s" (expected "%s" for %s use).', ...
                    inverter_name, actual, expected, role);
            end
        end
    end

    % Extract CEC CSV parameters; reject missing values
    Paco = db.Paco(idx);
    if isnan(Paco)
        error(['Inverter ''', inverter_name, ''' has no Paco value in the CEC database.']);
    end
    Pdco = db.Pdco(idx);
    if isnan(Pdco)
        error(['Inverter ''', inverter_name, ''' has no Pdco value in the CEC database.']);
    end
    Pso = db.Pso(idx);
    if isnan(Pso)
        error(['Inverter ''', inverter_name, ''' has no Pso value in the CEC database.']);
    end
    C0 = db.C0(idx);
    if isnan(C0)
        error(['Inverter ''', inverter_name, ''' has no C0 value in the CEC database.']);
    end
    C2 = db.C2(idx); % At nominal voltage, Pso disappears: C2 will not be used

    PInom = Paco / 1000; % Nominal output power Paco (W -> kW)
    PImax = PInom;

    % Generate efficiency points at different loads
    p_ac_norm = [0.1; 0.25; 0.5; 0.75; 1.0];
    pac_points = p_ac_norm * Paco;

    eff_points = zeros(5, 1);

    for i = 1:5
        % True Sandia model at nominal voltage (Vdc = Vdco):
        % Pac = (Paco/(Pdco-Pso) - C0*(Pdco-Pso))*(Pdc-Pso) + C0*(Pdc-Pso)^2
        % Solve for x = (Pdc - Pso):  C0*x^2 + B*x - Pac = 0
        A = C0;
        B = Paco/(Pdco-Pso) - C0*(Pdco-Pso);
        if abs(A) < 1e-12
            x = pac_points(i) / B;                        % linear case
        else
            discriminant = B^2 + 4*A*pac_points(i);
            % Positive root, rationalized form:
            x = (2 * pac_points(i)) / (B + sqrt(discriminant));
        end
        Pdc = x + Pso;

        eff_points(i) = (pac_points(i) / Pdc) * 100;

        % Cap efficiency realistically
        if eff_points(i) > 99
            eff_points(i) = 99;
        elseif eff_points(i) < 0
            eff_points(i) = 50;
        end
    end

    % Fit k0, k1, k2 using least squares
    % PVlite model: Efficiency = 100 * p0 / (p0 + k0 + k1*p0 + k2*p0^2)
    % Rearranging: k0 + k1*p0 + k2*p0^2 = p0 * (100/Efficiency - 1)
    % Let y = p0 * (100/Efficiency - 1), then y = k0 + k1*p0 + k2*p0^2

    y = p_ac_norm .* (100 ./ eff_points - 1);

    % Build matrix for least squares: [1, p0, p0^2] * [k0; k1; k2] = y
    A_mat = [ones(5,1), p_ac_norm, p_ac_norm.^2];

    % Solve using normal equations (A'*A * x = A'*y)
    k_params = (A_mat' * A_mat) \ (A_mat' * y);

    k0 = k_params(1);
    k1 = k_params(2);
    k2 = k_params(3);

    % Ensure non-negative values
    if k0 < 0
        k0 = 0.005;
    end
    if k2 < 0
        k2 = 0.01;
    end
end
