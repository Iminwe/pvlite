%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stand-alone PV system
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Load profiles
LoadProfiles;

%Power calculations
%Check if MKBM is selected
if exist('BatteryModel', 'var') && BatteryModel == 2
    %Use MKBM battery model
    PowerCalculations_MKBM;
else
    %Use original simple battery model
    PowerCalculations;
end

%Results
DailyParameters;
MonthlyParameters;
YearlyParameters;

%Draw Sankey diagram
if ~exist('Project_Lifetime', 'var') || Project_Lifetime == 1
    SankeySA;
end
