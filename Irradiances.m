%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculation of Sun position
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Eccentriciy correction factor
Eccentricity;

%Solar declination
SolarDeclination;

%Equation of time
EquationOfTime;

%Sunrise angle, radian
SunriseAngle;

%Generation of the matrix Hours
if (InputData==1 || InputData==2 || InputData==4)
    GenerateMatrixHours;
elseif (InputData==3 || InputData==5)
    Hours=Hours_TMY;
end

%True Solar Time, radian
TrueSolarTime;

%Sun Position, cosines and angles.
SunPosition;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculation of horizontal irradiances
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(InputData==1 || InputData==2 || InputData==4)
    %Synthetic generation 
    if(TimeSeries==1)
        %Average days, all days of each month have the same horizontal global 
        %irradiation
        SyntheticGeneration_AverageDays;
    elseif (TimeSeries==2)
        %Aguiar
        SyntheticGeneration_Aguiar;
    end
elseif(InputData==3 || InputData==5)
        %G0
        G0=G0_TMY;
        %D0
        D0=D0_TMY;
        %B0
        B0=B0_TMY;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculation of irradiances on the inclined plane
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Mounting==2)
    Orientation=-90;
    InclinedSurfaceIrradiances;
    G_Est=G;
    Gef_Est=Gef;
    Orientation=90;
    InclinedSurfaceIrradiances;
    G_West=G;
    Gef_West=Gef;
else
    InclinedSurfaceIrradiances;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%