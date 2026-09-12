%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CompareBatteryModels.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compares the original Basic Battery Model vs MKBM: runs both sequentially
% and plots degradation, SOC and Sankey diagrams
% IMPORTANT: run pvlite first so input data is loaded into the workspace

if ~exist('Application', 'var')
    error('Input data not found. Please run "pvlite" and select your Excel file first.');
end

if Application ~= 2 && Application ~= 3 && Application ~= 4
    error('Comparison is only available for Stand-alone (2), Hybrid DC (3), and Hybrid AC (4) systems.');
end

disp('======================================================');
disp('   STARTING COMPARISON: BASIC MODEL vs MKBM MODEL');
disp('======================================================');

%% --- 1. SIMULATE BASIC MODEL ---
disp('>> Running Basic Model Simulation...');
BatteryModel = 1; % Force Basic Model

if Application == 2
    PowerCalculations;
    DailyParameters;
    MonthlyParameters;
    YearlyParameters;
    SankeySA;
    f_sankey_basic = gcf;
    set(f_sankey_basic, 'Name', 'Sankey Diagram - BASIC MODEL');
elseif Application == 3
    PowerCalculationsHybrid_DCbus;
    DailyParameters;
    MonthlyParameters;
    YearlyParameters;
    SankeyHybrid_DCbus;
    f_sankey_basic = gcf;
    set(f_sankey_basic, 'Name', 'Sankey Diagram - BASIC MODEL');
elseif Application == 4
    PowerCalculationsHybrid_ACbus;
    DailyParameters;
    MonthlyParameters;
    YearlyParameters;
    SankeyHybrid_ACbus;
    f_sankey_basic = gcf;
    set(f_sankey_basic, 'Name', 'Sankey Diagram - BASIC MODEL');
end

% Save Basic Model results
SOC_basic = SOC;
% Basic model assumes no degradation (SOH = 100%, Capacity = CBAT)
SOH_basic = ones(1, Ndays * Nsteps); 
Qmax_basic = ones(1, Ndays * Nsteps) * CBAT;


%% --- 2. SIMULATE MKBM MODEL ---
disp('>> Running MKBM Model Simulation...');
BatteryModel = 2; % Force MKBM Model

% Ensure a fresh battery state for MKBM simulation. Starting from SOH = 1
if exist('BatParams', 'var')
    clear BatParams Q1_prev Q2_prev;
end
ResetBattery = 1;

% Reset solar generation data before the second simulation
disp('   Resetting solar generation data...');
if(Mounting==2)
    PVpower_delta;
else
    PVpower;
end

if Application == 2
    PowerCalculations_MKBM;
    DailyParameters;
    MonthlyParameters;
    YearlyParameters;
    SankeySA;
    f_sankey_mkbm = gcf;
    set(f_sankey_mkbm, 'Name', 'Sankey Diagram - MKBM MODEL');
elseif Application == 3
    PowerCalculationsHybrid_MKBM;
    DailyParameters;
    MonthlyParameters;
    YearlyParameters;
    SankeyHybrid_DCbus;
    f_sankey_mkbm = gcf;
    set(f_sankey_mkbm, 'Name', 'Sankey Diagram - MKBM MODEL');
elseif Application == 4
    PowerCalculationsHybrid_MKBM_ACbus;
    DailyParameters;
    MonthlyParameters;
    YearlyParameters;
    SankeyHybrid_ACbus;
    f_sankey_mkbm = gcf;
    set(f_sankey_mkbm, 'Name', 'Sankey Diagram - MKBM MODEL');
end

% Save MKBM Model results
SOC_mkbm = SOC;
SOH_mkbm = SOH_mat(:)';
Qmax_mkbm = SOH_mkbm * BatParams.Qmax_initial;

%% --- 3. GENERATE COMPARATIVE PLOTS ---
disp('>> Generating Comparative Plots...');
if exist('Stepph', 'var')
    t_hours = (1:(Ndays * Nsteps)) / Stepph;
else
    t_hours = 1:(Ndays * Nsteps);
end

% --- Plot 1: Degradation Comparison ---
f1 = figure('Name', 'Degradation Comparison: Basic vs MKBM', 'Position', [100, 100, 900, 500]);
plot(t_hours, SOH_basic * 100, '--g', 'LineWidth', 2);
hold on;
plot(t_hours, SOH_mkbm * 100, 'b', 'LineWidth', 2);
title('Battery Degradation (State of Health) over 1 Year');
xlabel('Time (Hours)');
ylabel('State of Health - SOH (%)');
legend('Basic Model (Ideal / No Degradation)', 'MKBM Model (Realistic Aging)', 'Location', 'southwest');
grid on;
ylim([min(SOH_mkbm)*100 - 1, 105]);

% --- Plot 2: Capacity Fade Comparison ---
f2 = figure('Name', 'Capacity Comparison: Basic vs MKBM', 'Position', [150, 150, 900, 500]);
plot(t_hours, Qmax_basic, '--g', 'LineWidth', 2);
hold on;
plot(t_hours, Qmax_mkbm, 'r', 'LineWidth', 2);
title('Maximum Capacity Evolution over 1 Year');
xlabel('Time (Hours)');
ylabel('Maximum Capacity (kWh)');
legend(sprintf('Basic Model (Fixed: %.1f kWh)', CBAT), 'MKBM Model (Capacity Fade)', 'Location', 'southwest');
grid on;
ylim([min(Qmax_mkbm) - (CBAT*0.05), CBAT * 1.1]);

% --- Plot 3: SOC Behavior Comparison (Sample Week in Winter) ---
f3 = figure('Name', 'SOC Behavior Comparison (Sample Week)', 'Position', [200, 200, 900, 500]);
% Plot a 7-day winter period (hours 1-168). Stepph = steps per hour, so
% 168 real hours span 168*Stepph samples
if exist('Stepph', 'var') && ~isempty(Stepph) && Stepph > 0
    plot_range = 1:min(168 * Stepph, length(t_hours));
else
    plot_range = 1:min(168, length(t_hours));
end
plot(t_hours(plot_range), SOC_basic(plot_range) * 100, '--g', 'LineWidth', 2);
hold on;
plot(t_hours(plot_range), SOC_mkbm(plot_range) * 100, 'b', 'LineWidth', 1.5);
title('State of Charge (SOC) Behavior - First Week of January');
xlabel('Time (Hours)');
ylabel('State of Charge - SOC (%)');
legend('Basic Model', 'MKBM Model (Includes Losses & Self-Discharge)', 'Location', 'southwest');
grid on;

disp('======================================================');
disp('   COMPARISON COMPLETE');
disp('======================================================');