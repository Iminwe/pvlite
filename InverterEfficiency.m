%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function InverterEfficiency()
% This function calculates the coefficients k0, k1 and k2 of the 
% inverter power efficiency model starting from manufacturer efficiency curves.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning('off','all');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input data
%Inverter power efficiency curve from manufacturer datasheet
%Normalised output power
pac=[0; 0.05; 0.1; 0.2; 0.3; 0.5; 1];
%Power efficiency points at each pac value, %
efficiency=[0; 72.4; 83.9; 90.8; 92.7; 94; 93.8];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fitting
model = fittype('100*pac/(pac+(k0+k1*pac+k2*pac*pac))','ind','pac','dep','Efficiency');
%Fitted coeficcients
[result, goodness, output] = fit(pac,efficiency,model);
result
%Draw a plot with data and model
plot(result, '-k', pac, efficiency, 'ko');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate yearly inverter energy efficiencies
coefficients=coeffvalues(result);
k0=coefficients(1);
k1=coefficients(2);
k2=coefficients(3);
% k0=0.005;
% k1=0.025;
% k2=0.08;
pac=0.05; eta5 = 100*pac/(pac+(k0+k1*pac+k2*pac*pac));
pac=0.1; eta10 = 100*pac/(pac+(k0+k1*pac+k2*pac*pac));
pac=0.2; eta20 = 100*pac/(pac+(k0+k1*pac+k2*pac*pac));
pac=0.3; eta30 = 100*pac/(pac+(k0+k1*pac+k2*pac*pac));
pac=0.5; eta50 = 100*pac/(pac+(k0+k1*pac+k2*pac*pac));
pac=0.75; eta75 = 100*pac/(pac+(k0+k1*pac+k2*pac*pac));
pac=1; eta100 = 100*pac/(pac+(k0+k1*pac+k2*pac*pac));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%European Efficiency
eta_eur = 0.03*eta5 + 0.06*eta10 + 0.13*eta20 + 0.1*eta30 + 0.48*eta50 + 0.2*eta100;
disp('European Efficiency')
disp(eta_eur)

%Californian Efficiency
eta_cec = 0.04*eta10 + 0.05*eta20 + 0.12*eta30 + 0.21*eta50 + 0.53*eta75 + 0.05*eta100;
disp('Californian Efficiency')
disp(eta_cec)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
warning('on','all');