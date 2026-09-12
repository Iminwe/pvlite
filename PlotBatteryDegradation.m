%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PlotBatteryDegradation.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to visualize battery degradation (SOH, Capacity, Power Fade)
% Run after a pvlite simulation with MKBM active.
% Multi-year (SOH_history filled): whole lifetime in years, replacements marked.
% Otherwise the original single-year view from SOH_mat is used.

if exist('SOH_mat', 'var') && exist('BatParams', 'var')

    % Samples per simulated hour (Stepph = time steps per hour)
    if exist('Stepph', 'var') && ~isempty(Stepph) && Stepph > 0
        samples_per_hour = Stepph;
    else
        samples_per_hour = 1;
    end

    % Detect whether a full multi-year SOH history is available
    multi_year = exist('SOH_history', 'var') && ~isempty(SOH_history) && ...
                 numel(SOH_history) > numel(SOH_mat(:));

    if multi_year
        % ==== MULTI-YEAR BRANCH: whole project lifetime from SOH_history ====
        SOH_all = SOH_history(:);
        t_hours_all = (1:numel(SOH_all))' / samples_per_hour;
        t_years_all = t_hours_all / 8760;

        % Sample indices where each battery unit starts its life
        if exist('bat_segment_starts', 'var') && ~isempty(bat_segment_starts)
            seg_starts = bat_segment_starts(:);
        else
            seg_starts = 1;
        end
        % Filter against out-of-range indices
        seg_starts = seg_starts(seg_starts >= 1 & seg_starts <= numel(SOH_all));
        seg_ends = [seg_starts(2:end) - 1; numel(SOH_all)];

        % Time (years) at which each replacement took place
        if numel(seg_starts) > 1
            % Exact position derived from the segment start indices
            repl_times = (seg_starts(2:end) - 1) / samples_per_hour / 8760;
        elseif exist('replacement_years', 'var') && ~isempty(replacement_years)
            % Fallback: replacements occur at the start of those years
            repl_times = replacement_years(:) - 1;
        else
            repl_times = [];
        end

        % --- FIGURE 1: SOH evolution and degradation breakdown ---
        figure('Name', 'Battery Degradation Analysis', 'Position', [100, 100, 900, 600]);

        % Top subplot: overall SOH over the whole project lifetime
        subplot(2,1,1);
        h_soh = plot(t_years_all, SOH_all * 100, 'LineWidth', 1.2, 'Color', [0 0.4470 0.7410]);
        hold on;
        ylim([min(SOH_all)*100 - 0.5, 100.5]);
        h_repl = [];
        for k = 1:numel(repl_times)
            % Vertical marker at each battery replacement
            h_repl = line([repl_times(k) repl_times(k)], ylim, ...
                          'Color', [0.8 0.2 0.2], 'LineStyle', '--', 'LineWidth', 1.2);
        end
        hold off;
        if ~isempty(h_repl)
            legend([h_soh, h_repl], {'State of Health', 'Battery replacement'}, ...
                   'Location', 'southwest');
        end
        if exist('Project_Lifetime', 'var') && ~isempty(Project_Lifetime) && Project_Lifetime > 1
            title(sprintf('State of Health (SOH) Evolution over %d Years', Project_Lifetime));
        else
            title('State of Health (SOH) Evolution');
        end
        xlabel('Time (Years)');
        ylabel('SOH (%)');
        grid on;
        xlim([0, t_years_all(end)]);

        % Bottom subplot: calendar vs cycling degradation per battery life segment;
        % the calendar counter restarts after each replacement
        subplot(2,1,2);
        calendar_all = zeros(size(SOH_all));
        if isfield(BatParams, 'CalendarFadePerHour') && BatParams.CalendarFadePerHour > 0
            for s = 1:numel(seg_starts)
                idx = seg_starts(s):seg_ends(s);
                local_hours = (1:numel(idx))' / samples_per_hour;
                calendar_all(idx) = local_hours * BatParams.CalendarFadePerHour;
            end
        end
        total_deg_all = 1 - SOH_all;
        cycling_all = max(0, total_deg_all - calendar_all);

        Y = [calendar_all * 100, cycling_all * 100];
        area(t_years_all, Y);
        title('Degradation Breakdown per Battery Life (Calendar vs Cycling)');
        xlabel('Time (Years)');
        ylabel('Capacity Loss (%)');
        legend('Calendar Aging (Time)', 'Cycling Aging (Usage)', 'Location', 'northwest');
        grid on;
        xlim([0, t_years_all(end)]);

        % --- FIGURE 2: Capacity and Power Fade over the project lifetime ---
        figure('Name', 'Capacity and Power Fade', 'Position', [150, 150, 900, 600]);

        % Left axis: Capacity
        yyaxis left
        plot(t_years_all, SOH_all * BatParams.Qmax_initial, 'LineWidth', 1.2);
        ylabel('Maximum Capacity (kWh)');
        ylim([0, BatParams.Qmax_initial * 1.05]);

        % Right axis: Power Limits
        yyaxis right
        plot(t_years_all, SOH_all * BatParams.Pmax_ch_initial, '--', 'LineWidth', 1.2);
        hold on;
        plot(t_years_all, SOH_all * BatParams.Pmax_dis_initial, ':', 'LineWidth', 1.2);
        hold off;
        ylabel('Power Limit (kW)');
        ylim([0, max(BatParams.Pmax_ch_initial, BatParams.Pmax_dis_initial) * 1.05]);

        title('Capacity Fade and Power Fade over Project Lifetime');
        xlabel('Time (Years)');
        legend('Max Capacity (Qmax)', 'Max Charge Power (Pmax\_ch)', 'Max Discharge Power (Pmax\_dis)', 'Location', 'southwest');
        grid on;
        xlim([0, t_years_all(end)]);

    else
        % ==== SINGLE-YEAR BRANCH: original behaviour using SOH_mat ====

        % Create a time vector in hours
        t_hours = (1:length(SOH_mat(:))) / samples_per_hour;

        % Reconstruct the calendar aging component over time
        if isfield(BatParams, 'CalendarFadePerHour') && BatParams.CalendarFadePerHour > 0
            calendar_fade_series = (1:length(t_hours)) * BatParams.CalendarFadePerHour;
        else
            calendar_fade_series = zeros(1, length(t_hours));
        end

        % Reconstruct cycling aging over time; total degradation = 1 - SOH
        total_degradation = 1 - SOH_mat(:)';
        cycling_fade_series = total_degradation - calendar_fade_series;

        % Ensure no negative values due to numerical precision
        cycling_fade_series = max(0, cycling_fade_series);

        % Calculate the relative contribution at the end of the year
        total_deg_end = total_degradation(end);
        if total_deg_end > 0
            cal_pct = (calendar_fade_series(end) / total_deg_end) * 100;
            cyc_pct = (cycling_fade_series(end) / total_deg_end) * 100;
        else
            cal_pct = 0; cyc_pct = 0;
        end

        % --- FIGURE 1: SOH and Degradation Breakdown ---
        figure('Name', 'Battery Degradation Analysis', 'Position', [100, 100, 900, 600]);

        % Top subplot: Overall SOH
        subplot(2,1,1);
        plot(t_hours, SOH_mat(:) * 100, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
        data_years = length(SOH_mat(:)) / samples_per_hour / 8760;
        if data_years > 1.5
            title(sprintf('State of Health (SOH) Evolution over %.1f Years', data_years));
        elseif exist('Project_Lifetime', 'var') && Project_Lifetime > 1
            title(sprintf('State of Health (SOH) - Last Simulated Year (Project Lifetime: %d Years)', Project_Lifetime));
        else
            title('State of Health (SOH) Evolution over 1 Year');
        end
        xlabel('Time (Hours)');
        ylabel('SOH (%)');
        grid on;
        ylim([min(SOH_mat(:))*100 - 0.5, 100.5]);

        % Bottom subplot: Degradation breakdown (Stacked Area)
        subplot(2,1,2);
        % Convert to percentage of degradation
        Y = [calendar_fade_series' * 100, cycling_fade_series' * 100];
        area(t_hours, Y);
        title(sprintf('Degradation Breakdown (End of year: %.1f%% Calendar, %.1f%% Cycling)', cal_pct, cyc_pct));
        xlabel('Time (Hours)');
        ylabel('Capacity Loss (%)');
        legend('Calendar Aging (Time)', 'Cycling Aging (Usage)', 'Location', 'northwest');
        grid on;

        % --- FIGURE 2: Capacity and Power Fade ---
        figure('Name', 'Capacity and Power Fade', 'Position', [150, 150, 900, 600]);

        % Left axis: Capacity
        yyaxis left
        plot(t_hours, SOH_mat(:) * BatParams.Qmax_initial, 'LineWidth', 2);
        ylabel('Maximum Capacity (kWh)');
        ylim([0, BatParams.Qmax_initial * 1.05]);

        % Right axis: Power Limits
        yyaxis right
        plot(t_hours, SOH_mat(:) * BatParams.Pmax_ch_initial, '--', 'LineWidth', 1.5);
        hold on;
        plot(t_hours, SOH_mat(:) * BatParams.Pmax_dis_initial, ':', 'LineWidth', 1.5);
        ylabel('Power Limit (kW)');
        ylim([0, max(BatParams.Pmax_ch_initial, BatParams.Pmax_dis_initial) * 1.05]);

        title('Capacity Fade and Power Fade over Time');
        xlabel('Time (Hours)');
        legend('Max Capacity (Qmax)', 'Max Charge Power (Pmax\_ch)', 'Max Discharge Power (Pmax\_dis)', 'Location', 'southwest');
        grid on;
    end

    fprintf('Plot generation complete.\n');
else
    disp('Error: Required variables (SOH_mat or BatParams) not found in workspace.');
    disp('Please run a simulation with the MKBM model first.');
end
