%Generation of the matrix Hours
%Initialization to zero
Hours=zeros(Nsteps, Ndays);
%Hourly step, hours
Step=24/Nsteps;
%Hourly row vector
RowVector=Step:Step:24;
%Hourly column vector
ColVector=RowVector';
%Creates the matrix hours with all the columns equal to the previous one
for i=1:Ndays
    Hours(:,i)=ColVector;
end
