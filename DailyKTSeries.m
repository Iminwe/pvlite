function KTd=DailyKTSeries(KTm)
%
%Input: 12 values of the monthly average daily KTm
%Ouput: 365 values of the daily clearness index, KTd

disp('Generating synthetic daily clearness indices ...');

%Deviation, per value
%Maximum allowed deviation between the monthly mean of the generated KTd
%and the KTm
deviation=0.01;

%Initial day of each month
MonthInitialDay=[1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];

%Final day of each month
MonthFinalDay=[31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];

%Get the Aguiar Markov Transition Matrices (MTM)
%MTM is three-dimensional array being the last index the number of the
%MTM, which varies from 1 to 10.
MTM=MarkovTransitionMatrices();

%Maximum and minimum value of KT for each MTM
KTminimum=[.031 .058 .051 .052 .028 .053 .044 .085 .010 .319];
KTmaximum=[.705 .694 .753 .753 .807 .856 .818 .846 .842 .865];

%Initialisation of KTd
KTd=zeros(1,365);

%Monthly loop, m is the month
for m=1:12
    %Select the MTM according to the monthly KT
    MTMNumber=MTMSelection(KTm(m));
    
    %KTmin and KTmax of the selected MTM
    KTmin=KTminimum(MTMNumber);
    KTmax=KTmaximum(MTMNumber);
    
    %Previous KT
    if(m==1)
        %For January, it is the mean of December
        KTprev=KTm(12);
    else
        %For the rest of months, it is the KT of the last day of the
        %previous calculated month
        KTprev=KTd(MonthFinalDay(m-1));
    end
    
    %Initial and final day of the current month 
    InitialDay=MonthInitialDay(m);
    FinalDay=MonthFinalDay(m);
    
    %Iterations to prevent an infinite loop
    iterations=0;
    while(1)
        %Daily loop in each month
        for d=InitialDay:FinalDay

            %Interval number of previous KT (1 to 10) between KTmin and KTmax, 
            %which is the number of the MTM row
            if (KTprev<KTmin)
                LastInterval=1;
            elseif (KTprev>KTmax)
                LastInterval=10;
            else
                %Round towards the upper integer 
                LastInterval=ceil(10*(KTprev-KTmin)/(KTmax-KTmin));
            end

            %Generates a random number R
            %It is limited to a maximum of 0.995 because there is one row
            %of an MTM matrix whose sum is 0.997, and the algorithm of the
            %next loop only stops if R is lower than any row sum.
            R=min(rand(),0.995);
            
            %Initialisation of colum variables
            %Sum of the columns
            ColumnSum=0;
            %First column
            ColumnNumber=1;

            %Sum the colums corresponding to the row LastInterval until
            %exceeding the value of R
            while(ColumnSum<R)    
                ColumnSum = ColumnSum + MTM(LastInterval, ColumnNumber, MTMNumber);
                ColumnNumber = min(ColumnNumber+1,10);
            end

            %New interval of KT
            NewInterval=ColumnNumber-1;

            %Calculated KT for this day, which is in the center of the new
            %interval of KT
            KTd(d)=(NewInterval-0.5)*(KTmax-KTmin)/10 + KTmin;

            %Updates the KTprev with the calculated KT
            KTprev=KTd(d);
        end %Internal for
        
        %Valor medio de la serie mensual generada
        KTmean(m)=mean(KTd(InitialDay:FinalDay));
        
        %Diferencia
        delta=abs(KTmean(m)-KTm(m));

        iterations=iterations+1;
        
        %Stop the program if the number of iteration exceeds one hundred
        if(iterations>100)
            error('More than hundred iterations in DailyKTSeries function');
        end
        
        %Checks the required precision and break the loop if it is achieved
        if(delta<deviation)
            break;
        end
    
    end %While loop
    
end %External for
