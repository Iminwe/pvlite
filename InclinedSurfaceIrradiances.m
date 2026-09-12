%InclinedSurfaceIrradiances
%Angle of incidence
%Matrix initialisation to zero
alpha=zeros(Nsteps, Ndays);
beta=zeros(Nsteps, Ndays);
xsun=zeros(Nsteps, Ndays);
ysun=zeros(Nsteps, Ndays);
zsun=zeros(Nsteps, Ndays);
xsurf=zeros(Nsteps, Ndays);
ysurf=zeros(Nsteps, Ndays);
zsurf=zeros(Nsteps, Ndays);
costetas=zeros(Nsteps, Ndays);
tetas=zeros(Nsteps, Ndays);
AMI=zeros(Nsteps, Ndays);

%Calculations
for d=1:Ndays
     for h=1:Nsteps
         %PV generator position
         if (Mounting==1)
             %Ground or roof
             %Alpha
             alpha(h,d)=Orientation*pi/180;
             %Beta
             beta(h,d)=Inclination*pi/180;
         
         elseif (Mounting==2)
             %Delta
             %Alpha
             alpha(h,d)=Orientation*pi/180;
             %Beta
             beta(h,d)=Inclination*pi/180;

         elseif (Mounting==3)
             %One axis N-S horizontal tracker
             %Alpha
             if fis(h,d)<=0;
                 alpha(h,d)=-pi/2;
             else
                 alpha(h,d)=pi/2;
             end
             %Beta
             if(gammas(h,d)==0)
                 beta(h,d)=0;
             else
                 beta(h,d)=atan(abs(sin(fis(h,d)))/tan(gammas(h,d)));
             end
         
         elseif (Mounting==4)
             %One axis vertical (azimutal) tracker
             %Alpha
             alpha(h,d)=fis(h,d);
             %Beta
             beta(h,d)=Inclination*pi/180;
         
         elseif (Mounting==5)
             %Two-axis tracker
             %Alpha
             alpha(h,d)=fis(h,d);
             %Beta
             beta(h,d)=tetazs(h,d);

         end
    
         %Coordinates of unit vector of the Sun in a Cartesian coordinate system 
         %0XYZ, whose origen (0) is placed in the location and with the axis
         %X, Y, Z pointing to West, South and Zenith, respectively.
         xsun(h,d)=cos(gammas(h,d))*sin(fis(h,d));
         ysun(h,d)=cos(gammas(h,d))*cos(fis(h,d));
         zsun(h,d)=sin(gammas(h,d));

         %Coordinates of the normal unit vector of the surface
         xsurf(h,d)=sin(beta(h,d))*sin(alpha(h,d));
         ysurf(h,d)=sin(beta(h,d))*cos(alpha(h,d));
         zsurf(h,d)=cos(beta(h,d));
    
         %Cosines of the incidence angle
         if (abs(w(h,d))>=abs(ws(d)))
             costetas(h,d)=0;
         else
             costetas(h,d)=xsun(h,d)*xsurf(h,d)+ysun(h,d)*ysurf(h,d)+zsun(h,d)*zsurf(h,d);
         end
    
         %incidence angle
         tetas(h,d)=acos(costetas(h,d));
     end
end

