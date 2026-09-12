%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PowerCalculationsHybrid_MKBM_ACbus.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Power calculations for hybrid AC bus systems using Modified Kinetic Battery Model (MKBM)

%Matrix initialisation to zero
PDC=zeros(Nsteps, Ndays);
pdc=zeros(Nsteps, Ndays);
PAC0=zeros(Nsteps, Ndays);
PAC1=zeros(Nsteps, Ndays);
PAC=zeros(Nsteps, Ndays);
PBAT=zeros(Nsteps, Ndays); %Battery power (>0 charge, <0 discharge)
SOC=zeros(Nsteps, Ndays);
Q1_mat=zeros(Nsteps, Ndays);  %Available energy tank (MKBM)
Q2_mat=zeros(Nsteps, Ndays);  %Bound energy tank (MKBM)
Cuse=zeros(Nsteps, Ndays);
LLH=zeros(Nsteps, Ndays);
OVC=zeros(Nsteps, Ndays); %Overcharge flag
OVD=zeros(Nsteps, Ndays); %Overdischarge flag
PGEN=zeros(Nsteps, Ndays); %Genset power
GENON=zeros(Nsteps, Ndays); %Genset ON flag
PTOT=zeros(Nsteps, Ndays); %Total power generation
FUEL=zeros(Nsteps, Ndays); %Fuel consumption
PWIND=zeros(Nsteps, Ndays); %Wind power
ETAI=zeros(Nsteps, Ndays); %Inverter efficiency
ELOSS_BAT=zeros(Nsteps, Ndays); %Battery losses (MKBM)
PDUMP=zeros(Nsteps, Ndays); %Dumped/excess power that cannot be used (kW)

%If TMY is not selected as input data, the wind speed is set to zero
if(InputData==1 || InputData==2 || InputData==4)
    Wind=zeros(Nsteps, Ndays); %Wind speed
end

%Normalised load power at the inverter output
PAC=PLOAD;
PAC1=PLOAD;
PAC0=PAC1./((1-(WAC/100)*(PAC1/PInom)));

%Mixed node configuration (AC and DC coupled PV)
if ~exist('PV_DC_share', 'var')
    PV_DC_share = 0.5; % Default to 50% PV on DC bus, 50% on AC bus
end
PPV_AC = PPV * (1 - PV_DC_share);
PPV_DC = PPV * PV_DC_share;

%Calculate AC power from PV using Grid Inverter
ACpowerGridInverter;

%Initialize MKBM battery model
if ~exist('BatParams', 'var') || (exist('ResetBattery', 'var') && ResetBattery == 1)
    %Check if BatteryType is defined, default to lithium LFP (type 2)
    if ~exist('BatteryType', 'var')
        BatteryType = 2; %Default: Li-ion LFP
        disp('BatteryType not defined. Using default: Li-ion LFP (type 2)');
    end

    %Check for custom MKBM parameters
    if exist('MKBM_c', 'var') && exist('MKBM_k', 'var')
        [Q1_prev, Q2_prev, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType, 'c', MKBM_c, 'k', MKBM_k);
    elseif exist('MKBM_c', 'var')
        [Q1_prev, Q2_prev, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType, 'c', MKBM_c);
    elseif exist('MKBM_k', 'var')
        [Q1_prev, Q2_prev, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType, 'k', MKBM_k);
    else
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

    %Ah-Throughput aging init. LifeCycles / LifeDoD are a spec pair (cycles at a DoD)
    if exist('MKBM_LifeCycles', 'var') && exist('MKBM_LifeDoD', 'var') && ~isnan(MKBM_LifeCycles) && ~isnan(MKBM_LifeDoD)
        BatParams.LifeCycles = MKBM_LifeCycles;
        BatParams.LifeDoD = MKBM_LifeDoD;
    else
        % Default: 6000 cycles at 80% DoD
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

%Time step in hours for MKBM
dt = 1/Stepph;

SOH_mat = ones(Nsteps, Ndays); % State of Health tracking matrix

%Initial genset state
GENON_prev = 0;

