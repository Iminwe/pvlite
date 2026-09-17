%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PowerCalculationsHybrid_ACbus.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Power calculations
%Matrix initialisation to zero
PDC=zeros(Nsteps, Ndays);
pdc=zeros(Nsteps, Ndays);
PAC0=zeros(Nsteps, Ndays);
PAC1=zeros(Nsteps, Ndays);
PAC=zeros(Nsteps, Ndays);
PBAT=zeros(Nsteps, Ndays); %Battery power (>0 charge, <0 discharge)
SOC=zeros(Nsteps, Ndays);
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

%If TMY is not selected as input data, the wind speed is set to zero
if(InputData==1 || InputData==2 || InputData==4)
    Wind=zeros(Nsteps, Ndays); %Wind speed
end

%Normalised load power at the inverter output
PAC=PLOAD;
PAC1=PLOAD;
PAC0=PAC1./((1-(WAC/100)*(PAC1/PInom)));

% Mixed node configuration (AC and DC coupled PV)
if ~exist('PV_DC_share', 'var')
    PV_DC_share = 0.5; % Default to 50% PV on DC bus, 50% on AC bus
end
PPV_AC = PPV * (1 - PV_DC_share);
PPV_DC = PPV * PV_DC_share;

%Calculate AC power from PV using Grid Inverter
ACpowerGridInverter;

%Initial SOC and genset operation
SOCprev=SOCmax; 

%Calculations
for d=1:Ndays
    for h=1:Nsteps

        %Genset power
        GENON(1,1)=0;
        if(SOCprev<SOCstart)
            %Genset start
            GENON(h,d)=1;
            PGEN(h,d)=PGENnom;
        elseif (SOCprev>=SOCstart && SOCprev<=SOCstop && GENON(h,d)==1)
            PGEN(h,d)=PGENnom;
        elseif (SOCprev>SOCstop && GENON(h,d)==1 )
            %Genset stops
            GENON(h,d)=0;
        end

        %Fuel consumption, liter
        if(PGENnom==0 || GENON(h,d)==0)
            FUEL(h,d)=0;
        else
            FUEL(h,d)=((b0i+b1i*PGENnom)+(b0s+b1s*PGENnom)*PGEN(h,d))/Stepph;
        end

        %Wind power, kW
        if(Wind(h,d)<=Vci || Wind(h,d)>Vco)
            PWIND(h,d)=0;
        elseif (Wind(h,d)>Vci && Wind(h,d)<Vnom)
            PWIND(h,d)=Cpeq*(Wind(h,d)^3-Vci^3);
        elseif (Wind(h,d)>Vnom && Wind(h,d)<=Vco)
            PWIND(h,d)=PWnom;
        end

        %Removes wind power from simulation
        if(PWnom==0)
            PWIND(h,d)=0;
        end

        %Total generated power on AC bus
        PTOT(h,d)=PAC_g(h,d)+PGEN(h,d)+PWIND(h,d);

        %PTOT > PLOAD: excess AC goes through the bidirectional inverter to charge
        %PTOT < PLOAD: the shortfall comes from the battery via the same inverter
        
        %Let's calculate net AC power:
        P_AC_NET = PTOT(h,d) - PLOAD(h,d);
        
        %P_AC_NET > 0: charging, via the bidirectional inverter as rectifier
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
            
            % Total battery power (DC PV + Rectified AC excess)
            PBAT(h,d) = PBAT_from_AC + PPV_DC(h,d);
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
            PBAT(h,d) = PPV_DC(h,d) - P_DC_req; 
            PDC(h,d) = 0;
        end
      
        %Discharge of the battery
        if (PBAT(h,d) < 0)
            %Available capacity for discharging
            Cuse(h,d)=(SOCprev-SOCmin)*CBAT;
            if (abs(PBAT(h,d))/Stepph)<=Cuse(h,d)
                %The battery can supply the required power
                %SOC calculation
                SOC(h,d)=SOCprev-(abs(PBAT(h,d))/Stepph)/CBAT;
            else
                %There is not enough capacity to discharge
                %The bidirectional inverter swithes off
                InverterOFF;
                %Loss of load flag
                LLH(h,d)=1;
                %Overdischarge flag
                OVD(h,d)=1;
                
                % Since bidirectional inverter is OFF, battery only sees DC PV
                PBAT(h,d) = PPV_DC(h,d);
                
                % Check if PPV_DC can be charged into the battery
                Cuse_charge=(SOCmax-SOCprev)*CBAT;
                if (PBAT(h,d)/Stepph <= Cuse_charge)
                    SOC(h,d)=SOCprev+(PBAT(h,d)/Stepph)/CBAT;
                else
                    % Regulate DC PV
                    PBAT(h,d) = Cuse_charge*Stepph;
                    PPV_DC(h,d) = PBAT(h,d);
                    SOC(h,d)=SOCmax;
                end
            end
        end

        %Charge of the battery
        if (PBAT(h,d)>0)
            %Available capacity for charging
            Cuse(h,d)=(SOCmax-SOCprev)*CBAT;
            if (PBAT(h,d)/Stepph<=Cuse(h,d))
                %The battery can be charged
                %SOC calculation
                SOC(h,d)=SOCprev+(PBAT(h,d)/Stepph)/CBAT;
            else
                %There is not enough capacity to charge the available power
                %We charge as much we can
                PBAT(h,d)=Cuse(h,d)*Stepph;
                %SOC calculation
                SOC(h,d)=SOCmax; %Or SOC(h,d)=SOCnow+(PBAT(h,d)/Stepph)/CBAT;
                %Regulation of the power generation
                Req_RE = PBAT(h,d) + PDC(h,d) - PGEN(h,d);
                if Req_RE <= 0
                    PPV(h,d) = 0;
                    PWIND(h,d) = 0;
                    PPV3(h,d) = 0;
                elseif PPV(h,d) > Req_RE
                    PPV(h,d) = Req_RE;
                    PWIND(h,d) = 0;
                    PPV3(h,d) = Req_RE;
                else
                    PWIND(h,d) = Req_RE - PPV(h,d);
                end
                %Overcharge flag
                OVC(h,d)=1;
            end
        end
        %Update SOC
        SOCprev=SOC(h,d);
    end
end