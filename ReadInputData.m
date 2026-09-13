%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ReadInputData.m
% Loads all input parameters required for the simulation from the selected Excel spreadsheet.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Open a window to select the input data excel file
if ~exist('file1', 'var') || isempty(file1)
    [script_dir, ~, ~] = fileparts(mfilename('fullpath'));
    [file, path] = uigetfile(fullfile(script_dir, 'inputdata', '*.xlsx'),'Select the input data file');
    if isequal(file,0)
        error('The file has not been selected');
    end
    file1 = fullfile(path, file);
end

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
clear NUMERIC TXT RAW;
[NUMERIC, TXT, RAW]=xlsread(file1,SheetName);

% Detect the new database-style PVgen layout.
% Legacy workbooks have no Use_Database header
isNewPV = HasDatabaseHeader(RAW);
if isNewPV
    pvOffset = 3;
else
    pvOffset = 0;
end

% The database selector only exists in the new layout.
if isNewPV && size(NUMERIC,1) >= 1 && ~isnan(NUMERIC(1,3))
    Use_Database_PV = NUMERIC(1,3);
else
    Use_Database_PV = 1; % Default to manual input
end

if Use_Database_PV == 2
    % Read module name from Row 5 in Excel, column C
    module_name = RAW{5, 3};
    % Read number of modules from Row 6 in Excel, column C
    N_modules = NUMERIC(3, 3);

    [PVnom_module, CVPT, NOCT] = Load_CEC_Module(module_name);

    % Total PV power = module power * number of modules
    PVnom = PVnom_module * N_modules;

    % Calculate thermal resistance from NOCT
    Rth = (NOCT - 20) / 800;
else
    module_name = '';
    N_modules = 1;

    % Manual PV parameters. pvOffset: 3 new sheets, 0 legacy
    PVnom = NUMERIC(1 + pvOffset, 3);
    CVPT = NUMERIC(2 + pvOffset, 3);
    NOCT = NUMERIC(3 + pvOffset, 3);
    Rth = NUMERIC(4 + pvOffset, 3);
end

% Mounting structure
Mounting = NUMERIC(6 + pvOffset, 3);
if (Mounting == 1)
    % Static ground or roof
    Inclination = NUMERIC(9 + pvOffset, 3);
    Orientation = NUMERIC(10 + pvOffset, 3);
elseif (Mounting == 2)
    % Static delta: same inclination for East and West structures
    Inclination = NUMERIC(13 + pvOffset, 3);
elseif (Mounting == 4)
    % Azimuthal tracker
    Inclination = NUMERIC(16 + pvOffset, 3);
end
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End PVgen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inverter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read the sheet
SheetName='Inverter';
clear NUMERIC TXT RAW;
[NUMERIC, TXT, RAW]=xlsread(file1,SheetName);

% Detect the new database-style Inverter layout.
% Legacy workbooks have no Use_Database header
isNewInv = HasDatabaseHeader(RAW);
if isNewInv
    invOffset = 2;
else
    invOffset = 0;
end

% The database selector only exists in the new layout.
if isNewInv && size(NUMERIC,1) >= 1 && ~isnan(NUMERIC(1,3))
    Use_Database_Inv = NUMERIC(1,3);
else
    Use_Database_Inv = 1; % Default to manual input
end

if Use_Database_Inv == 2
    % Read inverter name from Row 5 in Excel, column C
    inverter_name = RAW{5, 3};
    [PInom, PImax, k0, k1, k2] = Load_CEC_Inverter(inverter_name, 'battery');
else
    inverter_name = '';

    % Manual inverter parameters. invOffset: 2 new sheets, 0 legacy
    PInom = NUMERIC(1 + invOffset, 3);
    PImax = NUMERIC(2 + invOffset, 3);
    InverterCurve = NUMERIC(3 + invOffset, 3);
    if(InverterCurve == 1)
        % Power efficiency curve parameters
        k0 = NUMERIC(5 + invOffset, 3);
        k1 = NUMERIC(6 + invOffset, 3);
        k2 = NUMERIC(7 + invOffset, 3);
    else
        % Previous parameters from the power efficiency points
        [k0, k1, k2] = InverterParameters(NUMERIC((10 + invOffset):(15 + invOffset), 2), NUMERIC((10 + invOffset):(15 + invOffset), 3));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Inverter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grid Inverter (Only used in AC bus Application == 4)
% Moved after Options section where Application is read
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

%Project Lifetime and Degradation
if size(NUMERIC,1) >= 7 && ~isnan(NUMERIC(7,3))
    Project_Lifetime = NUMERIC(7,3);
else
    Project_Lifetime = 1; % Default to 1 year if not specified
end

if size(NUMERIC,1) >= 8 && ~isnan(NUMERIC(8,3))
    PV_Degradation_Rate = NUMERIC(8,3); % e.g., 0.008 for 0.8%
else
    PV_Degradation_Rate = 0; % Default to 0 degradation
end

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

