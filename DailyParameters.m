%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Daily Parameters,<1x365>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. Daily irradiations, Wh/m2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Global daily irradiations, Wh/m2
%Horizontal global irradiation
G0d=sum(G0)/Stepph;
%In-plane global irradiation
Gd=sum(G)/Stepph;
%Effective global irradiation
Gefd=sum(Gef)/Stepph;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Beam daily irradiations, Wh/m2
%Horizontal beam irradiation
B0d=sum(B0)/Stepph;
%In-plane beam irradiation
Bd=sum(B)/Stepph;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Diffuse daily irradiations, Wh/m2
%Horizontal diffuse irradiation
D0d=sum(D0)/Stepph;
%In-plane diffuse irradiation
Dd=sum(D)/Stepph;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2. Daily energy yields, kWh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PV energy output, ideal
EPV0d=sum(PPV0)/Stepph;
%Less temperature losses
EPV1d=sum(PPV1)/Stepph;
%Less wiring losses
EPV2d=sum(PPV2)/Stepph;
%Less inverter saturation
EPV3d=sum(PPV3)/Stepph;
%Final
EPVd=sum(PPV)/Stepph;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DC energy at the inverter output
EDCd=sum(PDC)/Stepph;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%AC energy at the inverter output
EAC0d=sum(PAC0)/Stepph;
%Less wiring losses
EAC1d=sum(PAC1)/Stepph;
%Final
EACd=sum(PAC)/Stepph;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Other energies and calculations depending on the application
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==1 || Application==2 || Application==3 || Application==4)
    %Load consumption, kWh
    ELOADd=sum(PLOAD)/Stepph;
end
if(Application==1)
    %Grid-connected system
    %Grid energy, kWh
    EGRIDd=sum(PGRID)/Stepph;
    %Injected in the grid, kWh
    EGRIDId=sum(PGRIDI)/Stepph;
    %Consumed from the grid, kWh
    EGRIDCd=sum(PGRIDC)/Stepph;
    %Self-consumed energy, kWh
    ESELFd=sum(PSELF)/Stepph;
end
if(Application==2 || Application==3 || Application==4)
    %Stand-alone PV systems
    %Battery energy
    EBATd=sum(PBAT)/Stepph;
end
if(Application==3 || Application==4)
    %Hybrid systems
    %Genset energy
    EGENd=sum(PGEN)/Stepph;
    %Wind energy
    EWINDd=sum(PWIND)/Stepph;
    %Dumped/excess energy
    if exist('PDUMP','var')
        EDUMPd=sum(PDUMP)/Stepph;
    else
        EDUMPd=zeros(1,Ndays);
    end
end
if(Application==5)
    %PV pumping
    %Daily pump volume, m3
    Qd=sum(Q)/Stepph;
    %Input energy to the motor, kWh
    E1d=sum(P1)/Stepph;
    %Mechanical energy in the shaft, kWh
    E2d=sum(P2)/Stepph;
    %Hidraulic energy, kWh
    EHd=sum(PH)/Stepph;
    EH0d=sum(PH0)/Stepph;
    EH1d=sum(PH1)/Stepph;
    EH2d=sum(PH2)/Stepph;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3. Performance Ratios
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PR ideal
PRd=EACd./(PVnom*Gd/1000);
%PR ideal (hidraulic)
if (Application==5)
    PRHd=EHd./(PVnom*Gd/1000);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%4. Efficiencies and losses, %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%4.0 Incidence (reflection, transmission and dust)
LOSS_INCd=(1-Gefd./Gd)*100;
%4.1 Temperature
LOSS_TEMd=(1-EPV1d./EPV0d)*100;
%4.2 DC wiring
LOSS_WDCd=(1-EPV2d./EPV1d)*100;
%4.3 Inverter saturation
LOSS_SATd=(1-EPV3d./EPV2d)*100;
%4.4 Inverter energy efficiency
ETAId=(EAC0d./EDCd)*100;
%4.5 Inverter losses
LOSS_INVd=100-ETAId;
%4.6 AC wiring
LOSS_WACd=(1-EAC1d./EAC0d)*100;
%4.7 Pumping
if (Application==5)
    %Motor
    ETAMd=100*(E2d/E1d);
    LOSS_MOTd=100-ETAMd;
    %Pump
    ETAPd=100*(EHd/E2d);
    LOSS_PUMPd=100-ETAPd;
    %Motor-pump
    ETAMPd=100*(EHd/E1d);
    LOSS_MPd=100-ETAMPd;   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%5. Loss of load probability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==2 || Application==3 || Application==4)
    LLHd=sum(LLH)/Nsteps;
    %Other definitions
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%6. State of charge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==2 || Application==3 || Application==4)
    SOCdmin=min(SOC);
    SOCdmax=max(SOC);
    SOCdavg=mean(SOC);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%7. Other calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (Application==1)
    %Self-consumption, %
    SCd=100*ESELFd/EACd;
    %Self-sufficiency, %
    SSd=100*ESELFd/ELOADd;
end

if(Application==3 || Application==4)
    %Stand-alone hybrid systems
    %Fuel consumption, liter
    FUELd=sum(FUEL);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%