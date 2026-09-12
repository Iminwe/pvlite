%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Yearly parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. Irradiations, Wh/m2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Global irradiation, Wh
G0a=sum(G0m);
Ga=sum(Gm);
Gefa=sum(Gefm);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Beam irradiation, Wh
B0a=sum(B0m);
Ba=sum(Bm);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Diffuse irradiation, Wh
D0a=sum(D0m);
Da=sum(Dm);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2. Energies, kWh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EPV0a=sum(EPV0m);
EPV1a=sum(EPV1m);
EPV2a=sum(EPV2m);
EPV3a=sum(EPV3m);
EPVa=sum(EPVm);

%Energy to the inverter input
EDCa=sum(EDCm);

EAC0a=sum(EAC0m);
EAC1a=sum(EAC1m);
EACa=sum(EACm);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Other energies and calculations depending on the application
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==1 || Application==2 || Application==3 || Application==4)
    %Load consumption
    ELOADa=sum(ELOADm);
end
if(Application==1)
    %Grid-connected system
    %Net grid energy
    EGRIDa=sum(EGRIDm);
    %Grid injection
    EGRIDIa=sum(EGRIDIm);
    %Grid consumption
    EGRIDCa=sum(EGRIDCm);
    %Self consumed energy, kWh
    ESELFa=EACa-EGRIDIa;
end
if(Application==2 || Application==3 || Application==4)
    %Stand-alone PV systems
    %Battery energy
    EBATa=sum(EBATm);
end
if(Application==3 || Application==4)
    %Stand-alone PV hybrid systems
    %Genset energy
    EGENa=sum(EGENm);
    %Wind energy
    EWINDa=sum(EWINDm);
    %Dumped/excess energy
    if exist('EDUMPm','var')
        EDUMPa=sum(EDUMPm);
    else
        EDUMPa=0;
    end
end
if(Application==5)
    %PV pumping
    %Yearly flow, (m3/h)
    Qa=sum(Qm);
    %Input energy to the motor, kWh
    E1a=sum(E1m);
    %Mechanical energy in the shaft, kWh
    E2a=sum(E2m);
    %Hidraulic energy, kWh
    EHa=sum(EHm);
    EH0a=sum(EH0m);
    EH1a=sum(EH1m);
    EH2a=sum(EH2m);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3. PRs (ideal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PRa=EACa/(PVnom*Ga/1000);
%PR ideal (hidraulic)
if (Application==5)
     PRHa=EHa/(PVnom*Ga/1000);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%4. Efficiencies and losses, %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%4.0 Incidence (reflection, transmission and dust)
LOSS_INCa=(1-Gefa/Ga)*100;
%4.1 Temperature
LOSS_TEMa=(1-EPV1a./EPV0a)*100;
%4.2 DC wiring
LOSS_WDCa=(1-EPV2a./EPV1a)*100;
%4.3 Inverter saturation
LOSS_SATa=(1-EPV3a./EPV2a)*100;
%4.4 Inverter energy efficiency
ETAIa=(EAC0a./EDCa)*100;
%4.5 Inverter losses
LOSS_INVa=100-ETAIa;
%4.6 AC wiring
LOSS_WACa=(1-EAC1a./EAC0a)*100;
%4.7 Pumping
if (Application==5)
    %Motor
    ETAMa=100*(E2a/E1a);
    LOSS_MOTa=100-ETAMa;
    %Pump
    ETAPa=100*(EHa/E2a);
    LOSS_PUMPa=100-ETAPa;
    %Motor-pump
    ETAMPa=100*(EHa/E1a);
    LOSS_MPa=100-ETAMPa;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%5. Loss of load probability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==2 || Application==3 || Application==4)
    LLHa=sum(sum(LLH))/(Nsteps*Ndays);
    LLPa=(Edemanda-EACa)/Edemanda;
    %Other definitions
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%6. State of charge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==2 || Application==3 || Application==4)
    %
    SOCda=mean(SOCdavg);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%7. Other calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Reference yield, equivalent hours
Yr=Ga/1000;
%Array yield, equivalent hours
Ya=EPVa/PVnom;
%Final yield, equivalent hours
Yf=EACa/PVnom;
%Capture losses, percentage of Yr
LCa=100*(Yr-Ya)/Yr;
%System losses, percentage of Yr
LSa=100*(Ya-Yf)/Yr;

if (Application==1)
    %Self-consumption, %
    SCa=100*ESELFa/EACa;
    %Self-sufficiency, %
    SSa=100*ESELFa/ELOADa;
end

if(Application==3 || Application==4)
    %Stand-alone hybrid systems
    %Fuel consumption, liter
    FUELa=sum(FUELm);
    %Running hours, hours
    GENONa=8760*sum(sum(GENON))/(Nsteps*Ndays);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%