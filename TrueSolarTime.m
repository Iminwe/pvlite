%Script TrueSolarTime

%Matrix initialisation
w=zeros(Nsteps, Ndays);

%Calculations
if(InputData==1 || InputData==2 || InputData==4 ) 
    %Matrix Hours is Solar time
    %True solar time, radian
    w=(Hours-12)*15*pi/180; 

elseif (InputData==3 || InputData==5) 
    %Matrix Hours should be expressed in Standard Time
    %Daily loop
    for d=1:Ndays
        for h=1:Nsteps
            %True solar time, radian
            %TMY3 files, as the recorded hourly data is during the 
            %60-minute period ending at the timestamp, the value is
            %assigned to the midpoint of that period. For this reason,
            %the solar noon is at 12.5h (instead of 12).
            %Optionally, the sun position and the corresponding solar time can be calculated from
            %beam normal irradiance if this data is included in the TMY.
            w(h,d)=(Hours(h,d)-12.5)*15*pi/180 + (Longitude-StandardLongitude)*pi/180 + ET(d);
        end
    end
end