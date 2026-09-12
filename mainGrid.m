%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grid-connected PV system
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Load consumption
LoadProfiles;

%AC power
ACpower;

%Results
DailyParameters;
MonthlyParameters;
YearlyParameters;

%Draw Sankey diagram
if ~exist('Project_Lifetime', 'var') || Project_Lifetime == 1
    SankeyGrid;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%