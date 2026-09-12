%SunriseAngle, radian
%Initialization to zero
ws=zeros(1,Ndays);
%Calculation
for i=1:Ndays
    %Sunrise angle
    if ((-tan(delta(i))*tan(lat)) > 1)
        ws(i)=0;
    elseif ((-tan(delta(i))*tan(lat)) < (-1))
        ws(i)=-pi;
    else
        ws(i)=-acos(-tan(delta(i))*tan(lat));
    end
end