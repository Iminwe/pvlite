%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mainMultiYear.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Multi-year PVlite simulation with PV degradation and MKBM battery cycle life

%Clear workspace
if ~exist('run_as_test', 'var') || ~run_as_test
    clear;
end

disp('Reading inputs for multi-year simulation...');
ReadInputData;
disp('Inputs Ok');

% Multi-year initialization
total_energy_produced  = 0;   % PV + genset + wind (energia aprovechada)
total_pv_energy        = 0;  % EPVa  : PV tras perdidas y regulacion (recortado)
total_pv_energy_gross  = 0;  % EPV2a : PV tras temperatura y cableado DC, ANTES del recorte
total_pv_energy_ideal  = 0;  % EPV0a : PV ideal, sin perdidas ni recorte
total_genset_energy    = 0;  % EGENa
total_wind_energy      = 0;  % EWINDa
total_ac_energy        = 0;  % EACa  : energia servida a la carga
total_load_energy      = 0;  % ELOADa
pv_energy_by_year      = [];
genset_energy_by_year  = [];
total_fuel_consumed    = 0;
total_dump_energy      = 0;  % EDUMPa : dumped/excess energy that cannot be used
dump_energy_by_year    = [];
battery_replacements   = 0;
replacement_years      = [];
fuel_by_year           = [];

% Save original PVnom to apply degradation each year
PVnom_initial = PVnom;

% Multi-year battery SOH history for PlotBatteryDegradation
SOH_history = [];
% Samples where each battery unit starts its life: the first starts at sample 1
bat_segment_starts = 1;

fprintf('\nStarting %d-year simulation...\n', Project_Lifetime);

for current_year = 1:Project_Lifetime
    fprintf('\n--- Simulating Year %d ---\n', current_year);

    % Apply PV degradation
    PVnom = PVnom_initial * ((1 - PV_Degradation_Rate) ^ (current_year - 1));
    fprintf('PV Nominal Power: %.2f kW (Degradation applied: %.2f%%)\n', PVnom, (1 - PVnom/PVnom_initial)*100);

    % Generation of time series
    Irradiances;
    Temperatures;

    % PV power
    if(Mounting==2)
        PVpower_delta;
    else
        PVpower;
    end

    % Check battery EOL and replace if necessary
    if exist('BatParams', 'var') && BatParams.SOH < 0.80
        fprintf('*** BATTERY END-OF-LIFE REACHED. Replacing battery for Year %d ***\n', current_year);
        battery_replacements = battery_replacements + 1;
        replacement_years = [replacement_years, current_year];
        ResetBattery = 1;
    else
        ResetBattery = 0;
    end

    % Applications
    if (Application==1)
        mainGrid;
    elseif (Application==2)
        mainSA;
    elseif (Application==3 || Application==4)
        mainHybrid;
    elseif (Application==5)
        mainPump;
    end

    % Accumulate the battery SOH history for multi-year plotting
    if exist('SOH_mat', 'var') && ~isempty(SOH_mat)
        year_soh = SOH_mat(:);
        if exist('ResetBattery', 'var') && ResetBattery == 1
            % The battery was replaced before this year
            bat_segment_starts = [bat_segment_starts, length(SOH_history) + 1];
        end
        SOH_history = [SOH_history; year_soh];
    end

    % Accumulate multi-year stats
    if exist('EPVa', 'var')
        total_pv_energy = total_pv_energy + EPVa;
        pv_energy_by_year = [pv_energy_by_year, EPVa];
    end
    if exist('EPV2a', 'var')
        total_pv_energy_gross = total_pv_energy_gross + EPV2a;
    end
    if exist('EPV0a', 'var')
        total_pv_energy_ideal = total_pv_energy_ideal + EPV0a;
    end
    if exist('EGENa', 'var')
        total_genset_energy = total_genset_energy + EGENa;
        genset_energy_by_year = [genset_energy_by_year, EGENa];
    end
    if exist('EWINDa', 'var')
        total_wind_energy = total_wind_energy + EWINDa;
    end
    if exist('EDUMPa', 'var')
        total_dump_energy = total_dump_energy + EDUMPa;
        dump_energy_by_year = [dump_energy_by_year, EDUMPa];
    end
    if exist('EACa', 'var')
        total_ac_energy = total_ac_energy + EACa;
    end
    if exist('ELOADa', 'var')
        total_load_energy = total_load_energy + ELOADa;
    end
    total_energy_produced = total_pv_energy + total_genset_energy + total_wind_energy;
    if exist('FUEL', 'var')
        total_fuel_consumed = total_fuel_consumed + sum(sum(FUEL));
        fuel_by_year = [fuel_by_year, sum(sum(FUEL))];
    end
end

fprintf('\n==================================================\n');
fprintf('MULTI-YEAR SIMULATION RESULTS (%d YEARS)\n', Project_Lifetime);
fprintf('==================================================\n');
fprintf('Total Ideal PV Energy (EPV0a): %.2f kWh\n', total_pv_energy_ideal);
fprintf('Total Gross PV Energy (EPV2a, before regulation): %.2f kWh\n', total_pv_energy_gross);
fprintf('Total PV Energy (EPVa, after regulation): %.2f kWh\n', total_pv_energy);
fprintf('Total Genset Energy (EGENa): %.2f kWh\n', total_genset_energy);
fprintf('Total Energy Produced (PV+genset+wind): %.2f kWh\n', total_energy_produced);
fprintf('Total Load Demand (ELOADa): %.2f kWh\n', total_load_energy);
fprintf('Total Energy Served (EACa): %.2f kWh\n', total_ac_energy);

if (Application==3 || Application==4)
    fprintf('Total Fuel Consumed: %.2f liters\n', total_fuel_consumed);
    fprintf('Total Dumped/Excess Energy (EDUMPa): %.2f kWh\n', total_dump_energy);
end
fprintf('Total Battery Replacements: %d\n', battery_replacements);
if battery_replacements > 0
    fprintf('Replacement Years: %s\n', num2str(replacement_years));
end
if exist('BatParams', 'var')
    fprintf('Final Battery SOH at Year %d: %.2f%%\n', Project_Lifetime, BatParams.SOH * 100);
end

% HTML multi-year report generation has been removed.

EconomicsCalculations;
fprintf('==================================================\n');
