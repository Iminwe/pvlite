%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PVlite: A simulator of PV systems applications.
% Derechos de autor/copyright: Federico Javier Muñoz Cano.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXERCISE_4
% Find the optimum inclination for a stand-alone PV generator.
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
MonthLength=[31,28,31,30,31,30,31,31,30,31,30,31];

%Values for the sweep
sweep1=[20:1:80]; %Inclinations, rows
sweep2=0; %Orientation, columns
%n is the size of the sweep1
[m,n]=size(sweep1);
%n2 is the size of sweep2
[m2,n2]=size(sweep2);

data=zeros(n*n2,3);
fila=1;

for q=1:n
    for q2=1:n2
    %Sweep variable
    Inclination=sweep1(q);
    Orientation=sweep2(q2);
    
    %Irradiances
    Irradiances;

    %Daily in-plane global irradiations, Wh/m2
    Gd=sum(G)/Stepph;

    %Monhtly in-plane global irradiations, Wh/m2
    Gm=MonthlySum(Gd);
    
    %Monthly average of daily in-plane irradiations, Wh/m2
    Gdm=Gm./MonthLength;

    %Analysis
    data(fila, 1)=Inclination;
    %For each inclination find the maximum ratio consumption/irradiation
    data(fila, 2)=max(Ldm./Gdm);
    %Month with lowest irradiation
    data(fila, 3)=min(Gdm);
    
    fila=fila+1;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Find minimum of the maximum ratios Ldm/Gm (whose index is b)
[a, b]=min(data(:, 2));

%Find the corresponding inclination for that maximum.
disp('The optimum angle for a stand-alone PV generator is:')
Optimum_Inclination=data(b, 1)
%disp('Monthly irradiation Gdm:')
%Gdm_beta=data(b, 3)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%