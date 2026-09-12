%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PowerCalculations_MKBM.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Power calculations using Modified Kinetic Battery Model (MKBM)
%This script replaces the original PowerCalculations.m when using lithium-ion

%Matrix initialisation to zero
PDC=zeros(Nsteps, Ndays);
pdc=zeros(Nsteps, Ndays);
PAC0=zeros(Nsteps, Ndays);
PAC1=zeros(Nsteps, Ndays);
PAC=zeros(Nsteps, Ndays);
PBAT=zeros(Nsteps, Ndays);
SOC=zeros(Nsteps, Ndays);
Q1_mat=zeros(Nsteps, Ndays);  %Available energy tank (MKBM)
Q2_mat=zeros(Nsteps, Ndays);  %Bound energy tank (MKBM)
Cuse=zeros(Nsteps, Ndays);
LLH=zeros(Nsteps, Ndays);
OVC=zeros(Nsteps, Ndays);
OVD=zeros(Nsteps, Ndays);
ETAI=zeros(Nsteps, Ndays); %Inverter efficiency
ELOSS_BAT=zeros(Nsteps, Ndays); %Battery losses (MKBM)

%Normalised load power at the inverter output
PAC=PLOAD;
PAC1=PLOAD;
PAC0=PAC1./((1-(WAC/100)*(PAC1/PInom)));
pac=PAC0/PInom;

%Checking maximum load vs maximum inverter power
if PImax<max(max(PAC0))
    disp('Attention: Undersized inverter')
    Maximum_Inverter_Power=PImax
    Maximum_Load_Power=max(max(PAC0))
    error('Simulation stopped: increase the maximum inverter power');
end

%Initialize MKBM battery model
if ~exist('BatParams', 'var') || (exist('ResetBattery', 'var') && ResetBattery == 1)
    %Check if BatteryType is defined, default to lithium LFP (type 2)
if ~exist('BatteryType', 'var')
    BatteryType = 2; %Default: Li-ion LFP
    disp('BatteryType not defined. Using default: Li-ion LFP (type 2)');
end

%Check for custom MKBM parameters
if exist('MKBM_c', 'var') && exist('MKBM_k', 'var')
    %Use custom parameters from input file
    [Q1_prev, Q2_prev, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType, 'c', MKBM_c, 'k', MKBM_k);
elseif exist('MKBM_c', 'var')
    [Q1_prev, Q2_prev, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType, 'c', MKBM_c);
elseif exist('MKBM_k', 'var')
    [Q1_prev, Q2_prev, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType, 'k', MKBM_k);
else
    %Use default parameters for battery type
    [Q1_prev, Q2_prev, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType);
end

%Add battery parameters from the input file; NaN (empty CSV cells) rejected
if exist('MKBM_eta_ch', 'var') && ~isnan(MKBM_eta_ch)
    BatParams.eta_ch = MKBM_eta_ch;
end
if exist('MKBM_eta_dis', 'var') && ~isnan(MKBM_eta_dis)
    BatParams.eta_dis = MKBM_eta_dis;
end
if exist('MKBM_Pmax_ch', 'var') && ~isnan(MKBM_Pmax_ch)
    BatParams.Pmax_ch = MKBM_Pmax_ch;
end
if exist('MKBM_Pmax_dis', 'var') && ~isnan(MKBM_Pmax_dis)
    BatParams.Pmax_dis = MKBM_Pmax_dis;
end

%Time step in hours for MKBM
dt = 1/Stepph;

%Ah-Throughput aging init. LifeCycles / LifeDoD are a spec pair (cycles at a DoD)
if exist('MKBM_LifeCycles', 'var') && exist('MKBM_LifeDoD', 'var') && ~isnan(MKBM_LifeCycles) && ~isnan(MKBM_LifeDoD)
    BatParams.LifeCycles = MKBM_LifeCycles;
    BatParams.LifeDoD = MKBM_LifeDoD;
else
    % Default: 6000 cycles at 80% DoD if not specified
    BatParams.LifeCycles = 6000;
    BatParams.LifeDoD = 0.8;
end
BatParams.TotalEnergyThroughput = BatParams.Qmax * BatParams.LifeCycles * BatParams.LifeDoD;

%Calendar Aging Initialization
if exist('MKBM_CalendarLife', 'var') && ~isnan(MKBM_CalendarLife)
    BatParams.CalendarLife = MKBM_CalendarLife;
    % EOL default: 80% SOH (20% capacity fade over calendar life)
    BatParams.CalendarFadePerHour = 0.2 / (BatParams.CalendarLife * 365 * 24);
