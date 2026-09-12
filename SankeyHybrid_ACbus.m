%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SankeyHybrid_ACbus.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Sankey diagram for Hybrid AC bus systems

%Input, reference yield
input=[Yr*PVnom EGENa EWINDa];
Text0='PV';
Text01='Genset';
Text02='Wind';

%Incidence losses (reflection, transmission and dust)
p1=((Ga-Gefa)/1000)*PVnom;
Text1='Incidence';

%Temperature losses
p2=(EPV0a-EPV1a);
if(p2<0)
    p2=-p2;
    Text2='Temperature (<0)';
else
    Text2='Temperature';
end

%DC wiring
p3=(EPV1a-EPV2a);
Text3='DC wiring';

%Inverter saturation & curtailment
p4=(EPV2a-EPV3a);
Text4='Battery fully charged';

%MKBM Battery losses
if exist('BatteryModel', 'var') && BatteryModel == 2
    p_bat = sum(sum(ELOSS_BAT));
    Text_bat = 'Battery losses';
else
    p_bat = 0; % Ideal battery
end

%AC wiring
p6=(EAC0a-EAC1a);
Text6='AC wiring';

%Conversion/inversion losses: grid and bidirectional inverters
total_input = Yr*PVnom + EGENa + EWINDa;
p5 = total_input - EAC0a - (p1 + p2 + p3 + p4 + p_bat);
%Avoid negative residual due to precision errors
if p5 < 0
    p5 = 0;
end
Text5='Conversion (Inv/Rect)';

%Diagram labels
%Horizontal irradiation
label_irradiation=sprintf('%s\n %s%s\n\n\n', 'Global horizontal yearly irradiation: ', num2str(G0a/1000, '%.1f'), ' [kWh/m2]'); 
%Final label
label_final = sprintf('%s\n%s%s\n %s\n%s%s\n %s\n%s%s\n %s\n%s%s\n %s\n%s%s\n', ...
'Energy AC', num2str(EACa, '%.1f'), ' [kWh]', ...
'System efficiency', num2str(100*EACa/(Yr*PVnom+EGENa+EWINDa), '%.1f'), ' [%]', ...
'Fuel consumption', num2str(FUELa/1000, '%.1f'), ' [m^3]', ...
'Energy demand', num2str(Edemanda, '%.1f'), ' [kWh]', ...
'LLP', num2str(100*LLPa, '%.1f'), ' [%]', ...
'LLH', num2str(100*LLHa, '%.1f'), ' [%]');

%Draw Sankey diagram.
if exist('BatteryModel', 'var') && BatteryModel == 2
    losses = [p1 p2 p3 p4 p_bat p5 p6]; 
    labels = {Text0, Text01, Text02, Text1, Text2, Text3, Text4, Text_bat, Text5, Text6, label_final};
else
    losses = [p1 p2 p3 p4 p5 p6]; 
    labels = {Text0, Text01, Text02, Text1, Text2, Text3, Text4, Text5, Text6, label_final};
end
unit = 'kWh';
sep = [1,3];
%Additional note below the diagram, centred and clear of the input arrows
[yBottom_sankey, xCenter_sankey] = drawSankey(input, losses, unit, labels, sep);
text(xCenter_sankey, yBottom_sankey, label_irradiation, 'FontSize', 12, 'HorizontalAlignment','center', 'VerticalAlignment', 'Top');