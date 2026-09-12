%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ACpowerGridInverter.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%AC power
%Matrix initialisation to zero
PAC0_g=zeros(Nsteps, Ndays);
PAC1_g=zeros(Nsteps, Ndays);
PAC_g=zeros(Nsteps, Ndays);
pac_g=zeros(Nsteps, Ndays);
PDC_g=zeros(Nsteps, Ndays);
pdc_g=zeros(Nsteps, Ndays);
ETAI_g=zeros(Nsteps, Ndays); %Inverter efficiency

%DC power at the inverter input delivered by the PV generator
PDC_g=PPV_AC;

%Maximum inverter power, normalised to the nominal one
pacmax_g=PGImax/PGInom;

%Calculations
for d=1:Ndays
    for h=1:Nsteps
        if (Gef(h,d)<Gth)
            %PV system is OFF
            %Null PV powers (AC side)
            PPV_AC(h,d)=0;
            PPV3_AC(h,d)=0;
            %Null inverter powers
            GridInverterOFF;
        else
            %Normal case
            %Power delivered at the inverter input,
            %normalised to the nominal inverter power.
            pdc_g(h,d)=PDC_g(h,d)/PGInom;
            a=k2_g;
            b=1+k1_g;
            c=k0_g-pdc_g(h,d);
            %Power delivered by the inverter at its output, normalised to the 
            %nominal inverter power.
            pac_g(h,d)=(-b+sqrt(b^2-4*a*c))/(2*a);
            %AC power
            PAC0_g(h,d)=pac_g(h,d)*PGInom;
            %Inverter efficiency
            ETAI_g(h,d)=pac_g(h,d)/pdc_g(h,d);
            
            %Special case 1: if pdc_g<Ki0, pac would be negative.
            if(pac_g(h,d)<0)
                %PV system is OFF
                %Null inverter powers
                GridInverterOFF;
                %Null PV powers (AC side)
                PPV_AC(h,d)=0;
                PPV3_AC(h,d)=0;
            end
            
            %Special case 2: inverter saturation
            if pac_g(h,d)>pacmax_g
                %AC power is limited to the maximum inverter power
                pac_g(h,d)=pacmax_g;
                %AC power
                PAC0_g(h,d)=pac_g(h,d)*PGInom;
                %DC power recalculated as the maximum inverter power
                %divided by the efficiency in that operating point
                pdc_g(h,d)=(pacmax_g+k0_g+k1_g*pacmax_g+k2_g*(pacmax_g^2));
                %DC power
                PDC_g(h,d)=pdc_g(h,d)*PGInom;
                %Recalculates PV powers
                PPV_AC(h,d)=PDC_g(h,d);
                PPV3_AC(h,d)=PDC_g(h,d); %Saturation losses will appear in PPV3
                %Inverter efficiency
                ETAI_g(h,d)=pac_g(h,d)/pdc_g(h,d);
            end
            %Less LV wiring losses
            PAC1_g(h,d)=PAC0_g(h,d)*(1-(WAC/100)*(PAC0_g(h,d)/PGInom));
        end  
    end    
end

%Final available AC power, kW
PAC_g=PAC1_g;