else
    BatParams.CalendarFadePerHour = 0; % No calendar aging if not specified
end
BatParams.CalendarFadeAccumulated = 0;

BatParams.Qmax_initial = BatParams.Qmax;
BatParams.Pmax_ch_initial = BatParams.Pmax_ch;
BatParams.Pmax_dis_initial = BatParams.Pmax_dis;
BatParams.EnergyDischarged = 0;
BatParams.SOH = 1.0;
SOH_mat = ones(Nsteps, Ndays); % State of Health tracking matrix

%Temperature Limits & Self Discharge Initialization
if exist('MKBM_MinChargeTemp', 'var') && ~isnan(MKBM_MinChargeTemp), BatParams.MinChargeTemp = MKBM_MinChargeTemp; end
if exist('MKBM_MaxChargeTemp', 'var') && ~isnan(MKBM_MaxChargeTemp), BatParams.MaxChargeTemp = MKBM_MaxChargeTemp; end
if exist('MKBM_MinDischargeTemp', 'var') && ~isnan(MKBM_MinDischargeTemp), BatParams.MinDischargeTemp = MKBM_MinDischargeTemp; end
if exist('MKBM_MaxDischargeTemp', 'var') && ~isnan(MKBM_MaxDischargeTemp), BatParams.MaxDischargeTemp = MKBM_MaxDischargeTemp; end
if exist('MKBM_SelfDischarge', 'var') && ~isnan(MKBM_SelfDischarge)
    % Convert % per month to a fraction per hour (assuming 30 days/month)
    BatParams.SelfDischargeRate = (MKBM_SelfDischarge / 100) / (30 * 24);
end
end

%Calculations
for d=1:Ndays
    for h=1:Nsteps
        %Power at the inverter input
        pdc(h,d)=pac(h,d) + k0 + k1*pac(h,d) + k2*(pac(h,d)^2);
        PDC(h,d)=pdc(h,d)*PInom;

        %Inverter efficiency
        if pdc(h,d) > 0
            ETAI(h,d)=pac(h,d)/pdc(h,d);
        else
            ETAI(h,d)=0;
        end

        %Battery power request (positive = charge, negative = discharge)
        Pbat_req = PPV(h,d) - PDC(h,d);
        
        % Apply Power Fade (Aging) base limits
        current_Pmax_ch = BatParams.Pmax_ch_initial * BatParams.SOH;
        current_Pmax_dis = BatParams.Pmax_dis_initial * BatParams.SOH;
        
        % Apply Temperature Operational Limits
        if isfield(BatParams, 'MinChargeTemp') && Ta(h,d) < BatParams.MinChargeTemp
            current_Pmax_ch = 0;
        end
        if isfield(BatParams, 'MaxChargeTemp') && Ta(h,d) > BatParams.MaxChargeTemp
            current_Pmax_ch = 0;
        end
        if isfield(BatParams, 'MinDischargeTemp') && Ta(h,d) < BatParams.MinDischargeTemp
            current_Pmax_dis = 0;
        end
        if isfield(BatParams, 'MaxDischargeTemp') && Ta(h,d) > BatParams.MaxDischargeTemp
            current_Pmax_dis = 0;
        end
        
        BatParams.Pmax_ch = current_Pmax_ch;
        BatParams.Pmax_dis = current_Pmax_dis;
        
        %Call MKBM battery model
        [SOC_new, Q1_new, Q2_new, Pbat_actual, Eloss] = BatteryMKBM(Pbat_req, dt, Q1_prev, Q2_prev, BatParams);

        %True when the loss-of-load branch recomputes the battery step
        battery_step_revised = false;

        %Check for loss of load (requested more discharge than available)
        if Pbat_req < 0 && abs(Pbat_actual) < abs(Pbat_req) * 0.99
            %Check if this causes loss of load
            if PPV(h,d) + abs(Pbat_actual) < PDC(h,d) * 0.99
                %Inverter switches off
                InverterOFF;
                %Loss of load hours flag
                LLH(h,d) = 1;
                %Overdischarge flag (battery reached minimum SOC)
                OVD(h,d) = 1;
                %Inverter off: battery only receives PV power. Step recomputed
                %from the previous state even when PPV is zero, so relaxation and
                %self-discharge still apply.
                Pbat_req_new = max(0, PPV(h,d));
                [SOC_new, Q1_new, Q2_new, Pbat_actual, Eloss] = ...
                    BatteryMKBM(Pbat_req_new, dt, Q1_prev, Q2_prev, BatParams);
                battery_step_revised = true;
                %PV can only go to the battery: curtail what it does not accept
                PPV_used = max(0, Pbat_actual);
                if PPV(h,d) > PPV_used + 1e-9
                    OVC(h,d) = 1;
                end
                PPV(h,d) = PPV_used;
                PPV3(h,d) = PPV_used;
            end
        end

        %Store MKBM state variables
        SOC(h,d) = SOC_new;
        Q1_mat(h,d) = Q1_new;
        Q2_mat(h,d) = Q2_new;
        ELOSS_BAT(h,d) = Eloss;
        PBAT(h,d) = Pbat_actual;

        %Check for overcharge (battery full, excess power)
        if ~battery_step_revised && Pbat_req > 0 && Pbat_actual < Pbat_req * 0.99
            %Could not charge all available power
            OVC(h,d) = 1;
            %Reduce PV power to match what battery can accept plus load
            P_excess = Pbat_req - Pbat_actual;
            PPV(h,d) = PPV(h,d) - P_excess;
            %PV losses caused by battery "saturation"
            PPV3(h,d) = PPV(h,d);
        end

        %Update degradation (cycling + calendar) AFTER the final battery solution
        if Pbat_actual < 0
            % Discharging: accumulate energy for cycling aging
            BatParams.EnergyDischarged = BatParams.EnergyDischarged + abs(Pbat_actual) * dt;
        end

        % Accumulate calendar aging for this time step
        BatParams.CalendarFadeAccumulated = BatParams.CalendarFadeAccumulated + (BatParams.CalendarFadePerHour * dt);

        % Update SOH from both mechanisms. TotalEnergyThroughput = energy to 80% SOH
        BatParams.SOH = 1.0 - 0.2 * (BatParams.EnergyDischarged / BatParams.TotalEnergyThroughput) - BatParams.CalendarFadeAccumulated;

        % Prevent SOH from dropping below 0
        if BatParams.SOH < 0
            BatParams.SOH = 0;
        end

        % Capacity Fade: Update maximum capacity
        BatParams.Qmax = BatParams.Qmax_initial * BatParams.SOH;

        SOH_mat(h,d) = BatParams.SOH;

        %Available capacity for discharge (compatibility with existing code)
        Cuse(h,d) = (SOC(h,d) - SOCmin) * CBAT;

        %Update state for next time step
        Q1_prev = Q1_mat(h,d);
        Q2_prev = Q2_mat(h,d);
    end
