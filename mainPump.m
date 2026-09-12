%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PV pumping system
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Pumping model
PumpingModel;

%AC power
ACpowerPump;

%Pumping calculations
%1. Using the Q-P2 curve calculated in script PumpingModel
%PumpingCalculations;
%2. Using an iterative algorithm
PumpingCalculations_Iterative;

%Results
DailyParameters;
MonthlyParameters;
YearlyParameters;

%Draw Sankey diagram
if ~exist('Project_Lifetime', 'var') || Project_Lifetime == 1
    SankeyPump;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%