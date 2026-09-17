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
pac=PAC0/PInom;

%Checking maximum load vs maximum inverter power
if PImax<max(max(PAC0))
    disp('Attention: Undersized inverter')
    Maximum_Inverter_Power=PImax
    Maximum_Load_Power=max(max(PAC0))
    error('Simulation stopped: increase the maximum inverter power');
end

%Initial SOC and genset operation
SOCprev=SOCmax; 

%Calculations
for d=1:Ndays
    for h=1:Nsteps
        %Power at the inverter input
        pdc(h,d)=pac(h,d) + k0 + k1*pac(h,d) + k2*(pac(h,d)^2);
        PDC(h,d)=pdc(h,d)*PInom;

        %Inverter efficiency
        ETAI(h,d)=pac(h,d)/pdc(h,d);
        
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

        %Total generated power
        PTOT(h,d)=PPV(h,d)+PGEN(h,d)+PWIND(h,d);

        %Battery power
        %Total power less inverter power
        PBAT(h,d)=PTOT(h,d)-PDC(h,d);
      
        %Discharge of the battery
        if (PBAT(h,d)<=0)
            %Available capacity for discharging
            Cuse(h,d)=(SOCprev-SOCmin)*CBAT;
            if (abs(PBAT(h,d))/Stepph)<=Cuse(h,d)
                %The battery can supply the required power
                %SOC calculation
                SOC(h,d)=SOCprev-(abs(PBAT(h,d))/Stepph)/CBAT;
            else
                %There is not enough capacity to discharge
                %The inverter swithes off
                InverterOFF;
                %Loss of load flag
                LLH(h,d)=1;
                %Overdischarge flag
                OVD(h,d)=1;
                %The generated power is used for charging the battery
                PBAT(h,d)=PTOT(h,d);
                %SOC calculation
                SOC(h,d)=SOCprev+(PBAT(h,d)/Stepph)/CBAT;
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