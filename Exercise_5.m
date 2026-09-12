%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PVlite: A simulator of PV systems applications.
% Derechos de autor/copyright: Federico Javier Muñoz Cano.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXERCISE_5
% Plot iso-reliability LLP curves.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Clear workspace
clear;

%Input data
disp('Reading inputs ...')

%Read input parameters from excel sheet;
ReadInputData;
disp('Inputs Ok');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Values for the sweep
sweep1=[10:0.5:25]; %PV generator nominal power
sweep2=[50:25:250]; %Nominal battery capacity

%n is the size of the sweep1
[m,n]=size(sweep1);
%n2 is the size of sweep2
[m2,n2]=size(sweep2);

data=zeros(n*n2,3);
variables=zeros(n, n2);

Y1=zeros(n, n2);
Y2=zeros(n, n2);
Y3=zeros(n, n2);

fila=1;
for q=1:n
    for q2=1:n2

    PVnom=sweep1(q);
    CBAT=sweep2(q2);
    
    %Irradiances
    Irradiances;

    %Temperatures
    Temperatures;

    %PV power
    PVpower;

    %Load consumption
    LoadProfiles;

    %Power calculations
    PowerCalculations;

    %Results
    DailyParameters;
    MonthlyParameters;
    YearlyParameters;

    %Analysis
    %LLH
    Y1(q,q2)=LLHa;

    %LLP
    Y2(q,q2)=LLPa;

    %PR
    Y3(q,q2)=PRa;

    data(fila, 1)=PVnom;
    data(fila, 2)=CBAT;
    data(fila, 3)=PRa;

    fila=fila+1;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Iso-reliability LLP map versus PVnom and CBAT
ax=gca;

%Sweeps
%CBAT
X=sweep2; 
%PVnom
%To include additional constant power losses, relative to the
%nominal PV generator power, set PRL<=1.
PRL=0.75;
Y=sweep1/PRL; 

%Plot curves
contour(X, Y, Y2, [0.1 0.05 0.01], 'Color','k', 'LineWidth', 2, 'ShowText','off');

%Colormap("gray")
colormap("bone")

xlabel('Nominal battery capacity CBAT, [kWh]','Color','k');
ylabel('Nominal PV power, [kW]', 'Color','k')

ax.FontSize = 24;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%