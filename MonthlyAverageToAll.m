function [DailyValues]=MonthlyAverageToAll(MonthlyAverages)
%This function assignates the monthly average of a given parameter to all
%the days of that month.

%Initial day of each month
MonthInitialDay=[1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];
%Final day of each month
MonthFinalDay=[31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];

%Initialisation
DailyValues=zeros(1,365);

%Assignation of the 12 monthly averages to all the days of that month
for i=1:12
    DailyValues(MonthInitialDay(i):MonthFinalDay(i))=MonthlyAverages(i);
end