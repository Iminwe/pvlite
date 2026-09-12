%Calculation of ambient and cell temperatures
if (InputData==1 || InputData==2 || InputData==4)
    %Matrix initialisation to zero
    Ta=zeros(Nsteps, Ndays);
    %Daily maximum and minimum temperatures
    TM=MonthlyAverageToAll(TMm);
    Tm=MonthlyAverageToAll(Tmm);         
    %Calculations ambient temperature profiles
    for d=1:Ndays
        %Daily coefficients
        a3(d)=-pi/(ws(d)+2*pi-pi/6);
        b3(d)=-a3(d)*ws(d);
        a4(d)=pi/(ws(d)-pi/6);
        b4(d)=-a4(d)*pi/6;
        a5(d)=pi/(2*pi+ws(d)-pi/6);
        b5(d)=-(pi+a5(d)*pi/6);
        for h=1:Nsteps
            %Ambient temperature, Ta
            if ((-pi<w(h,d))&&(w(h,d)<ws(d)))
                Ta(h,d)=TM(d)-(TM(d)-Tm(d))/2*(1+cos(a3(d)*w(h,d)+b3(d)));
            elseif (ws(d)<w(h,d))&&(w(h,d)<pi/6)
                Ta(h,d)=Tm(d)+(TM(d)-Tm(d))/2*(1+cos(a4(d)*w(h,d)+b4(d)));
            else
                Ta(h,d)=TM(d)-(TM(d)-Tm(d))/2*(1+cos(a5(d)*w(h,d)+b5(d)));
            end
        end
    end
elseif (InputData==3 || InputData==5)
    Ta=Ta_TMY;
end
%Cell temperature, Tc
Tc=Ta+Rth*Gef;