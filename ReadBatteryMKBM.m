%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ReadBatteryMKBM.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reads the extra battery parameters for the Modified Kinetic Battery Model
% (MKBM). Call after ReadInputData.m for lithium-ion batteries.
% Reads the 'BatteryMKBM' sheet; if absent, defaults from BatteryType are used.
%
% Parameters read from Excel:
%   Use_Database  - 1=Manual input, 2=Use PVlite database
%   Battery_Name  - Name of the battery in the database (if Use_Database=2)
%   N_Batteries   - Number of batteries in parallel
%   BatteryModel  - 1=Simple model (original), 2=MKBM model
%   BatteryType   - 1=Lead-acid, 2=Li-ion LFP, 3=Li-ion NMC, 4=Li-ion LTO, 5=Custom
%   MKBM_c        - Capacity ratio [0-1] (optional)
%   MKBM_k        - Rate constant [1/h] (optional)
%   MKBM_eta_ch   - Charging efficiency [0-1] (optional)
%   MKBM_eta_dis  - Discharging efficiency [0-1] (optional)
%   MKBM_Pmax_ch  - Maximum charging power [kW] (optional)
%   MKBM_Pmax_dis - Maximum discharging power [kW] (optional)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Try to read MKBM parameters sheet
try
    SheetName = 'BatteryMKBM';
    clear NUMERIC TXT RAW;
    [NUMERIC, TXT, RAW] = xlsread(file1, SheetName);

    % Detect the new database-style BatteryMKBM layout
    isNewBattery = HasDatabaseHeader(RAW);
    if isNewBattery
        batOffset = 3;
    else
        batOffset = 0;
    end

    % Check if user wants to use database
    if isNewBattery && size(NUMERIC,1) >= 1 && ~isnan(NUMERIC(1,3))
        Use_Database_Bat = NUMERIC(1,3);
    else
        Use_Database_Bat = 1; % Default to manual
    end

    if Use_Database_Bat == 2
        % Database mode
        Battery_Name = '';
        N_Batteries = 1;

        if iscell(RAW) && size(RAW,1) >= 5 && size(RAW,2) >= 3 && ischar(RAW{5,3})
            Battery_Name = strtrim(RAW{5,3});
        end

        if size(NUMERIC,1) >= 3 && ~isnan(NUMERIC(3,3))
            N_Batteries = NUMERIC(3,3);
        end

        if isempty(Battery_Name)
            error('BatteryMKBM database mode requires a battery name in Excel row 5, column C.');
        end

        % CSV struct goes in BatDB, not BatParams (reserved for InitBatteryMKBM state)
        BatDB = Load_PVlite_Battery(Battery_Name);

        BatteryModel = BatDB.BatteryModel;
        BatteryType = BatDB.BatteryType;

        % Overwrite CBAT
        CBAT = BatDB.NominalCapacity * N_Batteries;

        % Override MKBM parameters. NaN is rejected, so the variable is not created
        % and the code falls back to battery-type defaults as in manual mode
        if ~isnan(BatDB.MKBM_c)
            MKBM_c = BatDB.MKBM_c;
        end
        if ~isnan(BatDB.MKBM_k)
            MKBM_k = BatDB.MKBM_k;
        end
        if ~isnan(BatDB.MKBM_eta_ch)
            MKBM_eta_ch = BatDB.MKBM_eta_ch;
        end
        if ~isnan(BatDB.MKBM_eta_dis)
            MKBM_eta_dis = BatDB.MKBM_eta_dis;
        end
        if ~isnan(BatDB.MKBM_Pmax_ch)
            MKBM_Pmax_ch = BatDB.MKBM_Pmax_ch * N_Batteries;
        end
        if ~isnan(BatDB.MKBM_Pmax_dis)
            MKBM_Pmax_dis = BatDB.MKBM_Pmax_dis * N_Batteries;
        end
        if ~isnan(BatDB.MKBM_LifeCycles)
            MKBM_LifeCycles = BatDB.MKBM_LifeCycles;
        end
        if ~isnan(BatDB.MKBM_LifeDoD)
            MKBM_LifeDoD = BatDB.MKBM_LifeDoD;
        end
        if ~isnan(BatDB.MKBM_CalendarLife)
            MKBM_CalendarLife = BatDB.MKBM_CalendarLife;
        end
        % Optional temperature limits and self-discharge; NaN cell -> not created
        if ~isnan(BatDB.MKBM_MinChargeTemp)
            MKBM_MinChargeTemp = BatDB.MKBM_MinChargeTemp;
        end
        if ~isnan(BatDB.MKBM_MaxChargeTemp)
            MKBM_MaxChargeTemp = BatDB.MKBM_MaxChargeTemp;
        end
        if ~isnan(BatDB.MKBM_MinDischargeTemp)
            MKBM_MinDischargeTemp = BatDB.MKBM_MinDischargeTemp;
        end
        if ~isnan(BatDB.MKBM_MaxDischargeTemp)
            MKBM_MaxDischargeTemp = BatDB.MKBM_MaxDischargeTemp;
        end
        if ~isnan(BatDB.MKBM_SelfDischarge)
            MKBM_SelfDischarge = BatDB.MKBM_SelfDischarge;
        end

        fprintf('MKBM parameters loaded from database for %s.\n', Battery_Name);
    else
        % Manual mode
        Battery_Name = '';
        N_Batteries = 1;
        idx_offset = batOffset;

        %Battery model selection (1=Simple, 2=MKBM)
        if size(NUMERIC,1) >= 1+idx_offset && ~isnan(NUMERIC(1+idx_offset,3))
            BatteryModel = NUMERIC(1+idx_offset,3);
        else
            BatteryModel = 1;
        end

        %Battery type (1-5)
        if size(NUMERIC,1) >= 2+idx_offset && ~isnan(NUMERIC(2+idx_offset,3))
            BatteryType = NUMERIC(2+idx_offset,3);
        else
            BatteryType = 1;
        end

        %Optional parameters - only read if not NaN
        if size(NUMERIC,1) >= 3+idx_offset && ~isnan(NUMERIC(3+idx_offset,3))
            MKBM_c = NUMERIC(3+idx_offset,3);
        end

        if size(NUMERIC,1) >= 4+idx_offset && ~isnan(NUMERIC(4+idx_offset,3))
            MKBM_k = NUMERIC(4+idx_offset,3);
        end

        if size(NUMERIC,1) >= 5+idx_offset && ~isnan(NUMERIC(5+idx_offset,3))
            MKBM_eta_ch = NUMERIC(5+idx_offset,3);
        end

        if size(NUMERIC,1) >= 6+idx_offset && ~isnan(NUMERIC(6+idx_offset,3))
            MKBM_eta_dis = NUMERIC(6+idx_offset,3);
        end

        if size(NUMERIC,1) >= 7+idx_offset && ~isnan(NUMERIC(7+idx_offset,3))
            MKBM_Pmax_ch = NUMERIC(7+idx_offset,3);
        end

        if size(NUMERIC,1) >= 8+idx_offset && ~isnan(NUMERIC(8+idx_offset,3))
            MKBM_Pmax_dis = NUMERIC(8+idx_offset,3);
        end

        if size(NUMERIC,1) >= 9+idx_offset && ~isnan(NUMERIC(9+idx_offset,3))
            MKBM_LifeCycles = NUMERIC(9+idx_offset,3);
        end

        if size(NUMERIC,1) >= 10+idx_offset && ~isnan(NUMERIC(10+idx_offset,3))
            MKBM_LifeDoD = NUMERIC(10+idx_offset,3);
        end

        if size(NUMERIC,1) >= 11+idx_offset && ~isnan(NUMERIC(11+idx_offset,3))
            MKBM_CalendarLife = NUMERIC(11+idx_offset,3);
        end

        if size(NUMERIC,1) >= 12+idx_offset && ~isnan(NUMERIC(12+idx_offset,3))
            MKBM_MinChargeTemp = NUMERIC(12+idx_offset,3);
        end

        if size(NUMERIC,1) >= 13+idx_offset && ~isnan(NUMERIC(13+idx_offset,3))
            MKBM_MaxChargeTemp = NUMERIC(13+idx_offset,3);
        end

        if size(NUMERIC,1) >= 14+idx_offset && ~isnan(NUMERIC(14+idx_offset,3))
            MKBM_MinDischargeTemp = NUMERIC(14+idx_offset,3);
        end

        if size(NUMERIC,1) >= 15+idx_offset && ~isnan(NUMERIC(15+idx_offset,3))
            MKBM_MaxDischargeTemp = NUMERIC(15+idx_offset,3);
        end

        if size(NUMERIC,1) >= 16+idx_offset && ~isnan(NUMERIC(16+idx_offset,3))
            MKBM_SelfDischarge = NUMERIC(16+idx_offset,3);
        end

        fprintf('MKBM parameters loaded manually from Excel.\n');
    end

    fprintf('  Battery Model: %d (%s)\n', BatteryModel, ...
        ternary(BatteryModel==1, 'Simple', 'MKBM'));
    fprintf('  Battery Type: %d\n', BatteryType);

catch
    %Sheet doesn't exist - use defaults
    warning('BatteryMKBM sheet not found in input file. Using default values.');
    Use_Database_Bat = 1;
    Battery_Name = '';
    N_Batteries = 1;
    BatteryModel = 1;  %Use simple model by default for backward compatibility
    BatteryType = 1;   %Lead-acid by default
end

%Helper function for display
function result = ternary(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