end

%Display battery performance summary
fprintf('\n=== Battery MKBM Performance Summary ===\n');
fprintf('Total battery losses: %.2f kWh\n', sum(sum(ELOSS_BAT)));
fprintf('Energy discharged: %.2f kWh\n', BatParams.EnergyDischarged);
fprintf('Final SOH (State of Health): %.2f%%\n', BatParams.SOH * 100);
fprintf('Final Qmax (Capacity Fade): %.2f kWh\n', BatParams.Qmax);
fprintf('Final Pmax_ch / Pmax_dis (Power Fade): %.2f kW / %.2f kW\n', BatParams.Pmax_ch, BatParams.Pmax_dis);
fprintf('Loss of load events: %d steps = %.2f hours\n', sum(sum(LLH)), sum(sum(LLH))/Stepph);
fprintf('Overcharge events: %d steps = %.2f hours\n', sum(sum(OVC)), sum(sum(OVC))/Stepph);
fprintf('Overdischarge events: %d steps = %.2f hours\n', sum(sum(OVD)), sum(sum(OVD))/Stepph);
fprintf('Final SOC: %.1f%%\n', SOC(end,end)*100);
fprintf('Min SOC reached: %.1f%%\n', min(min(SOC))*100);
fprintf('Max SOC reached: %.1f%%\n', max(max(SOC))*100);

% End of Life (EOL) Warning
if BatParams.SOH < 0.80
    fprintf('\n********************************************************\n');
    fprintf('*** WARNING: BATTERY END-OF-LIFE (EOL) REACHED       ***\n');
    fprintf('********************************************************\n');
    fprintf('The battery SOH has fallen below 80%% during this 1-year\n');
    fprintf('simulation. This indicates severe undersizing or highly\n');
    fprintf('aggressive usage. Battery replacement is required.\n');
    fprintf('********************************************************\n');
end
