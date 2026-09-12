%EquationOfTime, radian
%Initialization to zero
ET=zeros(1,Ndays);
for i=1:Ndays
    %Gamma
    gamma=(i-1)*2*pi/365;
    %Equation of time, radians
    ET(i)=0.000075+0.001868*cos(gamma)-0.032077*sin(gamma)-0.014615*cos(2*gamma)-0.04089*sin(2*gamma);
end