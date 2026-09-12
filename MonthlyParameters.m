%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Monthly parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. Irradiations, Wh/m2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Global irradiation, Wh
G0m=MonthlySum(G0d);
Gm=MonthlySum(Gd);
Gefm=MonthlySum(Gefd);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Beam irradiation, Wh
B0m=MonthlySum(B0d);
Bm=MonthlySum(Bd);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Diffuse irradiation, Wh
D0m=MonthlySum(D0d);
Dm=MonthlySum(Dd);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2. Energies, kWh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EPV0m=MonthlySum(EPV0d);
EPV1m=MonthlySum(EPV1d);
EPV2m=MonthlySum(EPV2d);
EPV3m=MonthlySum(EPV3d);
EPVm=MonthlySum(EPVd);

%Energy to the inverter input
EDCm=MonthlySum(EDCd);

EAC0m=MonthlySum(EAC0d);
EAC1m=MonthlySum(EAC1d);
EACm=MonthlySum(EACd);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Other energies and calculations depending on the application
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==1 || Application==2 || Application==3 || Application==4)
    %Load consumption
    ELOADm=MonthlySum(ELOADd);
end
if(Application==1)
    %Grid-connected system
    %Net grid energy
    EGRIDm=MonthlySum(EGRIDd);
    %Grid injection
    EGRIDIm=MonthlySum(EGRIDId);
    %Grid consumption
    EGRIDCm=MonthlySum(EGRIDCd);
    %Self-consumed energy
    ESELFm=MonthlySum(ESELFd);
end
if(Application==2 || Application==3 || Application==4)
    %Stand-alone PV systems
    %Battery energy
    EBATm=MonthlySum(EBATd);
end
if(Application==3 || Application==4)
    %Stand-alone PV hybrid systems
    %Genset energy
    EGENm=MonthlySum(EGENd);
    %Wind energy
    EWINDm=MonthlySum(EWINDd);
end
if(Application==5)
    %PV pumping
    %Daily flow, m3/h
    Qm=MonthlySum(Qd);
    %Input energy to the motor, kWh
    E1m=MonthlySum(E1d);
    %Mechanical energy in the shaft, kWh
    E2m=MonthlySum(E2d);
    %Hidraulic energy, kWh
    EHm=MonthlySum(EHd);
    EH0m=MonthlySum(EH0d); 
    EH1m=MonthlySum(EH1d); 
    EH2m=MonthlySum(EH2d); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3. Performance ratios (ideal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PRm=EACm./(PVnom*Gm/1000);
%PR ideal (hidraulic)
if (Application==5)
    PRHm=EHm./(PVnom*Gm/1000); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%4. Efficiencies and losses, %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%4.0 Incidence (reflection, transmission and dust)
LOSS_INCm=(1-Gefm./Gm)*100;
%4.1 Temperature
LOSS_TEMm=(1-EPV1m./EPV0m)*100;
%4.2 DC wiring
LOSS_WDCm=(1-EPV2m./EPV1m)*100;
%4.3 Inverter saturation
LOSS_SATm=(1-EPV2m./EPV1m)*100;
%4.4 Inverter energy efficiency
ETAIm=(EAC0m./EDCm)*100;
%4.5 Inverter losses
LOSS_INVm=100-ETAIm;
%4.6 AC wiring
LOSS_WACm=(1-EAC1m./EAC0m)*100;
%4.7 Pumping
if (Application==5)
    %Motor
    ETAMm=100*(E2m/E1m);
    LOSS_MOTm=100-ETAMm;
    %Pump
    ETAPm=100*(EHm/E2m);
    LOSS_PUMPm=100-ETAPm;
    %Motor-pump
    ETAMPm=100*(EHm/E1m);
    LOSS_MPm=100-ETAMPm;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%5. Loss of load probability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==2 || Application==3 || Application==4)
    LLHm=MonthlySum(sum(LLH));
    %Lenght of each month
    MonthLength=[31,28,31,30,31,30,31,31,30,31,30,31];
    LLHm=LLHm./(Nsteps*MonthLength);
    %Other definitions
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%6. State of charge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==2 || Application==3 || Application==4)
    %
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%7. Other calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (Application==1)
    %Self-consumption, %
    SCm=100*ESELFm/EACm;
    %Self-sufficiency, %
    SSm=100*ESELFm/ELOADm;
end

if(Application==3 || Application==4)
    %Stand-alone hybrid systems
    %Fuel consumption, liter
    FUELm=MonthlySum(FUELd);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

