%PV power
%Matriz initialisation to zero
%Ideal, with no losses
%Est
PPV0_Est=zeros(Nsteps, Ndays);
PPV1_Est=zeros(Nsteps, Ndays);
PPV2_Est=zeros(Nsteps, Ndays);
PPV3_Est=zeros(Nsteps, Ndays);
%West
PPV0_West=zeros(Nsteps, Ndays);
PPV1_West=zeros(Nsteps, Ndays);
PPV2_West=zeros(Nsteps, Ndays);
PPV3_West=zeros(Nsteps, Ndays);

%Calculations
%Est
for d=1:Ndays
    for h=1:Nsteps  
        if (Gef_Est(h,d)<Gth)
            %PV system is OFF
            %Anulates PV generator
            %Ideal, no losses
            PVgeneratorEst_OFF;
        else
            %Chain of DC power conversion, normalised to the nominal PV power.
            %Ideal, no losses, kW
            PPV0_Est(h,d)=0.5*PVnom*Gef_Est(h,d)/1000;
            %Less temperature losses
            PPV1_Est(h,d)=PPV0_Est(h,d)*(1-(Tc(h,d)-25)*CVPT/100);
            %Less wiring losses
            PPV2_Est(h,d)=PPV1_Est(h,d)*(1-(WDC/100)*(PPV1_Est(h,d)/PVnom));
            %Losses caused by the inverter saturation (grid-connection)
            PPV3_Est(h,d)=PPV2_Est(h,d);
        end
    end
end

%West
for d=1:Ndays
    for h=1:Nsteps  
        if (Gef_West(h,d)<Gth)
            %PV system is OFF
            %Anulates PV generator
            %Ideal, no losses
            PVgeneratorWest_OFF;
        else
            %Chain of DC power conversion, normalised to the nominal PV power.
            %Ideal, no losses, kW
            PPV0_West(h,d)=0.5*PVnom*Gef_West(h,d)/1000;
            %Less temperature losses
            PPV1_West(h,d)=PPV0_West(h,d)*(1-(Tc(h,d)-25)*CVPT/100);
            %Less wiring losses
            PPV2_West(h,d)=PPV1_West(h,d)*(1-(WDC/100)*(PPV1_West(h,d)/PVnom));
            %Losses caused by the inverter saturation (grid-connection)
            PPV3_West(h,d)=PPV2_West(h,d);
        end
    end
end

%Averaged irradiances
G=(G_Est+G_West)/2;
Gef=(Gef_Est+Gef_West)/2;

%Final available PV power
PPV0=PPV0_Est+PPV0_West;
PPV1=PPV1_Est+PPV1_West;
PPV2=PPV2_Est+PPV2_West;
PPV3=PPV3_Est+PPV3_West;
PPV=PPV3;






    

