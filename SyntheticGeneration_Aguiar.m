%Sinthetic series of KTd (daily variability) using the method of Aguiar

%Daily Extraterrestial Horizontal Irradiation, Wh/m2
%Initialization to zero
BOd0=zeros(1,Ndays);
%Calculation
for i=1:Ndays
    BOd0(i)=24/pi*1367*Eo(i)*((-1)*ws(i)*(sin(delta(i))*sin(lat))-cos(delta(i))*cos(lat)*sin(ws(i)));
end

%Monthly mean of the Daily Extraterrestial Horizontal Irradiation, Wh/m2 (12 values)
BOdm0=MonthlyAverage(BOd0);

%Monthly mean of the daily clearness index (12 values)
KTdm=Gdm0./BOdm0;

%Synthetic generation of the Daily Clearness Index (365 values)
KTd=DailyKTSeries(KTdm);

%Synthetic Daily Global Horizontal Irradiation, Wh/m2
Gd0=KTd.*BOd0;

%Daily diffuse fraction, KDd
%Initialization to zero
KDd=zeros(1,Ndays);
%Calculation
DiffuseFraction;

%Daily horizontal irradiations, Wh/m2
%Initialization to zero
Bd0=zeros(1,Ndays);
Dd0=zeros(1,Ndays);
%Estimation of the Direct and Diffuse Components of Horizontal Radiation
for d=1:Ndays
    %Horizontal diffuse irradiation
    Dd0(d)=Gd0(d)*KDd(d);
    %Horizontal beam irradiation
    Bd0(d)=Gd0(d)*(1-KDd(d));
end

%Horizontal irradiances, W/m2
%Matrix initialisation to zero
G0=zeros(Nsteps, Ndays);
B0=zeros(Nsteps, Ndays);
D0=zeros(Nsteps, Ndays);
rd=zeros(Nsteps, Ndays);
rg=zeros(Nsteps, Ndays);
%Calculations
for d=1:Ndays
     %Liu and Jordan parameters
     a2(d)=0.409-0.5016*sin(ws(d)+1.047);
     b2(d)=0.6609+0.4767*sin(ws(d)+1.047);
     %Counters initialisation
     sumrg=0;
     sumrd=0;
     %Calculation of rd and rg
     for h=1:Nsteps
        if (abs(w(h,d))>=abs(ws(d)))
            rd(h,d)=0;
            rg(h,d)=0;
        else
            rd(h,d)=pi/24*(cos(w(h,d))-cos(ws(d)))/(ws(d)*cos(ws(d))-sin(ws(d)));
            rg(h,d)=rd(h,d)*(a2(d)+b2(d)*cos(w(h,d)));
            sumrd=sumrd + rd(h,d);
            sumrg=sumrg + rg(h,d);
        end
     end
     %Correction to ensure that the sum of rd and rg is unity
     for h=1:Nsteps
        if (sumrd==0)
            rd(h,d)=0;
            rg(h,d)=0;
        else
            rd(h,d)=rd(h,d)/sumrd*Stepph;
            rg(h,d)=rg(h,d)/sumrg*Stepph;
        end
     end
     %Irradiance components
     for h=1:Nsteps
        if (abs(w(h,d))>=abs(ws(d)))
            G0(h,d)=0;
            D0(h,d)=0;
            B0(h,d)=0;
        else
            G0(h,d)=Gd0(d)*rg(h,d);
            D0(h,d)=Dd0(d)*rd(h,d);
            B0(h,d)=G0(h,d)-D0(h,d);
        end
     end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End of calculation of horizontal irradiances
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%