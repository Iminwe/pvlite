%Input, reference yield
input=Yr;
Text0='Reference yield';

%Incidence losses (reflection, transmission and dust)
p1=(Ga-Gefa)/1000;
Text1='Incidence';

%Temperature losses
p2=(EPV0a-EPV1a)/PVnom;
if(p2<0)
    p2=-p2;
    Text2='Temperature (<0)';
else
    Text2='Temperature';
end

%DC wiring
p3=(EPV1a-EPV2a)/PVnom;
Text3='DC wiring';

%Inverter saturation
p4=(EPV2a-EPV3a)/PVnom;
Text4='Battery fully charged';

%MKBM Battery losses
if exist('BatteryModel', 'var') && BatteryModel == 2
    p_bat = sum(sum(ELOSS_BAT))/PVnom;
    Text_bat = 'Battery losses';
end

%Inverter efficiency
p5=(EDCa-EAC0a)/PVnom;
Text5='Inverter';

%AC wiring
p6=(EAC0a-EAC1a)/PVnom;
Text6='AC wiring';

%Diagram labels
%Horizontal irradiation
label_irradiation=sprintf('%s\n %s%s\n\n\n', 'Global horizontal yearly irradiation: ', num2str(G0a/1000, '%.1f'), ' [kWh/m2]'); 
%Final label
label_final = sprintf('%s\n%s%s\n %s\n%s%s\n %s\n%s%s\n %s\n%s%s\n', ...
'Final yield', num2str(EACa/PVnom, '%.1f'), ' [kWh/kWp]', ...
'PR', num2str(100*PRa, '%.1f'), ' [%]', ...
'Energy demand', num2str(Edemanda, '%.1f'), ' [kWh]', ...
'LLP', num2str(100*LLPa, '%.1f'), ' [%]', ...
'LLH', num2str(100*LLHa, '%.1f'), ' [%]');

%Draw Sankey diagram.
if exist('BatteryModel', 'var') && BatteryModel == 2
    losses = [p1 p2 p3 p4 p_bat p5 p6]; 
    labels = {Text0, Text1, Text2, Text3, Text4, Text_bat, Text5, Text6, label_final};
else
    losses = [p1 p2 p3 p4 p5 p6]; 
    labels = {Text0, Text1, Text2, Text3, Text4, Text5, Text6, label_final};
end
unit = 'kWh/kWp';
sep = [1,3];
%Additional notes not overlapping the input arrows
[yBottom_sankey] = drawSankey(input, losses, unit, labels, sep);
text(1, yBottom_sankey, label_irradiation, 'FontSize', 12, 'HorizontalAlignment','right', 'VerticalAlignment', 'Top');