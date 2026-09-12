%Air mass calculation
%Model coefficients;
h0  = 8434.5;
cr1 = 0.061359;
cr2 = 0.1594;
cr3 = 1.123;
cr4 = 0.065656;
cr5 = 28.9344;
cr6 = 277.3971;
ma1 = 0.50572;
ma2 = 6.07995;
ma3 = -1.6364;

%Calculations
%Altitude correction
altitude_correction=exp(-Altitude/h0);
%Refraction correction
delta_gammas(h,d)=cr1*(cr2 + cr3*gammas(h,d) + cr4*gammas(h,d)^2)/(1 + cr5*gammas(h,d) + cr6*gammas(h,d)^2);
gammas_corrected(h,d)=gammas(h,d) + delta_gammas(h,d);
%Air Mass calculation
if (gammas(h,d)<0)
    AMI(h,d)=0;
elseif (gammas(h,d)>pi/2)
    AMI(h,d)=1;
else
    AMI(h,d) = altitude_correction/(sin(gammas_corrected(h,d)) + ma1*(gammas_corrected(h,d)*180/pi + ma2)^ma3);
end
