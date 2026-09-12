%Pumping Calculations
%Matrices initialialisation
%HEAD, m
H=zeros(Nsteps, Ndays); 
%FLOW, m3/h
Q=zeros(Nsteps, Ndays);
%Motor efficiency
ETAM=zeros(Nsteps, Ndays);
%Pump efficiency
ETAP=zeros(Nsteps, Ndays);
%Motor-Pump efficiency
ETAMP=zeros(Nsteps, Ndays);
%Electric input power
P1=zeros(Nsteps, Ndays);
%Shaft power
P2=zeros(Nsteps, Ndays);
%Hidraulic power
PH=zeros(Nsteps, Ndays);
%Speed
RPM=zeros(Nsteps, Ndays);
rpm=zeros(Nsteps, Ndays);
%Equivalent flow on the nominal pump curve
Q1=zeros(Nsteps, Ndays);

%Calculations
for d=1:Ndays
    for h=1:Nsteps   
        %P1 power is equal to the output inverter power, kW
        P1(h,d)=PAC(h,d);
        %Shaft power
        if(P1(h,d)<=Km0)
            %The system is OFF
            PumpingOFF;
        else
            %Shaft power P2, kW
            a=Km2;
            b=(1+Km1);
            c=(Km0-P1(h,d));
            P2(h,d)=(-b + sqrt (b^2-4*a*c))/(2*a);
           
            %Operating point H-Q
            if(P2(h,d)<=Kq0)
                PumpingOFF;
            else  
                %Flow Q, m3/h, as a function of P2 
                a=Kq2;
                b=Kq1;
                c=Kq0-P2(h,d);
                Q(h,d)=(-b + sqrt(b^2-4*a*c))/(2*a);
                %Head H, m
                H(h,d)=Ks0+Ks1*Q(h,d)+Ks2*Q(h,d)^2;
                %Limitation at maximum speed
                if(Q(h,d)>Qmax)
                    Q(h,d)=Qmax;
                    H(h,d)=Hmax;
                    P2(h,d)=P2max;
                end
                %Hidraulic power, kW
                PH(h,d)=1e-3*(Density*9.81/3600)*H(h,d)*Q(h,d); 
                
                %Hidraulic power breakdown 
                %Static head, kW
                PH0(h,d)=1e-3*(Density*9.81/3600)*Ks0*Q(h,d);
                %Drawdown, kW
                PH1(h,d)=1e-3*(Density*9.81/3600)*Ks1*(Q(h,d)^2);
                %Friction losses, kW
                PH2(h,d)=1e-3*(Density*9.81/3600)*Ks2*(Q(h,d)^3); 
                
                %Corresponding flow point, Q1, on the nominal pump curve
                a=Kh2-H(h,d)/(Q(h,d)^2);
                b=Kh1;
                c=Kh0;
                Q1(h,d)=(-b - sqrt(b^2-4*a*c))/(2*a);
                %Normalised speed, rpm=RPM/RPMnom
                rpm(h,d)=Q(h,d)/Q1(h,d);
                %Speed
                RPM(h,d)=rpm(h,d)*RPMnom;
                %Efficiencies
                ETAP(h,d)=PH(h,d)/P2(h,d);
                ETAM(h,d)=P2(h,d)/P1(h,d);
                ETAMP(h,d)=ETAP(h,d)*ETAM(h,d);
                %If the RPM is outside the limits, the system stops
                if(RPM(h,d)<RPMcool)
                    PumpingOFF;
                    disp('Minimum cooling - System OFF')
                end
            end
        end
    end
end
