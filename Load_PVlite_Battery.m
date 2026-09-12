%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load_PVlite_Battery.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function BatParams = Load_PVlite_Battery(battery_name)
    % Reads PVlite_Batteries.csv and returns the parameters of one battery

    [script_dir, ~, ~] = fileparts(mfilename('fullpath'));
    db_path = fullfile(script_dir, 'ddbb', 'PVlite_Batteries.csv');
    if ~isfile(db_path)
        error('PVlite_Batteries.csv not found in ddbb folder.');
    end

    % Read CSV as table, skipping the first 2 units/metadata lines
    opts = detectImportOptions(db_path);
    opts.DataLines = [4 Inf];
    opts.VariableNamesLine = 1;
    opts.PreserveVariableNames = true;

    db = readtable(db_path, opts);

    % Find battery by name, trimming leading/trailing whitespace
    battery_name = strtrim(battery_name);
    idx = find(strcmp(strtrim(db.Name), battery_name));

    if isempty(idx)
        error(['Battery ''', battery_name, ''' not found in the PVlite database.']);
    end

    % If multiple match, warn the user and take the first one
    if numel(idx) > 1
        warning('Load_PVlite_Battery:duplicateName', ...
            'Found %d entries named "%s" in the PVlite database. Using the first one.', ...
            numel(idx), battery_name);
    end
    idx = idx(1);

    % Mandatory structural fields
    if isnan(db.BatteryType(idx))
        error(['Battery ''', battery_name, ''' has no BatteryType in the PVlite database.']);
    end
    if isnan(db.NominalCapacity_kWh(idx))
        error(['Battery ''', battery_name, ''' has no NominalCapacity_kWh in the PVlite database.']);
    end

    % Extract parameters into a struct; optional MKBM fields may be NaN
    BatParams = struct();
    BatParams.BatteryModel = 2; % Always MKBM for these
    BatParams.BatteryType = db.BatteryType(idx);
    BatParams.NominalCapacity = db.NominalCapacity_kWh(idx);
    BatParams.MKBM_c = db.MKBM_c(idx);
    BatParams.MKBM_k = db.MKBM_k(idx);
    BatParams.MKBM_eta_ch = db.MKBM_eta_ch(idx);
    BatParams.MKBM_eta_dis = db.MKBM_eta_dis(idx);
    BatParams.MKBM_Pmax_ch = db.MKBM_Pmax_ch_kW(idx);
    BatParams.MKBM_Pmax_dis = db.MKBM_Pmax_dis_kW(idx);
    BatParams.MKBM_LifeCycles = db.MKBM_LifeCycles(idx);
    BatParams.MKBM_LifeDoD = db.MKBM_LifeDoD(idx);
    BatParams.MKBM_CalendarLife = db.MKBM_CalendarLife(idx);

    % Optional operating temperature limits and self-discharge rate
    BatParams.MKBM_MinChargeTemp = db.MKBM_MinChargeTemp(idx);
    BatParams.MKBM_MaxChargeTemp = db.MKBM_MaxChargeTemp(idx);
    BatParams.MKBM_MinDischargeTemp = db.MKBM_MinDischargeTemp(idx);
    BatParams.MKBM_MaxDischargeTemp = db.MKBM_MaxDischargeTemp(idx);
    BatParams.MKBM_SelfDischarge = db.MKBM_SelfDischarge(idx);
end