%Calculations
for d=1:Ndays
    for h=1:Nsteps
        
        %SOC for genset control, from the faded Qmax so it matches BatteryMKBM
        SOC_current = (Q1_prev + Q2_prev) / BatParams.Qmax;
        
        %Genset control based on SOC
        if(SOC_current < SOCstart)
            %Genset start
            GENON(h,d) = 1;
            PGEN(h,d) = PGENnom;
        elseif (SOC_current >= SOCstart && SOC_current <= SOCstop && GENON_prev == 1)
            %Genset continues running
            GENON(h,d) = 1;
            PGEN(h,d) = PGENnom;
        elseif (SOC_current > SOCstop && GENON_prev == 1)
            %Genset stops
            GENON(h,d) = 0;
            PGEN(h,d) = 0;
        else
            GENON(h,d) = 0;
            PGEN(h,d) = 0;
        end
        GENON_prev = GENON(h,d);

        %Fuel consumption, liter
        if(PGENnom == 0 || GENON(h,d) == 0)
            FUEL(h,d) = 0;
        else
            FUEL(h,d) = ((b0i + b1i*PGENnom) + (b0s + b1s*PGENnom)*PGEN(h,d)) / Stepph;
        end

        %Wind power, kW
        if(Wind(h,d) <= Vci || Wind(h,d) > Vco)
            PWIND(h,d) = 0;
        elseif (Wind(h,d) > Vci && Wind(h,d) < Vnom)
            PWIND(h,d) = Cpeq * (Wind(h,d)^3 - Vci^3);
        elseif (Wind(h,d) >= Vnom && Wind(h,d) <= Vco)
            PWIND(h,d) = PWnom;
        end

        %Removes wind power from simulation if not configured
        if(PWnom == 0)
            PWIND(h,d) = 0;
        end

        %Total generated power on AC bus
        PTOT(h,d)=PAC_g(h,d)+PGEN(h,d)+PWIND(h,d);

        %Net AC power:
        P_AC_NET = PTOT(h,d) - PLOAD(h,d);

        %Per-step bookkeeping for the dump variable
        rect_AC_in = 0;           %AC power accepted by the bidirectional inverter
        rect_DC_out = 0;          %DC power the rectifier delivers to the battery
        dump_DC_curtailment = 0;  %DC-coupled PV curtailed while the inverter is OFF
        
        %If P_AC_NET > 0, charging battery. Needs to pass through bidirectional inverter (rectifier).
        if P_AC_NET > 0
            pac(h,d) = P_AC_NET / PInom;
            if pac(h,d) > PImax/PInom
                pac(h,d) = PImax/PInom; %Saturation of rectifier
            end
            pdc(h,d) = pac(h,d) - (k0 + k1*pac(h,d) + k2*(pac(h,d)^2));
            if pdc(h,d) < 0
                pdc(h,d) = 0;
            end
            PBAT_from_AC = pdc(h,d) * PInom;
            %What the rectifier really took from the AC bus and what it delivered
            rect_AC_in = pac(h,d) * PInom;
            rect_DC_out = PBAT_from_AC;
            
            % Total battery power (DC PV + Rectified AC excess)
            Pbat_req = PBAT_from_AC + PPV_DC(h,d);
            PDC(h,d) = 0; %No DC load
        else
            %Discharging battery to cover AC deficit
            pac(h,d) = abs(P_AC_NET) / PInom;
            if pac(h,d) > PImax/PInom
                pac(h,d) = PImax/PInom;
            end
            pdc(h,d) = pac(h,d) + k0 + k1*pac(h,d) + k2*(pac(h,d)^2);
            P_DC_req = pdc(h,d) * PInom;
            
            % Battery power is DC PV minus DC required for AC inverter
            Pbat_req = PPV_DC(h,d) - P_DC_req; 
            PDC(h,d) = 0;
        end
        
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
            %Could not supply all requested power
            %Battery cannot feed the DC the bidirectional inverter needs: switch it off
            InverterOFF;
            %Loss of load flag
            LLH(h,d) = 1;
            %Overdischarge flag
            OVD(h,d) = 1;

            %Inverter OFF: the battery only sees DC PV. Step recomputed from the
            %previous state even when PPV_DC is zero, so relaxation and self-discharge apply.
            PPV_DC_prev = PPV_DC(h,d);
            Pbat_req_new = max(0, PPV_DC_prev);
            [SOC_new, Q1_new, Q2_new, Pbat_actual, Eloss] = BatteryMKBM(Pbat_req_new, dt, Q1_prev, Q2_prev, BatParams);
            battery_step_revised = true;

            %Curtail the DC PV that the battery does not accept
            PPV_DC_used = min(PPV_DC_prev, max(0, Pbat_actual));
            PPV_DC(h,d) = PPV_DC_used;
            if PPV_DC_prev > PPV_DC_used + 1e-9
                OVC(h,d) = 1;
                PV_curtail = PPV_DC_prev - PPV_DC_used;
                PPV(h,d) = max(0, PPV(h,d) - PV_curtail);
                PPV3(h,d) = max(0, PPV3(h,d) - PV_curtail);
                %Inverter OFF: this DC-coupled PV cannot reach the AC bus either,
                %so it is dumped, not lost in a converter.
                dump_DC_curtailment = PV_curtail;
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
            %AC-bus flow was already solved above: PAC_g from ACpowerGridInverter,
            %PTOT / P_AC_NET built from it BEFORE the battery call. Curtailing
            %PPV / PWIND / PPV3 here cannot change the physics; it only corrupted
            %the reported PV yield (EPVa) and saturation losses (EPV3a).

            %Overcharge flag: charge-side refusal
            OVC(h,d) = 1;
        end

        %Dumped/excess AC power by cause: inverter saturation, battery refusal, DC curtailment
        %Converter losses are not dump: rect_AC_in - rect_DC_out and ELOSS_BAT, counted separately
        dump_AC_saturation   = max(0, P_AC_NET - rect_AC_in);
        dump_battery_refusal = max(0, Pbat_req - max(0, Pbat_actual));
        PDUMP(h,d) = dump_AC_saturation + dump_battery_refusal + dump_DC_curtailment;

        %Update Degradation (Cycling + Calendar) AFTER the final battery solution of the step
        if Pbat_actual < 0
            % Discharging: accumulate energy for cycling aging
            BatParams.EnergyDischarged = BatParams.EnergyDischarged + abs(Pbat_actual) * dt;
        end

        % Accumulate calendar aging for this time step
        BatParams.CalendarFadeAccumulated = BatParams.CalendarFadeAccumulated + (BatParams.CalendarFadePerHour * dt);

        % Update overall SOH combining both degradation mechanisms
        BatParams.SOH = 1.0 - 0.2 * (BatParams.EnergyDischarged / BatParams.TotalEnergyThroughput) - BatParams.CalendarFadeAccumulated;

        % Prevent SOH from dropping below 0
        if BatParams.SOH < 0
            BatParams.SOH = 0;
        end

        % Capacity Fade: Update maximum capacity
        BatParams.Qmax = BatParams.Qmax_initial * BatParams.SOH;

        SOH_mat(h,d) = BatParams.SOH;

        %Available capacity for discharge (for compatibility)
        Cuse(h,d) = (SOC(h,d) - SOCmin) * CBAT;

        %Update state for next time step
        Q1_prev = Q1_mat(h,d);
        Q2_prev = Q2_mat(h,d);
    end
