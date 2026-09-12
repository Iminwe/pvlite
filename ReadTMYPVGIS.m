%ReadTMYPVGIS script
%Read the file .csv from PVGIS TMY and generates hourly matrices: 
% Hours
% G0
% B0
% D0
% Ta
%Besides, the script calculates monthly mean averages of G0 and Ta to
%obtain the twelve values of 
% Gdm0, monthly average of daily global irradiation, Wh/m2 
% TMm, monthly average of daily maximum ambient temperatures, ºC
% Tmm, monthly average of daily minimum ambient temperatures, ºC

%Select the file .xls
%Anchor ddbb to this script's location, not the working directory
tmy_script_dir = fileparts(mfilename('fullpath'));
if isempty(tmy_script_dir)
    tmy_script_dir = pwd;    % script body pasted into the Command Window
end
ddbb_dir = fullfile(tmy_script_dir, 'ddbb');
if exist('run_as_test', 'var') && run_as_test
    file_tmypvgis = fullfile(ddbb_dir, 'tmy_40.525_-3.772_2005_2020_Madrid.csv');
else
    [file, path] = uigetfile(fullfile(ddbb_dir, '*.csv'),'Select TMY-PVGIS file');
    if isequal(file,0)
        error('File not selected');
    end
    file_tmypvgis = fullfile(path, file);
end

%Print error if the file is not selected
if isequal(file_tmypvgis,0)
    error('File not selected');
end

%Fail if the meteo file cannot be located
if ~isfile(file_tmypvgis)
    error('PVlite:ReadTMYPVGIS:FileNotFound', 'TMY-PVGIS file not found: %s', file_tmypvgis);
end

%Open the file (read mode)
fid=fopen(file_tmypvgis, 'r');

% %Read first line
% %Latitude
% cell=textscan(fid, '%s %s %s %f', 1);
% Latitude=cell{1,4};
% %Latitude, radians. Internal calculation.
% lat=Latitude*pi/180;
% %Read second line
% cell=textscan(fid, '%s %s %s %f', 1);
% Longitude=cell{1,4};

%Read (and ignore) the first 17 lines
for i=1:17
    readline=fgetl(fid);
end

%Read the next 8760 lines using fscanf()
for i=1:8760
    %Read the line 'i' and save in the data matrix 
    tmy_data(i,:)=fscanf(fid,'%4d%2d%2d:%2d%2d,%f,%f,%f,%f,%f,%f,%f,%f,%f', [1,14]);
end

%Close the file
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Matrices generation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Shift arrays circularly to convert UTC to standard time
%Global irradiance
tmy_data(:,8)=circshift(tmy_data(:,8),TimeZone);
%Diffuse irradiance
tmy_data(:,10)=circshift(tmy_data(:,10),TimeZone);
%Ambient temperature
tmy_data(:,6)=circshift(tmy_data(:,6),TimeZone);
%Wind speed
tmy_data(:,12)=circshift(tmy_data(:,12),TimeZone);
%Generate matrices
for d=1:365
    for h=1:24
        %Hours is the column 4
        Hours_TMY(h,d)=tmy_data(h+(d-1)*24, 4);
        
        %G0 is the column 8
        G0_TMY(h,d)=tmy_data(h+(d-1)*24, 8);
        
        %D0 is the column 10
        D0_TMY(h,d)=tmy_data(h+(d-1)*24, 10);
        
        %B0 is Global less Diffuse
        B0_TMY(h,d)=G0_TMY(h,d)-D0_TMY(h,d);
            
        %Ta is the column 6
        Ta_TMY(h,d)=tmy_data(h+(d-1)*24, 6);

        %Wind is the column 12
        Wind(h,d)=tmy_data(h+(d-1)*24, 12);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculates the 12 monthly averages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Daily horizontal global irradiadiation, monthly mean
DailySum=sum(G0_TMY);
Gdm0(1,1)=sum(DailySum(1,1:31))/31;
Gdm0(1,2)=sum(DailySum(1,32:59))/28;
Gdm0(1,3)=sum(DailySum(1,60:90))/31;
Gdm0(1,4)=sum(DailySum(1,91:120))/30;
Gdm0(1,5)=sum(DailySum(1,121:151))/31;
Gdm0(1,6)=sum(DailySum(1,151:181))/30;
Gdm0(1,7)=sum(DailySum(1,182:212))/31;
Gdm0(1,8)=sum(DailySum(1,213:243))/31;
Gdm0(1,9)=sum(DailySum(1,244:273))/30;
Gdm0(1,10)=sum(DailySum(1,274:304))/31;
Gdm0(1,11)=sum(DailySum(1,305:334))/30;
Gdm0(1,12)=sum(DailySum(1,335:365))/31;

%Daily horizontal global irradiadiation, monthly mean
DailySum=sum(D0_TMY);
Ddm0(1,1)=sum(DailySum(1,1:31))/31;
Ddm0(1,2)=sum(DailySum(1,32:59))/28;
Ddm0(1,3)=sum(DailySum(1,60:90))/31;
Ddm0(1,4)=sum(DailySum(1,91:120))/30;
Ddm0(1,5)=sum(DailySum(1,121:151))/31;
Ddm0(1,6)=sum(DailySum(1,151:181))/30;
Ddm0(1,7)=sum(DailySum(1,182:212))/31;
Ddm0(1,8)=sum(DailySum(1,213:243))/31;
Ddm0(1,9)=sum(DailySum(1,244:273))/30;
Ddm0(1,10)=sum(DailySum(1,274:304))/31;
Ddm0(1,11)=sum(DailySum(1,305:334))/30;
Ddm0(1,12)=sum(DailySum(1,335:365))/31;

%Diffuse fraction
KDdm=Ddm0./Gdm0;

%Daily maximum temperature, monthly mean
DailyMaximum=max(Ta_TMY);
TMm(1,1)=mean(DailyMaximum(1,1:31));
TMm(1,2)=mean(DailyMaximum(1,32:59));
TMm(1,3)=mean(DailyMaximum(1,60:90));
TMm(1,4)=mean(DailyMaximum(1,91:120));
TMm(1,5)=mean(DailyMaximum(1,121:151));
TMm(1,6)=mean(DailyMaximum(1,151:181));
TMm(1,7)=mean(DailyMaximum(1,182:212));
TMm(1,8)=mean(DailyMaximum(1,213:243));
TMm(1,9)=mean(DailyMaximum(1,244:273));
TMm(1,10)=mean(DailyMaximum(1,274:304));
TMm(1,11)=mean(DailyMaximum(1,305:334));
TMm(1,12)=mean(DailyMaximum(1,335:365));

%Daily minimum temperature, monthly mean
DailyMinimum=min(Ta_TMY);
Tmm(1,1)=mean(DailyMinimum(1,1:31));
Tmm(1,2)=mean(DailyMinimum(1,32:59));
Tmm(1,3)=mean(DailyMinimum(1,60:90));
Tmm(1,4)=mean(DailyMinimum(1,91:120));
Tmm(1,5)=mean(DailyMinimum(1,121:151));
Tmm(1,6)=mean(DailyMinimum(1,151:181));
Tmm(1,7)=mean(DailyMinimum(1,182:212));
Tmm(1,8)=mean(DailyMinimum(1,213:243));
Tmm(1,9)=mean(DailyMinimum(1,244:273));
Tmm(1,10)=mean(DailyMinimum(1,274:304));
Tmm(1,11)=mean(DailyMinimum(1,305:334));
Tmm(1,12)=mean(DailyMinimum(1,335:365));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%