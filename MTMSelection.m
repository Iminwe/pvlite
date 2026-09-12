function MTMNumber=MTMSelection(MonthlyKT)
%

if MonthlyKT<=0.30
    MTMNumber=1;
elseif MonthlyKT<=0.35
    MTMNumber=2;
elseif MonthlyKT<=0.40
    MTMNumber=3; 
elseif MonthlyKT<=0.45
    MTMNumber=4;  
elseif MonthlyKT<=0.50
    MTMNumber=5;  
elseif MonthlyKT<=0.55
    MTMNumber=6;
elseif MonthlyKT<=0.60
    MTMNumber=7;    
elseif MonthlyKT<=0.65
    MTMNumber=8;
elseif MonthlyKT<=0.70
    MTMNumber=9;
else
    MTMNumber=10;
end