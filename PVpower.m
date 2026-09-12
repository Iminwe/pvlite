%PV power
%Matriz initialisation to zero
PPV0=zeros(Nsteps, Ndays);
PPV1=zeros(Nsteps, Ndays);
PPV2=zeros(Nsteps, Ndays);
PPV3=zeros(Nsteps, Ndays);
PPV=zeros(Nsteps, Ndays);

%Calculations
for d=1:Ndays
    for h=1:Nsteps  
        if (Gef(h,d)<Gth)
            %PV system is OFF
            %Anulates PV generator
            %Ideal, no losses
            PVgeneratorOFF;
        else
            %Chain of DC power conversion.
            %Ideal effective, kW
            PPV0(h,d)=PVnom*Gef(h,d)/1000;
            %Less temperature losses
            PPV1(h,d)=PPV0(h,d)*(1-(Tc(h,d)-25)*CVPT/100);
            %Less wiring losses
            PPV2(h,d)=PPV1(h,d)*(1-(WDC/100)*(PPV1(h,d)/PVnom));
            %Less losses caused by the inverter clipping, battery disconnection, etc. 
            %Initially, PPV3 is equal to PPV2, but it is reduced by
            %subsequent calculations depending on the system operation.
            PPV3(h,d)=PPV2(h,d);
        end
    end
end

%Final available PV power
PPV=PPV3;






    

