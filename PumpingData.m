%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PUMPING DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%Curve parameters
Ks=[kw2+Hf/(Qrated^2)  kw1  (Hs+Hr)];
Ks0=Ks(3);
Ks1=Ks(2);
Ks2=Ks(1);
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

%Fit pump curve with a second-degree polynomial (H=Kh0 + Kh1*Q + Kh2*Q*Q)
FitResult1=fit(Qnom', Hnom','poly2');
Kh=coeffvalues(FitResult1);
Kh0=Kh(3);
Kh1=Kh(2);
Kh2=Kh(1);

% %Pump curve
% plot(FitResult1, '-k', Qnom, Hnom, 'ko');
% xlabel('Flow [m^3/h]');
% ylabel('Head [m]');
% hold on;
% %System curve
% x=0:.1:6;
% plot(x,polyval(Ks,x), '-k')
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
%Fit pump curve with a second-degree polynomial
FitResult3=fit(QnomP1', P1nom','poly2');
Kp1=coeffvalues(FitResult3);
Kp10=Kp1(3);
Kp11=Kp1(2);
Kp12=Kp1(1);

%Nominal curve of shaft power P2, kW							
QnomP2=NUMERIC(65:74,2)';
%Removes NaN
QnomP2(isnan(QnomP2))=[];
%P2 power
P2nom=NUMERIC(65:74,3)';
%Removes NaN
P2nom(isnan(P2nom))=[];
%Fit pump curve with a second-degree polynomial
FitResult4=fit(QnomP2', P2nom','poly2');
Kp2=coeffvalues(FitResult4);
Kp20=Kp2(3);
Kp21=Kp2(2);
Kp22=Kp2(1);

% %Plot input data and fit results
% figure
% plot(FitResult3, '-k', Qnom, P1nom, 'ko');
% hold on
% plot(FitResult4, '-k', Qnom, P2nom, 'ks');
% ylabel('Power [kW]');
% xlabel('Flow [m^3/h]');
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
%Fitting
warning('off','all');
model = fittype('100*p2motor/(p2motor+(Km0+Km1*p2motor+Km2*p2motor*p2motor))','ind','p2motor','dep','eta_m');
%Fitted coeficcients
[Fitresult5, goodness, output] = fit(P2motor', eta_motor', model);
coefficients=coeffvalues(Fitresult5);
Km0=coefficients(1);
Km1=coefficients(2);
Km2=coefficients(3);
warning('on','all');

%Draw a plot with data and model
% plot(Fitresult5, '-k', P2motor, eta_motor, 'ko');
% ylabel('Motor power efficiency [%]');
% xlabel('P_2 [kW]');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Curve Q-P2 at variable speed
%Flow sweep
Q2=Qrated/100:Qrated/100:1.5*Qrated;
for i=1:length(Q2)
    %Head H2 corresponding to Q2 on the system curve
    %H2(i)=Ks(3)+Ks(1)*Q2(i)^2;
    H2(i)=Ks(3)+Ks(2)*Q2(i)+Ks(1)*Q2(i)^2;
    
    %Flow Q1 at point 1 on the nominal pump curve
    a=Kh(1)-H2(i)/(Q2(i)^2);
    b=Kh(2);
    c=Kh(3);
    Q1(i)=(-b - sqrt(b^2-4*a*c))/(2*a);
    %Head at point 1 on the pump curve
    H1(i)=Kh0 + Kh1*Q1(i) + Kh2*Q1(i)*Q1(i);
    %Hidraulic power at point 1, kW
    PH1(i)=1e-3*(Density*9.81/3600)*H1(i)*Q1(i);
    %Shaft power at point 1, kW
    P21(i)=Kp20 + Kp21*Q1(i) + Kp22*Q1(i)*Q1(i);
    %Pump efficiency at point 1
    eta_p1(i)=PH1(i)/P21(i);
    %Which is equal to pump efficiency in point 2
    eta_p2(i)=eta_p1(i);
    %Hidraulic power at point 2, kW
    PH2(i)=1e-3*(Density*9.81/3600)*H2(i)*Q2(i);
    %Shaft power at point 2;
    P22(i)=PH2(i)/eta_p2(i);
    rpm2(i)=Q2(i)/Q1(i);
end
%Fit P22-Q22 curve with a second orden polynomial P22=Kq0 + Kq1*Q + Kq2*Q*Q
FitResult6=fit(Q2', P22','poly2');
Kq=coeffvalues(FitResult6);
Kq0=Kq(3);
Kq1=Kq(2);
Kq2=Kq(1);

%plot(FitResult6, '-k', Q2, P22, '--k');
%P22fit=Kq0+Kq1*Q2+Kq2*Q2.*Q2;
%plot(rpm2, P22)
%plot(rpm2, P22fit)
%plot(rpm2, Q2)
%plot(P22, Q2, '-k', P22fit, Q2, '--k');

%RPMmin, rpm
rpmmin=sqrt(Ks0/Kh0);
RPMmin=RPMnom*rpmmin;

%Flow at the intersection point, Qn, of the system curve and the nominal pump curve
a=Kh2-Ks2;
b=Kh1;
c=Kh0-Ks0;
Qn=(-b - sqrt(b^2-4*a*c))/(2*a);
if(Qn<0)
    Qn=(-b + sqrt(b^2-4*a*c))/(2*a);
end
%Maximum flow, m3/h, and head, m
Qmax=Qn*(RPMmax/RPMnom);
Hmax=Ks0+Ks2*(Qmax^2);
%Maximum hidraulic power, kW
PHmax=1e-3*(Density*9.81/3600)*Hmax*Qmax;
%Maximum shaft power, kW
P2max=Kq0 + Kq1*Qmax + Kq2*Qmax*Qmax;
%Maximum P1 power, kW
P1max=P2max + Km0 + Km1*P2max + Km2*P2max*P2max;
%New maximum inverter power
if (P1max<PImax)
    disp('Warning: the maximum pump speed will limit the maximum inverter power to P1max [kW]');
    P1max
end
PImax=P1max;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%