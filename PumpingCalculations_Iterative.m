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
      
            %Initial pump efficiency 
            etap_prev=1;
            %Iterations to prevent an infinite loop
            iterations=0;
            while(1)
                %Power operating point on the system curve
                poly=[Ks2 Ks1 Ks0 -P2(h,d)*etap_prev/(1e-3*(Density*9.81/3600))];
                r=roots(poly);
                Q_itera=r(3); %Real root
                H_itera=Ks0+Ks1*Q_itera+Ks2*Q_itera^2;
                
                %Flow at the intersection point, Qn, of the affinity
                %parabola that includes the point (Q_itera, H_itera) and
                %the nominal pump curve
                a=Kh2-H_itera/Q_itera^2;
                b=Kh1;
                c=Kh0;
                Qn=(-b - sqrt(b^2-4*a*c))/(2*a);
                if(Qn<0)
                    Qn=(-b + sqrt(b^2-4*a*c))/(2*a);
                end
                %Head at Qn
                Hn=Kh0 + Kh1*Qn + Kh2*Qn^2;

                %Pump efficiency at Qn
                %Hydraulic power
                phn=1e-3*(Density*9.81/3600)*Hn*Qn;
                %Shaft power
                p2n=Kp20 + Kp21*Qn + Kp22*Qn^2;
                %Pump efficiency
                etap_next=phn/p2n;
                
                %Stop the program if the number of iteration exceeds one hundred
                iterations=iterations+1;
                if(iterations>100)
                    error('More than hundred iterations in PumpingCalculations_iterative function');
                end

                %If the next pump efficiency differs less than 0.1% regarding the previous 
                %efficiency the loop stops;
                if(abs(etap_next-etap_prev)<0.001)
                    break;
                else
                    etap_prev=etap_next;
                end
            end

            %Pump speed
            %Normalised speed, rpm=RPM/RPMnom
            rpm(h,d)=Q_itera/Qn;
            %Speed
            RPM(h,d)=rpm(h,d)*RPMnom;

            %System shutdown
            if ( RPM(h,d)<RPMcool || rpm(h,d)<sqrt(Ks0/Kh0) )
                PumpingOFF;
            else
                %Flow Q, m3/h
                Q(h,d)=Q_itera;
                %Head H, m
                H(h,d)=H_itera;

                %Limitation at maximum speed
                if(Q(h,d)>Qmax)
                    Q(h,d)=Qmax;
                    H(h,d)=Hmax;
                    P2(h,d)=P2max;
                    RPM(h,d)=RPMmax;
                    rpm(h,d)=RPMmax/RPMnom;
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

                %Efficiencies
                ETAP(h,d)=PH(h,d)/P2(h,d);
                ETAM(h,d)=P2(h,d)/P1(h,d);
                ETAMP(h,d)=ETAP(h,d)*ETAM(h,d);
            end
        end
    end
end