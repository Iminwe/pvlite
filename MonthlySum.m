function Month=MonthlySum(DailyMatrix)
%This function ...
%

%Lenght of each month
MonthLength=[31,28,31,30,31,30,31,31,30,31,30,31];

%Lengt of the matrix
Ndays=length(DailyMatrix);

%Monthy sums
if (Ndays==365)
    %All the year
    Month(1)=sum(DailyMatrix(1:31));
    Month(2)=sum(DailyMatrix(32:59));
    Month(3)=sum(DailyMatrix(60:90));
    Month(4)=sum(DailyMatrix(91:120));
    Month(5)=sum(DailyMatrix(121:151));
    Month(6)=sum(DailyMatrix(152:181));
    Month(7)=sum(DailyMatrix(182:212));
    Month(8)=sum(DailyMatrix(213:243));
    Month(9)=sum(DailyMatrix(244:273));
    Month(10)=sum(DailyMatrix(274:304));
    Month(11)=sum(DailyMatrix(305:334));
    Month(12)=sum(DailyMatrix(335:365));
elseif (Ndays==12)
    %Only characteristic days
    Month(1)=DailyMatrix(1).*MonthLength(1);
    Month(2)=DailyMatrix(2).*MonthLength(2);
    Month(3)=DailyMatrix(3).*MonthLength(3);
    Month(4)=DailyMatrix(4).*MonthLength(4);
    Month(5)=DailyMatrix(5).*MonthLength(5);
    Month(6)=DailyMatrix(6).*MonthLength(6);
    Month(7)=DailyMatrix(7).*MonthLength(7);
    Month(8)=DailyMatrix(8).*MonthLength(8);
    Month(9)=DailyMatrix(9).*MonthLength(9);
    Month(10)=DailyMatrix(10).*MonthLength(10);
    Month(11)=DailyMatrix(11).*MonthLength(11);
    Month(12)=DailyMatrix(12).*MonthLength(12);
end
