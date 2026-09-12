%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PVlite: A simulator of PV systems applications.
% Derechos de autor/copyright: Federico Javier Muñoz Cano.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXERCISE_3
% Calculate the monthly average of daily irradiations Gdm on the tilted 
% planes for different inclinations.
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
%Inclinations
sweep1=[20:10:80];
Orientation=0;
%n is the number of inclinations
[m,n]=size(sweep1);

for q=1:n
    %Sweep variable
    Inclination=sweep1(q);
    
    %Irradiances
    Irradiances;

    %Daily in-plane global irradiations, Wh/m2
    Gd=sum(G)/Stepph;

    %Monhtly in-plane global irradiations, Wh/m2
    Gm=MonthlySum(Gd);
    
    %Monthly average of daily in-plane irradiations, Wh/m2
    Gdm=Gm./MonthLength;

    %Analysis, Gdm for each inclination
    Gdm_beta(:, q)=Gdm';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Results
%Inclinations
disp('Inclinations')
sweep1
%Irradiations
disp('Irradiations')
Gdm_beta