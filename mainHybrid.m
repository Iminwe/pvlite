%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hybrid systems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Load profiles
LoadProfiles;

%Power calculations
if (Application==3) 
    %DC bus
    %Check if MKBM is selected
    if exist('BatteryModel', 'var') && BatteryModel == 2
        %Use MKBM battery model
        PowerCalculationsHybrid_MKBM;
    else
        %Use original simple battery model
        PowerCalculationsHybrid_DCbus;
    end
elseif (Application==4)
    %AC bus
    if exist('BatteryModel', 'var') && BatteryModel == 2
        %Use MKBM battery model
        PowerCalculationsHybrid_MKBM_ACbus;
    else
        %Use original simple battery model
        PowerCalculationsHybrid_ACbus;
    end
end

%Results
DailyParameters;
MonthlyParameters;
YearlyParameters;

%Draw Sankey diagram
if ~exist('Project_Lifetime', 'var') || Project_Lifetime == 1
    if (Application==3)
        SankeyHybrid_DCbus;
    elseif (Application==4)
        SankeyHybrid_ACbus;
    end
end
