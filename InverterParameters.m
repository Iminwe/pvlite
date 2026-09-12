function [k0, k1, k2]=InverterParameters(pac, Efficiency)
% 

warning('off','all');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculations
% Schmid model
model = fittype('100*p0/(p0+(k0+k1*p0+k2*p0*p0))','ind','p0','dep','Efficiency');

%Fitted coeficcients
[result, goodnes, output] = fit(pac, Efficiency, model);

%Draw a plot with data and model
plot(result, '-k', pac, Efficiency, 'ko');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate yearly inverter energy efficiencies
coefficients=coeffvalues(result);
k0=coefficients(1);
k1=coefficients(2);
k2=coefficients(3);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
warning('on','all');