%Calculation of parameters F1 and F2 of the Perez model (Solar Energy 44,
%1990), which are called here as K1 and K2, respectively
if (abs(w(h,d))>=abs(ws(d)))
    epsilon(h,d)=0;
    delta(h,d)=0;
    K1(h,d)=0;
    K2(h,d)=0;
else
    %Sky clearness, epsilon
    if (D0(h,d)==0)
        epsilon(h,d)=0;
    else
        %Simplified equation
        %Solar Energy 39, 1987
        epsilon(h,d)=(D0(h,d)+B0(h,d)/costetazs(h,d))/D0(h,d);

        %Equation including dependence with tetazs
        %Solar Energy 44, 1990
        %epsilon(h,d)=((D0(h,d) + B0(h,d)/costetazs(h,d))/D0(h,d) + 1.041*(tetazs(h,d)^3)) / (1 + 1.041*(tetazs(h,d)^3));
    end

    %Sky brightness, delta
    delta(h,d)=D0(h,d)*AMI(h,d)/(1367*Eo(d));

    %Model coefficients
    %Perez et al., Solar energy 44, 1990
    PC=PerezCoefficients90(epsilon(h,d));

    %Circumsolar coefficient
    K1(h,d)=max(0, PC.k31 + PC.k32*delta(h,d) + PC.k33*tetazs(h,d));

    %Horizont brightness coefficient
    K2(h,d)=PC.k41 + PC.k42*delta(h,d) + PC.k43*tetazs(h,d);
end