%Irradiance components
%Matrix initialisation to zero
G=zeros(Nsteps, Ndays); %Global
B=zeros(Nsteps, Ndays); %Beam
D=zeros(Nsteps, Ndays); %Diffuse
R=zeros(Nsteps, Ndays); %Albedo
Gef=zeros(Nsteps, Ndays); %Global effective
Bef=zeros(Nsteps, Ndays); %Beam effective
Def=zeros(Nsteps, Ndays); %Diffuse effective
Ref=zeros(Nsteps, Ndays); %Albedo effective
%Auxiliar
K1=zeros(Nsteps, Ndays);
K2=zeros(Nsteps, Ndays);
Diso=zeros(Nsteps, Ndays);
Dcir=zeros(Nsteps, Ndays);
Dhor=zeros(Nsteps, Ndays);
FB=zeros(Nsteps, Ndays);
FD=zeros(Nsteps, Ndays);
FR=zeros(Nsteps, Ndays);
%Calculations
for d=1:Ndays
     for h=1:Nsteps
         %Beam irradiance component
         if (abs(w(h,d))>=abs(ws(d)))
            B(h,d)=0;
            Bn(h,d)=0;
         else
            B(h,d)=B0(h,d)*max(0,costetas(h,d))/costetazs(h,d);
            Bn(h,d)=B0(h,d)/costetazs(h,d);
         end
         
         %Diffuse component.
         %Isotropic model
         if(Diffuse_model==1)
             K1(h,d)=0;
             %Anulation of the diffuse horizontal component (Perez Model)
             K2(h,d)=0;
         %Anisotropic (Hay model).
         elseif(Diffuse_model==2)
             if (abs(w(h,d))>=abs(ws(d)))
                K1(h,d)=0;
             else
                K1(h,d)= B0(h,d)/(1367*Eo(d)*costetazs(h,d));
             end
             %Anulation of the diffuse horizontal component (Perez Model)
             K2(h,d)=0;
         %Anisotropic (Perez Model)
         elseif(Diffuse_model==3)
             AirMass;
             PerezModel;
         end

         %Diffuse irradiance components: isotropic (Diso) and circumsolar (Dcir)
         if (abs(w(h,d))>=abs(ws(d)))
            Diso(h,d)=0;
            Dcir(h,d)=0;
            Dhor(h,d)=0;
            D(h,d)=0;
         else
            Diso(h,d)=D0(h,d)*(1-K1(h,d))*(1+cos(beta(h,d)))/2;
            Dcir(h,d)=D0(h,d)*K1(h,d)*max(0,costetas(h,d))/costetazs(h,d);
            Dhor(h,d)=D0(h,d)*K2(h,d)*sin(beta(h,d));
            D(h,d)=Diso(h,d)+Dcir(h,d)+Dhor(h,d);
         end
        
         %Albedo irradiance component
         if (abs(w(h,d))>=abs(ws(d)))
            R(h,d)=0;
         else
            R(h,d)=GroundReflectance*G0(h,d)*(1-cos(beta(h,d)))/2;
         end
        
         %Global irradiance
         G(h,d)=B(h,d)+D(h,d)+R(h,d);

         %Effects of incidence angle and dust
         %Model parameters
         if (DustDegree==1)
             FT=1; ar=0.17; c1=4/(3*pi); c2=-0.069; 
         elseif (DustDegree==2)
             FT=0.98; ar=0.2; c1=4/(3*pi); c2=-0.054; 
         elseif (DustDegree==3)
             FT=0.97;ar=0.21; c1=4/(3*pi); c2=-0.049; 
         elseif (DustDegree==4)
             FT=0.92; ar=0.27; c1=4/(3*pi); c2=-0.023; 
         end
         %Correction factors
         if (abs(w(h,d))>=abs(ws(d)))
             %Set corrections factors to 100%, which anulates the effective
             %irradiances
             FB(h,d)=1;
             FD(h,d)=1;
             FR(h,d)=1;
         else
             %Correction of the beam irradiance
             FB(h,d)=(exp(-costetas(h,d)/ar)-exp(-1/ar))/(1-exp(-1/ar));
             %Correction of the diffuse irradiance (isotropic component)
             fun1(h,d)=sin(beta(h,d))+(pi-beta(h,d)-sin(beta(h,d)))/(1+cos(beta(h,d)));
             FD(h,d)=exp(-(1/ar)*(c1*fun1(h,d)+c2*fun1(h,d)^2));
             %Correction of the albedo irradiance
             if (beta(h,d)<0.01)
                 FR(h,d)=0;
             else
                 fun2(h,d)=sin(beta(h,d))+(beta(h,d)-sin(beta(h,d)))/(1-cos(beta(h,d)));
                 FR(h,d)=exp(-(1/ar)*(c1*fun2(h,d)+c2*fun2(h,d)^2));
             end
         end

         %Effective irradiance components
         Bef(h,d)=B(h,d)*(1-FB(h,d))*FT;
         Def(h,d)=(Dcir(h,d)*(1-FB(h,d))+Diso(h,d)*(1-FD(h,d)))*FT;
         Ref(h,d)=R(h,d)*(1-FR(h,d))*FT;

         %Effective global irradiance
         Gef(h,d)=Bef(h,d)+Def(h,d)+Ref(h,d);
     end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End of calculation of irradiances on the inclined plane
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%