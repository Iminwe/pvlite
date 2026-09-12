%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ReadInputData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Open a window to select the input data excel file
file1=uigetfile('*.xlsx','Select the input data file');

% If the file is not selected, or the window is closed, the program stops.
if isequal(file1,0)
    error('The file has not been selected');
end

%Read the first excel sheet
[num1, txt1]=xlsread(file1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Site.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='Site';
clear NUMERIC TXT;
[NUMERIC, TXT]=xlsread(file1,SheetName);

%Latitude of the location, positive in the Northern Hemisphere and negative
%in the Southern Hemisphere.
Latitude=NUMERIC(1,3);

%Latitude, radians. Internal calculation.
lat=Latitude*pi/180;

%Longitude of the location, negative towards West and positive towards Est.
Longitude=NUMERIC(2,3);

%Altitude of the location over sea level.
Altitude=NUMERIC(3,3);

%Standard longitude of the local meridian (multiple of 15), negative towards 
%West and positive towards East.
StandardLongitude=NUMERIC(4,3);
TimeZone=StandardLongitude/15;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Site
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Meteorological data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='Meteo';
clear NUMERIC TXT;
[NUMERIC, TXT]=xlsread(file1,SheetName);

%Input data
% 1-Monthly averages from the excel sheet
% 2-Monthly averages obtained from PVGIS TMY
% 3-Hourly values from PVGIS TMY
InputData=NUMERIC(1,3);
if(InputData==1)
    %Read monthly averages from the excel sheet
    %Mean daily global horizonal irradiation, monthly average, Wh/m2.
    Gdm0=NUMERIC(6:17,3)';
    %Minimum daily temperature, monthly average, ºC.
    Tmm=NUMERIC(6:17,4)';
    %Maximum daily temperature, monthly average, ºC.
    TMm=NUMERIC(6:17,5)';
elseif (InputData==2 || InputData==3)
    %Read TMY PGIS *.csv file
    ReadTMYPVGIS;
elseif (InputData==4 || InputData==5)
    %Read USA TMY3 *.csv file
    ReadTMY3;
end

%Generation of time series 
TimeSeries=NUMERIC(2,3);
%1.	Mean days
%2.	Aguiar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End Meteo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PV generator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='PVgen';
clear NUMERIC TXT;
[NUMERIC, TXT]=xlsread(file1,SheetName);

%Nominal PV power
PVnom=NUMERIC(1,3);
%Coefficient of Variation of module Power with Temperature (absolute value), %
CVPT=NUMERIC(2,3);
%Nominal Operation Cell Temperature, ºC
NOCT=NUMERIC(3,3);
%Thermal resistance, ºC·m^2/W
Rth=NUMERIC(4,3);

%Mounting structure
Mounting=NUMERIC(6,3);
 if (Mounting==1)
     %Static ground or roof
     %Inclination of the modules regarding the horizontal, from 0º to 90º.
     Inclination=NUMERIC(9,3);
     %Orientation of the modules towards the Equator.
     %Zero towards the South in the Northern Hemisphere (North in the Southern Hemisphere), negative towards the East, and positive towards the West.
     Orientation=NUMERIC(10,3);
 elseif (Mounting==2)
     %Static delta
     %Inclination of the modules regarding the horizontal, from 0º to 90º.
     %The same for East and West structrures.
     Inclination=NUMERIC(13,3);
 elseif (Mounting==4)
     %Azimutal tracker
     %Inclination of the modules regarding the horizontal, from 0º to 90º.
     Inclination=NUMERIC(16,3);
 end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End PVgen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inverter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='Inverter';
clear NUMERIC TXT;
[NUMERIC, TXT]=xlsread(file1,SheetName);

%Nominal output power, kW
PInom=NUMERIC(1,3);
%Maximum output power, kW
PImax=NUMERIC(2,3);
%Power efficiency curve
InverterCurve=NUMERIC(3,3);
if(InverterCurve==1)
    %Power efficiency curve parameters
    k0=NUMERIC(5,3);
    k1=NUMERIC(6,3);
    k2=NUMERIC(7,3);
else
    %Calculation of the previous parameters starting power efficiency
    %points
    [k0, k1, k2]=InverterParameters(NUMERIC(10:15,2), NUMERIC(10:15,3));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Inverter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wiring.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='Wiring';
clear NUMERIC TXT;
[NUMERIC, TXT]=xlsread(file1,SheetName);
%DC losses, %
WDC=NUMERIC(1,3);
%LV losses, %
WAC=NUMERIC(2,3);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Wiring.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Battery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='Battery';
clear NUMERIC TXT;
[NUMERIC, TXT]=xlsread(file1,SheetName);
%Battery. For stand-alone PV systems
%Battery capacity, kWh
CBAT=NUMERIC(1,3);
%Maximum SOC
SOCmax=NUMERIC(2,3);
%Minimum SOC
SOCmin=NUMERIC(3,3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Battery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load profiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='Load';
clear NUMERIC TXT;
[NUMERIC, TXT]=xlsread(file1,SheetName);
%Monthly average of daily energy consumption, kWh/day
Ldm=NUMERIC(2:13,3)';
%Yearly energy demand, kWh
Edemanda=NUMERIC(14,3);
%Normalised daily load profiles
F=NUMERIC(20:43,3)';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Load
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='Options';
clear NUMERIC TXT;
[NUMERIC, TXT]=xlsread(file1,SheetName);
%PV applicacion
Application=NUMERIC(1,3);

%Check the selected input data has wind speed
% if(Application==4 && InputData~=3 && InputData~=5)
%     error('This simulation requires hourly wind data. Select InputData==3')
% end

%Degree of dust/soiling
DustDegree=NUMERIC(2,3);
%Model of diffuse radiation
Diffuse_model=NUMERIC(3,3);
%Monthly correlation between the fraction of diffuse and clearness index
Diffuse_fraction=NUMERIC(4,3);
%Ground reflectance
GroundReflectance=NUMERIC(5,3);
%Other parameters
%Minimum irradiance required to injecting power in the grid, W/m2
Gth=0;

%Number of simulated days.
Ndays=365;
%Simulation step, seconds. Up to one hour maximum.
SimulationStep=NUMERIC(6,3);
%For TMY data the simulation step must be one hour
if(InputData==3 || InputData==5 )
    SimulationStep=3600;
end

%Number of simulation points per day
Nsteps=floor((24*60*60)/SimulationStep);
%Number of simulation points per hour
Stepph=3600/SimulationStep;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pumping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (Application==5)
    %PumpingData; %v2.2
    %Read the sheet
    SheetName='Pumping';
    clear NUMERIC TXT;
    [NUMERIC, TXT]=xlsread(file1,SheetName);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Well/borehole
    %Static head, m
    Hs=NUMERIC(1,3);
    %Constant test flow, m3/h
    Qtest=NUMERIC(2,3);
    %Drawdown at constant test flow
    Hdr=NUMERIC(3,3);
    %Aquifer loss
    kw1=NUMERIC(4,3);
    %Well loss
    kw2=NUMERIC(5,3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Water tank
    %Water tank capacity
    WTC=NUMERIC(8,3);
    %Discharge level
    Hr=NUMERIC(9,3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Pump
    %Rated flow, m3/h
    Qrated=NUMERIC(12,3);
    %Rated head, m
    Hrated=NUMERIC(13,3);
    %Liquid density, kg/m3
    Density=NUMERIC(14,3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %System curve
    %Friction losses, m
    Hf=NUMERIC(17,3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Pump curve
    %Flow nominal curve, m3/h
    Qnom=NUMERIC(38:47,2)';
    %Removes NaN
    Qnom(isnan(Qnom))=[];
    %Head nominal curve, m
    Hnom=NUMERIC(38:47,3)';
    %Removes NaN
    Hnom(isnan(Hnom))=[];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Powers
    %Nominal curve of power at the motor input P1, kW
    QnomP1=NUMERIC(52:61,2)';
    %Removes NaN
    QnomP1(isnan(QnomP1))=[];
    %P1 power
    P1nom=NUMERIC(52:61,3)';
    %Removes NaN
    P1nom(isnan(P1nom))=[];
    %Nominal curve of shaft power P2, kW
    QnomP2=NUMERIC(65:74,2)';
    %Removes NaN
    QnomP2(isnan(QnomP2))=[];
    %P2 power
    P2nom=NUMERIC(65:74,3)';
    %Removes NaN
    P2nom(isnan(P2nom))=[];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Motor
    %Rated shaft power, kW
    P2rated=NUMERIC(77,3);
    %Rated speed
    RPMnom=NUMERIC(78,3);
    % Minimum speed
    RPMcool=RPMnom*NUMERIC(79,3)/100;
    % Maximum speed
    RPMmax=RPMnom*NUMERIC(80,3)/100;
    %Motor power efficiency
    %Power output P2, kW
    P2motor=NUMERIC(84:91,2)';
    %Removes NaN
    P2motor(isnan(P2motor))=[];
    %Efficiency, %
    eta_motor=NUMERIC(84:91,3)';
    %Removes NaN
    eta_motor(isnan(eta_motor))=[];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Pumping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generator set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==3 || Application==4)
    %Read the sheet
    SheetName='Genset';
    clear NUMERIC TXT;
    [NUMERIC, TXT]=xlsread(file1,SheetName);
    %Nominal power of the genset
    PGENnom=NUMERIC(1,3);
    %State of charge for connecting the genset
    SOCstart=NUMERIC(2,3);
    %State of charge for disconnecting the genset
    SOCstop=NUMERIC(3,3);
    %Fuel consumption model
    %Intercept coefficient 0
    b0i=NUMERIC(6,3);
    %Intercept coefficient 1
    b1i=NUMERIC(7,3);
    %Slope coefficient 0
    b0s=NUMERIC(8,3);
    %Slope coefficient 1
    b1s=NUMERIC(9,3);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Genset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wind generator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Application==3 || Application==4)
    %Read the sheet
    SheetName='Wind';
    clear NUMERIC TXT;
    [NUMERIC, TXT]=xlsread(file1,SheetName);
    %Rated electrical power
    PWnom=NUMERIC(1,3);
    %Rated wind speed
    Vnom=NUMERIC(2,3);
    %Cut-in wind speed
    Vci=NUMERIC(3,3);
    %Cut-out wind speed
    Vco=NUMERIC(4,3);
    %Equivalent power coefficient (Cpeq=0,5·r·A·Cp), kW/(m/s)3    
    Cpeq=PWnom/(Vnom^3-Vci^3);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Wind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%