%PV Distribution in Mixed Node (DC vs AC), Hybrid AC bus only (Application == 4)
if Application == 4
    %Re-read PVgen sheet to get PV_DC_share
    [NUMERIC_PV, ~]=xlsread(file1,'PVgen');
    % NUMERIC drops the first 3 text rows. So Excel Row 23 is NUMERIC Row 20.
    if size(NUMERIC_PV,1) >= 21 && ~isnan(NUMERIC_PV(21,3))
        PV_DC_share = NUMERIC_PV(21,3);
    else
        PV_DC_share = 0.5; % Default value if not specified
    end
else
    PV_DC_share = 1.0; % All PV goes to DC bus for standalone and DC hybrid
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Options
PlotEconomicsFlag = 1; % Generate economic charts by default
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grid Inverter (Only used in AC bus Application == 4)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Application == 4
    %Read the sheet
    SheetName='GridInverter';
    clear NUMERIC TXT RAW;
    try
        [NUMERIC, TXT, RAW]=xlsread(file1,SheetName);
        
        % Check if user wants to use database for GridInverter
        if size(NUMERIC,1) >= 1 && ~isnan(NUMERIC(1,3))
            Use_Database_GridInv = NUMERIC(1,3);
        else
            Use_Database_GridInv = 1; % Default to manual input
        end
        
        if Use_Database_GridInv == 2
            % Grid inverter name: Excel Row 5 col C (RAW uses Excel row/col directly)
            grid_inverter_name = RAW{5, 3};
            [PGInom, PGImax, k0_g, k1_g, k2_g] = Load_CEC_Inverter(grid_inverter_name, 'grid');
        else
            %Nominal output power, kW
            PGInom=NUMERIC(3,3);
            %Maximum output power, kW
            PGImax=NUMERIC(4,3);
            %Power efficiency curve
            GridInverterCurve=NUMERIC(5,3);
            if(GridInverterCurve==1)
                %Power efficiency curve parameters
                k0_g=NUMERIC(7,3);
                k1_g=NUMERIC(8,3);
                k2_g=NUMERIC(9,3);
            else
                %Previous parameters from the power efficiency points
                [k0_g, k1_g, k2_g]=GridInverterParameters(NUMERIC(12:17,2), NUMERIC(12:17,3));
            end
        end
    catch
        warning('Worksheet ''GridInverter'' not found or incorrectly formatted. Hybrid AC bus systems require this sheet.');
        error('Simulation stopped: Missing GridInverter data for Application=4');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End Grid Inverter
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load MKBM Battery Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ReadBatteryMKBM;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Economics Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    SheetName='Economics';
    clear NUMERIC TXT RAW;
    [NUMERIC, TXT, RAW]=xlsread(file1,SheetName);
    
    if size(NUMERIC,1) >= 1 && ~isnan(NUMERIC(1,3))
        PV_Module_Cost = NUMERIC(1,3);
    else
        PV_Module_Cost = 0;
    end
    
    if size(NUMERIC,1) >= 2 && ~isnan(NUMERIC(2,3))
        Inverter_Cost = NUMERIC(2,3);
    else
        Inverter_Cost = 0;
    end
    
    if size(NUMERIC,1) >= 3 && ~isnan(NUMERIC(3,3))
        Battery_Cost = NUMERIC(3,3);
    else
        Battery_Cost = 0;
    end
    
    if size(NUMERIC,1) >= 4 && ~isnan(NUMERIC(4,3))
        Genset_Cost = NUMERIC(4,3);
    else
        Genset_Cost = 0;
    end
    
    if size(NUMERIC,1) >= 5 && ~isnan(NUMERIC(5,3))
        Wind_Cost = NUMERIC(5,3);
    else
        Wind_Cost = 0;
    end
    
    if size(NUMERIC,1) >= 6 && ~isnan(NUMERIC(6,3))
        Fuel_Cost = NUMERIC(6,3);
    else
        Fuel_Cost = 0;
    end
    
    if size(NUMERIC,1) >= 7 && ~isnan(NUMERIC(7,3))
        Fixed_Installation_Cost = NUMERIC(7,3);
    else
        Fixed_Installation_Cost = 0;
    end
    
    if size(NUMERIC,1) >= 8 && ~isnan(NUMERIC(8,3))
        Opex_Factor = NUMERIC(8,3);
    else
        Opex_Factor = 0;
    end
    
    if size(NUMERIC,1) >= 9 && ~isnan(NUMERIC(9,3))
        Discount_Rate = NUMERIC(9,3);
    else
        Discount_Rate = 0;
    end
catch
    disp('Warning: Could not read Economics sheet. Defaulting economic parameters to 0.');
    PV_Module_Cost = 0;
    Inverter_Cost = 0;
    Battery_Cost = 0;
    Genset_Cost = 0;
    Wind_Cost = 0;
    Fuel_Cost = 0;
    Fixed_Installation_Cost = 0;
    Opex_Factor = 0;
    Discount_Rate = 0;
end

