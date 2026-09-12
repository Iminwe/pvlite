%AC power
%Matrix initialisation to zero
PAC0=zeros(Nsteps, Ndays);
PAC1=zeros(Nsteps, Ndays);
PAC=zeros(Nsteps, Ndays);
pac=zeros(Nsteps, Ndays);
PDC=zeros(Nsteps, Ndays);
pdc=zeros(Nsteps, Ndays);
ETAI=zeros(Nsteps, Ndays);

%DC power at the inverter input delivered by the PV generator
PDC=PPV;

%Maximum inverter power, normalised to the nominal one
pacmax=PImax/PInom;

%Calculations
for d=1:Ndays
    for h=1:Nsteps
        if (Gef(h,d)<Gth)
            %PV system is OFF
            %Null PV powers
            PVgeneratorOFF;
            %Null inverter powers
            InverterOFF;
        else
            %Normal case
            %Power delivered at the inverter input,
            %normalised to the nominal inverter power.
            pdc(h,d)=PDC(h,d)/PInom;
            a=k2;
            b=1+k1;
            c=k0-pdc(h,d);
            %Power delivered by the inverter at its output, normalised to the 
            %nominal inverter power.
            pac(h,d)=(-b+sqrt(b^2-4*a*c))/(2*a);
            %AC power
            PAC0(h,d)=pac(h,d)*PInom;
            %Inverter efficiency
            ETAI(h,d)=pac(h,d)/pdc(h,d);
            
            %Special case 1: if pdc<Ki0, pac would be negative.
            if(pac(h,d)<0)
                %PV system is OFF
                %Null inverter powers
                InverterOFF;
                %And PV powers
                PVgeneratorOFF;
            end
            
            %Special case 2: inverter saturation
            if pac(h,d)>pacmax
                %AC power is limited to the maximum inverter power
                pac(h,d)=pacmax;
                %AC power
                PAC0(h,d)=pac(h,d)*PInom;
                %DC power recalculated as the maximum inverter power
                %divided by the efficiency in that operating point
                pdc(h,d)=(pacmax+k0+k1*pacmax+k2*(pacmax^2));
                %DC power
                PDC(h,d)=pdc(h,d)*PInom;
                %Recalculates PV powers
                PPV(h,d)=PDC(h,d);
                PPV3(h,d)=PDC(h,d); %Saturation losses will appear in PPV3
                %Inverter efficiency
                ETAI(h,d)=pac(h,d)/pdc(h,d);
            end
            %Less LV wiring losses
            PAC1(h,d)=PAC0(h,d)*(1-(WAC/100)*(PAC0(h,d)/PInom));
        end  
    end    
end

%Final available AC power, kW
PAC=PAC1;

