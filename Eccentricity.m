%Eccentricity, dimensionless
%Initialization to zero
Eo=zeros(1,Ndays);
%Calculation
for i=1:Ndays
    %Spencer equations
    %Gamma
    gamma=(i-1)*2*pi/365;
    %Eccentricity correction factor
    Eo(i)=1.00011+(0.034221*cos(gamma))+(0.001280*sin(gamma))+(0.000719*cos(2*gamma))+(0.000077*sin(2*gamma));
end