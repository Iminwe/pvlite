%Power calculations
%Matrix initialisation to zero
PDC=zeros(Nsteps, Ndays);
pdc=zeros(Nsteps, Ndays);
PAC0=zeros(Nsteps, Ndays);
PAC1=zeros(Nsteps, Ndays);
PAC=zeros(Nsteps, Ndays);
PBAT=zeros(Nsteps, Ndays);
SOC=zeros(Nsteps, Ndays);
Cuse=zeros(Nsteps, Ndays);
LLH=zeros(Nsteps, Ndays);
OVC=zeros(Nsteps, Ndays);
OVD=zeros(Nsteps, Ndays);
ETAI=zeros(Nsteps, Ndays); %Inverter efficiency

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

%Initial SOC
SOCprev=SOCmax;

%Calculations
for d=1:Ndays
    for h=1:Nsteps
        %Power at the inverter input
        pdc(h,d)=pac(h,d) + k0 + k1*pac(h,d) + k2*(pac(h,d)^2);
        PDC(h,d)=pdc(h,d)*PInom;

        %Inverter efficiency
        ETAI(h,d)=pac(h,d)/pdc(h,d);

        %Battery power
        PBAT(h,d)=PPV(h,d)-PDC(h,d);
      
        %Discharge of the battery
        if (PBAT(h,d)<=0)
            %Available capacity for discharging, kWh
            Cuse(h,d)=(SOCprev-SOCmin)*CBAT;
            %Check if the energy demand can be supplied by the battery
            if (abs(PBAT(h,d))/Stepph)<=Cuse(h,d)
                %The battery can supply the required power
                %SOC calculation
                SOC(h,d)=SOCprev-(abs(PBAT(h,d))/Stepph)/CBAT;
            else
                %There is not enough capacity to discharge
                %The inverter swithes off
                InverterOFF;
                %Loss of load hours flag
                LLH(h,d)=1;
                %Overdischarge flag
                OVD(h,d)=1;
                %The PV power is used for charging the battery
                PBAT(h,d)=PPV(h,d);
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
                %There is not enough capacity to charge
                %We charge as much we can
                PBAT(h,d)=Cuse(h,d)*Stepph;
                %SOC calculation
                SOC(h,d)=SOCmax; %Or SOC(h,d)=SOCnow+(PBAT(h,d)/Stepph)/CBAT;
                %The PV power is reduced
                PPV(h,d)=PBAT(h,d)+PDC(h,d);
                %PV losses caused by battery "saturation";
                PPV3(h,d)=PPV(h,d);
                %Overcharge flag
                OVC(h,d)=1;
            end
        end
        %Update SOC
        SOCprev=SOC(h,d);
    end
end