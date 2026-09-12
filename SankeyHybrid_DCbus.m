%Input, reference yield
input=[Yr*PVnom EGENa EWINDa];
Text0='PV';
Text01='Genset';
Text02='Wind';

%Incidence losses (reflection, transmission and dust)
p1=(Ga-Gefa)/1000;
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

%Inverter saturation
p4=(EPV2a-EPV3a);
Text4='Battery fully charged';

%Inverter efficiency
p5=(EDCa-EAC0a);
Text5='Inverter';

%AC wiring
p6=(EAC0a-EAC1a);
Text6='AC wiring';

%Diagram labels
%Horizontal irradiation
label_irradiation=sprintf('%s %s%s\n\n\n', 'Global horizontal yearly irradiation: ', num2str(G0a/1000, '%.1f'), ' [kWh/m2]'); 
%Final label
label_final = sprintf('%s\n%s%s\n %s\n%s%s\n %s\n%s%s\n %s\n%s%s\n %s\n%s%s\n %s\n%s%s\n', ...
'Energy AC', num2str(EACa, '%.1f'), ' [kWh]', ...
'System efficiency', num2str(100*EACa/(Yr*PVnom+EGENa+EWINDa), '%.1f'), ' [%]', ...
'Fuel consumption', num2str(FUELa/1000, '%.1f'), ' [m^3]', ...
'Energy demand', num2str(Edemanda, '%.1f'), ' [kWh]', ...
'LLP', num2str(100*LLPa, '%.1f'), ' [%]', ...
'LLH', num2str(100*LLHa, '%.1f'), ' [%]');

%Draw Sankey diagram.
losses = [p1 p2 p3 p4 p5 p6]; 
unit = 'kWh';
sep = [1,3];
labels = {Text0, Text01, Text02, Text1, Text2, Text3, Text4, Text5, Text6, label_final};
drawSankey(input, losses, unit, labels, sep);
%text(-0.1, 1.1, label_irradiation, 'FontSize', 16, 'HorizontalAlignment','right', 'VerticalAlignment', 'Bottom');
text(1, -0.5, label_irradiation, 'FontSize', 16, 'HorizontalAlignment','right', 'VerticalAlignment', 'Bottom');