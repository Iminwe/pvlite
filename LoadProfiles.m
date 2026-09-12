%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Generation of load profiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Twelve daily consumption profiles for each month.
L12=zeros(24*Stepph, 12);
for k=1:12 %Each column of L12
    for i=1:24
        for j=(Stepph*(i-1)+1):(Stepph*i)
            L12(j, k)=Ldm(k)*F(i);
        end
    end
end

%Initial day of each month
MonthInitialDay=[1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];
%Final day of each month
MonthFinalDay=[31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];

%Instantaneous power consumption
PLOAD=zeros(24*Stepph, 365);

%Assignation of of each monthly profile to all the days of that month
for i=1:12
    for j=MonthInitialDay(i):MonthFinalDay(i)
        PLOAD(:,j)=L12(:,i);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
