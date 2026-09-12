%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hybrid systems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Load profiles
LoadProfiles;

%Power calculations
if (Application==3) 
    %DC bus
    PowerCalculationsHybrid_DCbus;
elseif (Application==4)
    %AC bus
    error('Work in progress (AC bus). The simulation of this hybrid configuration is not available.');
end

%Results
DailyParameters;
MonthlyParameters;
YearlyParameters;

%Draw Sankey diagram
if (Application==3)
    SankeyHybrid_DCbus;
elseif (Application==4)
    %AC bus
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%