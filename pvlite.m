%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PVlite: A simulator of PV systems applications.
% Copyright: Javier Muñoz Cano. Version 2.3, 2024.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Clear workspace unless in test mode
if ~exist('run_as_test', 'var') || ~run_as_test
    clear;
end

%Input data
disp('Reading inputs ...')

%Read input parameters from excel sheet;
ReadInputData;
disp('Inputs Ok');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Simulating ...');
%Start

%Generation of irradiance time series.
Irradiances;

%Generation of temperature time series.
Temperatures;

%PV power
if(Mounting==2)
    %Delta (East-West) mounting
    PVpower_delta;
else
    %Standard mounting
    PVpower;
end

%Applications
if (Application==1)
    %Grid-connected PV system
    mainGrid;
elseif (Application==2)
    %Stand-alone PV system
    mainSA;
elseif (Application==3 || Application==4)
    %Stand-alone hybrid PV system
    mainHybrid;
elseif (Application==5)
    %PV pumping
    mainPump;
end

%Perform Economic Analysis
EconomicsCalculations;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
