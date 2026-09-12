%SunPosition
%Matrix initialisation to zero
costetazs=zeros(Nsteps, Ndays);
cosfis=zeros(Nsteps, Ndays);
gammas=zeros(Nsteps, Ndays);
tetazs=zeros(Nsteps, Ndays);
fis=zeros(Nsteps, Ndays);
%Calculations
for d=1:Ndays
    for h=1:Nsteps
        %Cosines of the solar zenith angle
        costetazs(h,d)=sin(delta(d))*sin(lat)+cos(delta(d))*cos(lat)*cos(w(h,d));    
        %Limitation of costetazs to positive values
        if (costetazs(h,d)<0)
            costetazs(h,d)=0;
        end
        %Limitation of tetazs to 85º maximum (******************)
        costetazs(h,d)=max(0.08715,costetazs(h,d));
        %Solar altitude angle
        gammas(h,d)=asin(costetazs(h,d));
        %Solar zenith angle
        tetazs(h,d)=pi/2-gammas(h,d);
        %Cosines of solar azimuth angle
        cosfis(h,d)=(costetazs(h,d)*sin(lat)-sin(delta(d)))*sign(lat)/(cos(gammas(h,d))*cos(lat));
        %Limitation of cosfis(h,d) to real values
        if cosfis(h,d)>1
            cosfis(h,d)=1;
        end
        if cosfis(h,d)<-1
            cosfis(h,d)=-1;
        end
        %Solar azimuth angle (negative towards the east, in the morning, and positive
        %towards the west, in the evening.
        if (w(h,d)<0)
            fis(h,d) = -acos(cosfis(h,d));
        else
            fis(h,d) = acos(cosfis(h,d));
        end
    end
end