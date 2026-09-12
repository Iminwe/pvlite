%Calculation of daily diffuse fraction using correlation models
%for monthly diffuse fractions
for i=1:Ndays
    %Page
    if (Diffuse_fraction==1)
        KDd(i)=max(1-1.13*KTd(i), 0.1);
    %Collares Pereira and Rabl
    elseif (Diffuse_fraction==2) 
        if(KTd(i)<=0.2)
            KDd(i)=0.775+0.347*(abs(ws(i))-pi/2)-(0.505+0.261*(abs(ws(i))-pi/2))*cos(2*(0.2-0.9));
        elseif (KTd(i)>0.2 && KTd(i)<0.8)
            KDd(i)=0.775+0.347*(abs(ws(i))-pi/2)-(0.505+0.261*(abs(ws(i))-pi/2))*cos(2*(KTd(i)-0.9));
        else
            KDd(i)=0.775+0.347*(abs(ws(i))-pi/2)-(0.505+0.261*(abs(ws(i))-pi/2))*cos(2*(0.8-0.9));
        end     
    %Erbs
    elseif (Diffuse_fraction==3)    
        if (ws(i)<=1.4208)
            if(KTd(i)<0.3)
                KDd(i)=0.6423;
            elseif(KTd(i)>=0.3 && KTd(i)<=0.8)
                KDd(i) = 1.391-3.56*KTd(i)+4.189*KTd(i)*KTd(i)-2.137*KTd(i)*KTd(i)*KTd(i);
            else
                KDd(i)=0.1298;
            end
        elseif (ws(i)>1.4208)
            if(KTd(i)<0.3)
                KDd(i)=0.6637;
            elseif(KTd(i)>=0.3 && KTd(i)<=0.8)
                KDd(i) = 1.311-3.022*KTd(i)+3.427*KTd(i)*KTd(i)-1.821*KTd(i)*KTd(i)*KTd(i);
            else
                KDd(i)=0.1543;
            end
        end
    %Macagnan
    elseif (Diffuse_fraction==4)
        KDd(i)=max(0.758-0.428*KTd(i)-0.503*KTd(i)*KTd(i),0.1);
    else
        error('Daily diffuse fraction option is wrong');
    end
end