end

%Reported PV power: PAC_g (AC-coupled grid inverter) + PPV_DC (surviving DC PV)
PPV = PAC_g + PPV_DC;

%Display battery performance summary
fprintf('\n=== Battery MKBM Performance Summary (AC Bus Hybrid) ===\n');
fprintf('Total battery losses: %.2f kWh\n', sum(sum(ELOSS_BAT)));
fprintf('Energy discharged: %.2f kWh\n', BatParams.EnergyDischarged);
fprintf('Final SOH (State of Health): %.2f%%\n', BatParams.SOH * 100);
fprintf('Final Qmax (Capacity Fade): %.2f kWh\n', BatParams.Qmax);
fprintf('Final Pmax_ch / Pmax_dis (Power Fade): %.2f kW / %.2f kW\n', BatParams.Pmax_ch, BatParams.Pmax_dis);
fprintf('Total fuel consumption: %.2f liters\n', sum(sum(FUEL)));
fprintf('Genset operating hours: %d steps = %.2f hours\n', sum(sum(GENON)), sum(sum(GENON))/Stepph);
fprintf('Loss of load events: %d steps = %.2f hours\n', sum(sum(LLH)), sum(sum(LLH))/Stepph);
fprintf('Overcharge events: %d steps = %.2f hours\n', sum(sum(OVC)), sum(sum(OVC))/Stepph);
fprintf('Overdischarge events: %d steps = %.2f hours\n', sum(sum(OVD)), sum(sum(OVD))/Stepph);
fprintf('Dumped/excess energy: %.2f kWh\n', sum(sum(PDUMP))/Stepph);
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
