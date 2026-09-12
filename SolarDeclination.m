%SolarDeclination, radian
%Initialization to zero
delta=zeros(1,Ndays);
for i=1:Ndays
    %Spencer equations
    %Gamma
    gamma=(i-1)*2*pi/365;
    %Solar declination, degree
    delta(i)=(0.006918-(0.399912*cos(gamma))+(0.070257*sin(gamma))-(0.006758*cos(2*gamma))+(0.000907*sin(2*gamma))-(0.002697*cos(3*gamma))+(0.00148*sin(3*gamma)))*180/pi;
    %Conversion from degree to radian
    delta(i)=delta(i)*pi/180;
end