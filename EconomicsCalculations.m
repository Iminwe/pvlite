%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EconomicsCalculations.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculates CAPEX, OPEX and related economic metrics.
% Expected to run at the end of the simulation.

% Initialize totals
CAPEX = Fixed_Installation_Cost;

% PV Cost (PVnom in kWp, Cost in EUR/Wp)
% Uses installed power, not degraded: PVnom_initial from mainMultiYear.m,
% single-year runs fall back to PVnom
if exist('PVnom_initial', 'var') && ~isempty(PVnom_initial) && PVnom_initial > 0
    PV_Cost_Power = PVnom_initial;
elseif exist('PVnom', 'var')
    PV_Cost_Power = PVnom;
else
    PV_Cost_Power = 0;
end
PV_Total_Cost = PV_Cost_Power * 1000 * PV_Module_Cost;
CAPEX = CAPEX + PV_Total_Cost;

% Inverter Cost (PInom in kW, Cost in EUR/W); check PInom across applications
if exist('PInom', 'var')
    Inverter_Total_Cost = PInom * 1000 * Inverter_Cost;
    CAPEX = CAPEX + Inverter_Total_Cost;
else
    Inverter_Total_Cost = 0;
end

% Battery Cost (CBAT is in kWh, Cost in EUR/kWh)
if exist('CBAT', 'var')
    Battery_Total_Cost = CBAT * Battery_Cost;
    CAPEX = CAPEX + Battery_Total_Cost;
else
    Battery_Total_Cost = 0;
end

% Genset Cost (PGENnom is in kW, Cost in EUR/kW)
if exist('PGENnom', 'var')
    Genset_Total_Cost = PGENnom * Genset_Cost;
    CAPEX = CAPEX + Genset_Total_Cost;
else
    Genset_Total_Cost = 0;
end

% Wind Turbine Cost (PWnom in kW, Cost in EUR/kW), only when PWnom > 0
if exist('PWnom', 'var') && ~isempty(PWnom) && PWnom > 0 && exist('Wind_Cost', 'var')
    Wind_Total_Cost = PWnom * Wind_Cost;
    CAPEX = CAPEX + Wind_Total_Cost;
else
    Wind_Total_Cost = 0;
end


% OPEX (Annual)
OPEX_Annual = CAPEX * Opex_Factor;

% Battery replacement cost, discounted to present value. Future cost into the
% NPC, not into the initial CAPEX. Replacements from mainMultiYear.m, each at
% the price of the initial bank
Battery_Replacement_NPC = 0;
if exist('battery_replacements', 'var') && battery_replacements > 0 && ...
   exist('replacement_years', 'var') && ~isempty(replacement_years) && ...
   Battery_Total_Cost > 0
    for ii = 1:numel(replacement_years)
        rep_year = replacement_years(ii);
        % Only count replacements that occur within the project duration
        if rep_year > 0 && (~exist('Project_Lifetime', 'var') || rep_year <= Project_Lifetime)
            Battery_Replacement_NPC = Battery_Replacement_NPC + ...
                Battery_Total_Cost / ((1 + Discount_Rate) ^ rep_year);
        end
    end
end

% Genset fuel cost, discounted to present value. fuel_by_year (mainMultiYear.m)
% captures the extra fuel burned as the PV field degrades
Fuel_Cost_NPC = 0;
Annual_Fuel_Cost = 0;
if exist('Fuel_Cost', 'var') && Fuel_Cost > 0
    if exist('fuel_by_year', 'var') && ~isempty(fuel_by_year)
        Annual_Fuel_Cost = mean(fuel_by_year) * Fuel_Cost;
        for yy = 1:numel(fuel_by_year)
            if Discount_Rate > 0
                Fuel_Cost_NPC = Fuel_Cost_NPC + fuel_by_year(yy) * Fuel_Cost / ((1 + Discount_Rate)^yy);
            else
                Fuel_Cost_NPC = Fuel_Cost_NPC + fuel_by_year(yy) * Fuel_Cost;
            end
        end
    elseif exist('FUEL', 'var')
        Annual_Fuel_Cost = sum(sum(FUEL)) * Fuel_Cost;
        if exist('Project_Lifetime', 'var') && Project_Lifetime > 0
            if Discount_Rate > 0
                Fuel_Cost_NPC = Annual_Fuel_Cost * (1 - (1 + Discount_Rate)^(-Project_Lifetime)) / Discount_Rate;
            else
                Fuel_Cost_NPC = Annual_Fuel_Cost * Project_Lifetime;
            end
        else
            Fuel_Cost_NPC = Annual_Fuel_Cost;
        end
    end
end

% Net Present Cost (NPC) over Project_Lifetime
if exist('Project_Lifetime', 'var') && Project_Lifetime > 0
    if Discount_Rate > 0
        % Calculate present value of an annuity factor (PVA)
        PVA_factor = (1 - (1 + Discount_Rate)^(-Project_Lifetime)) / Discount_Rate;
    else
        PVA_factor = Project_Lifetime;
    end
    
    NPC = CAPEX + OPEX_Annual * PVA_factor + Battery_Replacement_NPC + Fuel_Cost_NPC;
    
    % Annualized Cost
    if Discount_Rate > 0
        CRF = (Discount_Rate * (1 + Discount_Rate)^Project_Lifetime) / ((1 + Discount_Rate)^Project_Lifetime - 1);
        Annualized_Cost = NPC * CRF;
    else
        Annualized_Cost = NPC / Project_Lifetime;
    end
else
    NPC = CAPEX + OPEX_Annual + Battery_Replacement_NPC + Fuel_Cost_NPC; % Fallback if lifetime is not properly defined
    Annualized_Cost = NPC;
end

% Display Results
fprintf('\n==================================================\n');
fprintf('ECONOMIC ANALYSIS\n');
fprintf('==================================================\n');
fprintf('PV Array Cost:           € %.2f\n', PV_Total_Cost);
if Inverter_Total_Cost > 0
    fprintf('Inverter Cost:           € %.2f\n', Inverter_Total_Cost);
end
if Battery_Total_Cost > 0
    fprintf('Battery Bank Cost:       € %.2f\n', Battery_Total_Cost);
end
if Genset_Total_Cost > 0
    fprintf('Genset Cost:             € %.2f\n', Genset_Total_Cost);
end
if Wind_Total_Cost > 0
    fprintf('Wind Turbine Cost:       € %.2f\n', Wind_Total_Cost);
end
fprintf('Fixed Installation Cost: € %.2f\n', Fixed_Installation_Cost);
fprintf('--------------------------------------------------\n');
fprintf('Total Initial CAPEX:     € %.2f\n', CAPEX);
fprintf('Annual OPEX:             € %.2f/year\n', OPEX_Annual);
if Battery_Replacement_NPC > 0
    fprintf('Battery Replacements:    %d (year(s): %s)\n', battery_replacements, num2str(replacement_years));
    fprintf('Battery Replacement Cost (NPC): € %.2f\n', Battery_Replacement_NPC);
end
if Fuel_Cost_NPC > 0
    fprintf('Genset Fuel Cost (NPC):  € %.2f\n', Fuel_Cost_NPC);
end
fprintf('Project Lifetime:        %d years\n', Project_Lifetime);
fprintf('Discount Rate:           %.2f%%\n', Discount_Rate * 100);
fprintf('Net Present Cost (NPC):  € %.2f\n', NPC);
fprintf('Annualized Cost:         € %.2f/year\n', Annualized_Cost);
fprintf('==================================================\n');

% Plot Economics if requested
if exist('PlotEconomicsFlag', 'var') && PlotEconomicsFlag == 1
    PlotEconomics;
end