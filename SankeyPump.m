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
Text4='Inverter or pump limitation';

%Inverter efficiency
p5=(EDCa-EAC0a)/PVnom;
Text5='Inverter';

%AC wiring
p6=(EAC0a-EAC1a)/PVnom;
Text6='AC wiring';

%Motor
p7=(E1a-E2a)/PVnom;
Text7='Motor';

%Pump
p8=(E2a-EHa)/PVnom;
Text8='Pump';

%Diagram labels
%Horizontal irradiation
label_irradiation=sprintf('%s\n %s%s\n\n\n', 'Global horizontal yearly irradiation: ', num2str(G0a/1000, '%.1f'), ' [kWh/m^2]'); 
%Final label
label_final = sprintf('%s\n  %s%s\n%s\n  %s%s\n%s\n  %s%s\n%s\n  %s%s', ...
'AC energy', num2str(EACa/PVnom, '%.1f'), ' [kWh/kWp]', ... 
'E_H_a', num2str(EHa/PVnom, '%.1f'), ' [kWh/kWp]', ... 
'PRH', num2str(100*PRHa, '%.1f'), ' [%]', ...
'Pumping', num2str(Qa/PVnom, '%.1f'), ' [m^3/kWp]');

%Draw Sankey diagram.
losses = [p1 p2 p3 p4 p5 p6 p7 p8]; 
unit = 'kWh/kWp';
sep = [1,3];
labels = {Text0, Text1, Text2, Text3, Text4, Text5, Text6, Text7, Text8, label_final};
%Additional notes not overlapping the input arrows
[yBottom_sankey] = drawSankey(input, losses, unit, labels, sep);
text(1, yBottom_sankey, label_irradiation, 'FontSize', 12, 'HorizontalAlignment','right', 'VerticalAlignment', 'Top');