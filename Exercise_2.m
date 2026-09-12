%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PVlite: A simulator of PV systems applications.
% Derechos de autor/copyright: Federico Javier Muñoz Cano.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXERCISE_2
% Plot a contour 2D map with the variation of the reference yield
% as a function of the inclination and orientation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Clear workspace
clear;

%Input data
disp('Reading inputs ...')

%Read input parameters from excel sheet;
ReadInputData;
disp('Inputs Ok');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Values for the sweep
sweep1=[20:5:50]; %Inclination, rows
sweep2=[-45:5:45]; %Orientation, columns
%n is the size of the sweep1
[m,n]=size(sweep1);
%n2 is the size of sweep2
[m2,n2]=size(sweep2);

data=zeros(n*n2,3);
Y1=zeros(n, n2);
fila=1;

for q=1:n
    for q2=1:n2
    %Sweep variable
    Inclination=sweep1(q);
    Orientation=sweep2(q2);
    
    %Irradiances
    Irradiances;

    %Reference yield
    Ga=sum(sum(G))/Stepph;
    Yr=Ga/1000;

    %Analysis
    Y1(q,q2)=Yr;

    data(fila, 1)=Orientation;
    data(fila, 2)=Inclination;
    data(fila, 3)=Yr;

    fila=fila+1;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plot 2D map
X=sweep2;
Y=sweep1;
contourf(X, Y, Y1,'ShowText','on');
colormap("bone")
hold on

%Maximum Yr
[Yr_max,index]=max(data(:,3))
%Orientation
Orientation_max=data(index,1)
%Inclination
Inclination_max=data(index,2)
%Plot maximum
plot(Orientation_max, Inclination_max, 'k*')
% Axes labels
xlabel('Orientation [Degree]','Color','k');
ylabel('Inclination [Degree]', 'Color','k')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%