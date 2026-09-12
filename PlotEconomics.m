%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PlotEconomics.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Economic charts: CAPEX breakdown and cost projection

if CAPEX > 0
    % Create a figure with two subplots side by side
    f = figure('Name', 'Economic Analysis', 'NumberTitle', 'off', 'Position', [100, 100, 1000, 450]);
    
    % --- Subplot 1: CAPEX Breakdown (Pie Chart) ---
    subplot(1, 2, 1);
    
    % Gather non-zero costs and labels
    costs = [];
    labels = {};
    
    if PV_Total_Cost > 0
        costs(end+1) = PV_Total_Cost;
        labels{end+1} = sprintf('PV Array (%.1f%%)', (PV_Total_Cost/CAPEX)*100);
    end
    if Inverter_Total_Cost > 0
        costs(end+1) = Inverter_Total_Cost;
        labels{end+1} = sprintf('Inverter (%.1f%%)', (Inverter_Total_Cost/CAPEX)*100);
    end
    if Battery_Total_Cost > 0
        costs(end+1) = Battery_Total_Cost;
        labels{end+1} = sprintf('Battery Bank (%.1f%%)', (Battery_Total_Cost/CAPEX)*100);
    end
    if Genset_Total_Cost > 0
        costs(end+1) = Genset_Total_Cost;
        labels{end+1} = sprintf('Genset (%.1f%%)', (Genset_Total_Cost/CAPEX)*100);
    end
    if Wind_Total_Cost > 0
        costs(end+1) = Wind_Total_Cost;
        labels{end+1} = sprintf('Wind Turbine (%.1f%%)', (Wind_Total_Cost/CAPEX)*100);
    end
    if Fixed_Installation_Cost > 0
        costs(end+1) = Fixed_Installation_Cost;
        labels{end+1} = sprintf('Fixed Install (%.1f%%)', (Fixed_Installation_Cost/CAPEX)*100);
    end
    
    if ~isempty(costs)
        % Empty pie labels avoid text overlap on tiny slices
        empty_labels = repmat({''}, 1, length(costs));
        p = pie(costs, empty_labels);
        title('CAPEX Breakdown');
        
        % Improve pie chart aesthetics
        for i = 1:2:length(p)
            p(i).EdgeColor = 'none'; % Remove black edges
        end
        
        % Move labels to a legend outside the pie to prevent overlaps
        legend(labels, 'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 2);
    else
        text(0.5, 0.5, 'No CAPEX data', 'HorizontalAlignment', 'center');
    end
    
    
    % --- Subplot 2: Cumulative Cash Flow / Cost Evolution ---
    subplot(1, 2, 2);
    
    if exist('Project_Lifetime', 'var') && Project_Lifetime > 0
        years = 0:Project_Lifetime;
        
        % Cumulative nominal cost (no discount): year 0 CAPEX, then OPEX
        if ~exist('Annual_Fuel_Cost', 'var'), Annual_Fuel_Cost = 0; end
        cumulative_cost = zeros(1, length(years));
        cumulative_cost(1) = CAPEX;
        for y = 2:length(years)
            cumulative_cost(y) = cumulative_cost(y-1) + OPEX_Annual + Annual_Fuel_Cost;
        end
        
        % Plotting a bar for Year 0 and a line/area for the accumulation
        b = bar(years, cumulative_cost, 'FaceColor', [0.85 0.33 0.1]);
        hold on;
        
        % Highlight year 0 (CAPEX)
        plot(0, CAPEX, 'ko', 'MarkerFaceColor', 'k');
        
        xlabel('Year');
        ylabel('Cumulative Cost (€)');
        title('Cost Evolution over Project Lifetime');
        grid on;
        
        % Set x-axis ticks appropriately
        if Project_Lifetime <= 25
            xticks(0:Project_Lifetime);
        else
            xticks(0:5:Project_Lifetime);
        end
        
        % Horizontal dashed NPC line: discounted equivalent
        if exist('NPC', 'var') && NPC > 0
            yline(NPC, '--k', sprintf('NPC = %.2f €', NPC), 'LabelHorizontalAlignment', 'left');
        end
        
        hold off;
    else
        text(0.5, 0.5, 'Lifetime not defined', 'HorizontalAlignment', 'center');
    end

end
