function MonthlyMean=MonthlyAverage(DailyMatrix)
%This function ...
%
MonthlyMean(1)=mean(DailyMatrix(1:31));
MonthlyMean(2)=mean(DailyMatrix(32:59));
MonthlyMean(3)=mean(DailyMatrix(60:90));
MonthlyMean(4)=mean(DailyMatrix(91:120));
MonthlyMean(5)=mean(DailyMatrix(121:151));
MonthlyMean(6)=mean(DailyMatrix(152:181));
MonthlyMean(7)=mean(DailyMatrix(182:212));
MonthlyMean(8)=mean(DailyMatrix(213:243));
MonthlyMean(9)=mean(DailyMatrix(244:273));
MonthlyMean(10)=mean(DailyMatrix(274:304));
MonthlyMean(11)=mean(DailyMatrix(305:334));
MonthlyMean(12)=mean(DailyMatrix(335:365));

