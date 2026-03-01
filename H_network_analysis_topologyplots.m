% Publication-Ready Brain Network Visualization - FIXED
% Advanced topographical, network, and connectivity visualizations
% With proper 10-20 electrode positioning
% USES THRESHOLDED MATRIX (matches metric calculations)

clear all; close all; clc;

%% Electrode Positions (10-20 system in 2D projection)
electrode_positions = [
    -0.3, 0.7;   % 1: Fp1
    -0.6, 0.3;   % 2: F7
    -0.7, 0.0;   % 3: T3
    -0.6, -0.4;  % 4: T5
    0.3, 0.7;    % 5: Fp2
    0.6, 0.3;    % 6: F8
    0.7, 0.0;    % 7: T4
    0.6, -0.4;   % 8: T6
    -0.8, 0.0;   % 9: A1
    -0.4, 0.0;   % 10: C3
    0.0, 0.0;    % 11: Cz
    0.4, 0.0;    % 12: C4
    0.8, 0.0;    % 13: A2
    -0.2, 0.5;   % 14: F3
    -0.3, 0.2;   % 15: F3-C3
    -0.4, -0.3;  % 16: P3
    -0.2, -0.6;  % 17: O1
    0.2, 0.5;    % 18: F4
    0.3, 0.2;    % 19: F4-C4
    0.4, -0.3;   % 20: P4
    0.2, -0.6;   % 21: O2
    0.0, 0.3;    % 22: Fz
];

channel_labels = {'Fp1', 'F7', 'T3', 'T5', 'Fp2', 'F8', 'T4', 'T6', ...
                  'A1', 'C3', 'Cz', 'C4', 'A2', 'F3', 'F3C3', 'P3', ...
                  'O1', 'F4', 'F4C4', 'P4', 'O2', 'Fz'};

% Region mapping (1=Frontal, 2=Temporal, 3=Parietal, 4=Occipital)
region_map = [1, 2, 2, 4, 1, 2, 2, 4, 2, 2, 1, 1, 2, 1, 1, 3, 4, 1, 1, 3, 4, 1];

region_names = {'Frontal', 'Temporal', 'Parietal', 'Occipital'};
region_colors = [0.9 0.3 0.3; 0.3 0.6 0.9; 0.3 0.8 0.5; 0.95 0.7 0.3];

%% Configuration
base_weighted_dir = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz\weighted_brain_networks';
output_base = fullfile(base_weighted_dir, 'publication_plots');
if ~exist(output_base, 'dir'), mkdir(output_base); end

% Significant features (p < 0.09)
sig_features = struct();
sig_features.coherence_alpha = {'strength', 'clustering_coeff'};
sig_features.phase_lag_gamma = {'betweenness', 'clustering_coeff', 'communities'};
sig_features.plv_alpha = {'betweenness', 'communities', 'strength', 'std_strength'};
sig_features.plv_beta = {'betweenness', 'strength'};

metric_files = struct();
metric_files.coherence_alpha = 'coherence_alpha_proportional_results';
metric_files.phase_lag_gamma = 'phase_lag_index_gamma_proportional_results';
metric_files.plv_alpha = 'plv_alpha_proportional_results';
metric_files.plv_beta = 'plv_beta_proportional_results';

%% STORAGE FOR GROUP-LEVEL ANALYSIS
% Initialize storage structures for aggregating data across subjects
group_aggregated_data = struct();
group_aggregated_data.epilepsy = struct();
group_aggregated_data.non_epilepsy = struct();

% For each metric and feature combination, store connectivity matrices and node values
metric_types = fieldnames(metric_files);
for m = 1:length(metric_types)
    for f = 1:length(sig_features.(metric_types{m}))
        feat = sig_features.(metric_types{m}){f};
        field_name = [metric_types{m} '_' feat];
        
        group_aggregated_data.epilepsy.(field_name) = struct();
        group_aggregated_data.epilepsy.(field_name).conn_matrices = {};
        group_aggregated_data.epilepsy.(field_name).node_values = {};
        group_aggregated_data.epilepsy.(field_name).subject_ids = {};
        
        group_aggregated_data.non_epilepsy.(field_name) = struct();
        group_aggregated_data.non_epilepsy.(field_name).conn_matrices = {};
        group_aggregated_data.non_epilepsy.(field_name).node_values = {};
        group_aggregated_data.non_epilepsy.(field_name).subject_ids = {};
    end
end

%% Main Processing Loop
groups = {'epilepsy', 'non_epilepsy'};
group_dirs = {fullfile(base_weighted_dir, 'epilepsy'), ...
              fullfile(base_weighted_dir, 'non_epilepsy')};

total_plots = 0;

for g = 1:length(groups)
    fprintf('\n=== Processing %s ===\n', groups{g});
    
    if ~exist(group_dirs{g}, 'dir')
        fprintf('ERROR: Directory does not exist: %s\n', group_dirs{g});
        continue;
    end
    
    patient_folders = dir(group_dirs{g});
    patient_folders = patient_folders([patient_folders.isdir] & ...
        ~ismember({patient_folders.name}, {'.', '..'}));
    
    fprintf('Found %d patient folders in %s\n', length(patient_folders), groups{g});
    
    if isempty(patient_folders)
        fprintf('No patient folders found!\n');
        continue;
    end
    
    for p = 1:max(5, length(patient_folders))
        patient_name = patient_folders(p).name;
        patient_path = fullfile(group_dirs{g}, patient_name);
        
        fprintf('\n  Patient [%d/%d]: %s\n', p, length(patient_folders), patient_name);
        
        session_folders = dir(patient_path);
        session_folders = session_folders([session_folders.isdir] & ...
            ~ismember({session_folders.name}, {'.', '..'}));
        
        fprintf('    Found %d sessions\n', length(session_folders));
        
        if isempty(session_folders)
            fprintf('    No session folders found!\n');
            continue;
        end
        
        for s = 1:length(session_folders)
            session_path = fullfile(patient_path, session_folders(s).name);
            patient_id = [patient_name '_' session_folders(s).name];
            
            fprintf('      Session: %s\n', session_folders(s).name);
            
            output_dir = fullfile(output_base, groups{g}, patient_id);
            if ~exist(output_dir, 'dir'), mkdir(output_dir); end
            
            plots_made = 0;
            
            % Process each metric
            for m = 1:length(metric_types)
                metric_file = fullfile(session_path, ...
                    [metric_files.(metric_types{m}) '.mat']);
                
                if ~exist(metric_file, 'file')
                    fprintf('        Missing: %s\n', metric_files.(metric_types{m}));
                    continue;
                end
                
                fprintf('        Processing: %s\n', metric_types{m});
                
                try
                    data = load(metric_file);
                    if ~isfield(data, 'results')
                        fprintf('          ERROR: No results field\n');
                        continue;
                    end
                    
                    % CRITICAL FIX: Use thresholded matrix, not original
                    % Metrics were calculated on the thresholded network (top 20%)
                    % so we must visualize the same network
                    if isfield(data.results, 'thresholded') && ...
                       isfield(data.results.thresholded, 'matrix')
                        % Use the thresholded matrix (proportional threshold applied)
                        conn = data.results.thresholded.matrix;
                        fprintf('          Using THRESHOLDED matrix (matches metric calculation)\n');
                    elseif isfield(data.results, 'original') && ...
                           isfield(data.results.original, 'matrix')
                        % Fallback to original if thresholded not available
                        conn = data.results.original.matrix;
                        fprintf('          WARNING: Using ORIGINAL matrix (may not match metrics!)\n');
                    else
                        fprintf('          ERROR: No connectivity matrix found\n');
                        continue;
                    end
                    
                    metrics = data.results.metrics;
                    
                    fprintf('          Connectivity matrix size: %dx%d\n', size(conn));
                    
                    % Process significant features
                    for f = 1:length(sig_features.(metric_types{m}))
                        feat = sig_features.(metric_types{m}){f};
                        if ~isfield(metrics, feat)
                            fprintf('            Feature %s not found\n', feat);
                            continue;
                        end
                        
                        node_vals = metrics.(feat);
                        node_vals = node_vals(:);
                        
                        fprintf('            Feature %s size: %d\n', feat, numel(node_vals));
                        
                        if numel(node_vals) ~= 22
                            fprintf('            Skipping %s (not 22x1)\n', feat);
                            continue;
                        end
                        
                        % Weight connectivity
                        weighted_conn = conn;
                        for i = 1:22
                            for j = 1:22
                                if i ~= j && conn(i,j) ~= 0
                                    weighted_conn(i,j) = conn(i,j) * ...
                                        (abs(node_vals(i)) + abs(node_vals(j))) / 2;
                                end
                            end
                        end
                        
                        % STORE DATA FOR GROUP ANALYSIS
                        field_name = [metric_types{m} '_' feat];
                        group_aggregated_data.(groups{g}).(field_name).conn_matrices{end+1} = weighted_conn;
                        group_aggregated_data.(groups{g}).(field_name).node_values{end+1} = node_vals;
                        group_aggregated_data.(groups{g}).(field_name).subject_ids{end+1} = patient_id;
                        
                        base_name = sprintf('%s_%s', metric_types{m}, feat);
                        title_base = sprintf('%s - %s\n%s', ...
                            strrep(metric_types{m}, '_', ' '), ...
                            strrep(feat, '_', ' '), patient_id);
                        
                        % Generate all plot types
                        try
                            plot_topographic_connectivity(weighted_conn, ...
                                electrode_positions, node_vals, title_base, ...
                                fullfile(output_dir, [base_name '_topo.png']), ...
                                region_map, region_colors, channel_labels);
                            
                            plot_circular_network(weighted_conn, node_vals, ...
                                region_map, title_base, ...
                                fullfile(output_dir, [base_name '_network.png']), ...
                                region_colors, channel_labels, region_names);
                            
                            plot_connectivity_matrix_advanced(weighted_conn, ...
                                region_map, title_base, ...
                                fullfile(output_dir, [base_name '_matrix.png']), ...
                                region_names);
                            
                            plot_region_summary(weighted_conn, node_vals, ...
                                region_map, title_base, ...
                                fullfile(output_dir, [base_name '_summary.png']), ...
                                region_colors, region_names);
                            
                            total_plots = total_plots + 4;
                            plots_made = plots_made + 4;
                            fprintf('            ✓ %s: 4 plots saved\n', feat);
                        catch plot_err
                            fprintf('            ✗ Plotting error for %s: %s\n', feat, plot_err.message);
                        end
                    end
                catch ME
                    fprintf('          ✗ Error: %s\n', ME.message);
                end
            end
            
            fprintf('      Total plots for this session: %d\n', plots_made);
        end
    end
end

%% SAVE AGGREGATED DATA FOR GROUP-LEVEL ANALYSIS
save(fullfile(output_base, 'group_aggregated_data.mat'), 'group_aggregated_data', '-v7.3');
fprintf('\n=== Aggregated data saved to: %s ===\n', fullfile(output_base, 'group_aggregated_data.mat'));

%% CREATE GROUP-LEVEL AVERAGE PLOTS
fprintf('\n=== Creating Group-Level Average Plots ===\n');
create_group_average_plots(group_aggregated_data, output_base, electrode_positions, ...
    region_map, region_colors, channel_labels, region_names);

fprintf('\n=== COMPLETE: %d individual plots + group averages generated ===\n', total_plots);

%% Plotting Functions

function plot_topographic_connectivity(conn_matrix, electrode_pos, node_values, title_str, filename, region_map_local, region_colors_local, channel_labels_local)
    % IMPROVED: Better color scaling to show connectivity differences
    fig = figure('Position', [100, 100, 1200, 1000], 'Color', 'w', 'Visible', 'off');
    ax = axes('Parent', fig);
    
    node_values = node_values(:);
    node_values = abs(node_values);
    
    % Normalize node values for sizing
    node_sizes = 200 + 800 * (node_values - min(node_values)) / (max(node_values) - min(node_values) + eps);
    
    % Draw head outline
    theta = linspace(0, 2*pi, 100);
    head_x = 0.85 * cos(theta);
    head_y = 0.85 * sin(theta);
    plot(ax, head_x, head_y, 'k-', 'LineWidth', 2.5); 
    hold(ax, 'on');
    
    % Draw nose
    nose_x = [0, -0.1, 0.1, 0];
    nose_y = [0.85, 1.0, 1.0, 0.85];
    plot(ax, nose_x, nose_y, 'k-', 'LineWidth', 2.5);
    
    % Draw ears
    ear_l = linspace(-pi/4, pi/4, 20);
    plot(ax, -0.85 - 0.1*cos(ear_l), sin(ear_l)*0.15, 'k-', 'LineWidth', 2.5);
    plot(ax, 0.85 + 0.1*cos(ear_l), sin(ear_l)*0.15, 'k-', 'LineWidth', 2.5);
    
    % IMPROVED: Use percentile-based thresholding for better visibility
    conn_flat = abs(conn_matrix(:));
    conn_flat_nonzero = conn_flat(conn_flat > 0);
    if ~isempty(conn_flat_nonzero)
        threshold = prctile(conn_flat_nonzero, 60); % Show top 40%
        max_conn = prctile(conn_flat_nonzero, 95); % Use 95th percentile for scaling
        min_conn = threshold;
    else
        threshold = 0;
        max_conn = 1;
        min_conn = 0;
    end
    
    % Define colormap for connections (blue to red gradient)
    conn_colormap = [
        0.0, 0.3, 0.8;  % Weak: Blue
        0.3, 0.7, 0.9;  % Medium-weak: Light blue
        0.8, 0.8, 0.2;  % Medium: Yellow
        0.9, 0.5, 0.1;  % Medium-strong: Orange
        0.9, 0.1, 0.1;  % Strong: Red
    ];
    
    % Draw connections with improved color coding
    n_nodes = size(conn_matrix, 1);
    for i = 1:n_nodes
        for j = i+1:n_nodes
            if abs(conn_matrix(i,j)) > threshold
                x_line = [electrode_pos(i,1), electrode_pos(j,1)];
                y_line = [electrode_pos(i,2), electrode_pos(j,2)];
                strength = abs(conn_matrix(i,j));
                
                % Normalize strength between 0 and 1
                norm_strength = (strength - min_conn) / (max_conn - min_conn + eps);
                norm_strength = max(0, min(1, norm_strength));
                
                % Get color from colormap
                color_idx = 1 + floor(norm_strength * (size(conn_colormap,1) - 1));
                color_idx = min(color_idx, size(conn_colormap,1));
                line_color = conn_colormap(color_idx, :);
                
                % Alpha and width based on strength
                alpha_val = 0.4 + 0.6 * norm_strength;
                line_width = 0.8 + 3.0 * norm_strength;
                
                plot(ax, x_line, y_line, '-', 'Color', [line_color, alpha_val], ...
                    'LineWidth', line_width);
            end
        end
    end
    
    % Draw electrodes with color-coded regions
    % for i = 1:n_nodes
    %     scatter(ax, electrode_pos(i,1), electrode_pos(i,2), node_sizes(i), ...
    %         region_colors_local(region_map_local(i),:), 'filled', 'MarkerEdgeColor', 'k', ...
    %         'LineWidth', 1.5);
    % end
    for i = 1:n_nodes
    % Draw node
    scatter(ax, electrode_pos(i,1), electrode_pos(i,2), node_sizes(i), ...
        region_colors_local(region_map_local(i),:), 'filled', 'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.5);
    
    % Label: channel name + node value
    text(electrode_pos(i,1), electrode_pos(i,2)+0.05, ...
        sprintf('%s\n%.2f', channel_labels_local{i}, node_values(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end

    axis(ax, 'equal');
    xlim(ax, [-1.2, 1.2]); 
    ylim(ax, [-1.0, 1.2]);
    title(ax, title_str, 'FontSize', 16, 'FontWeight', 'bold');
    
    % Add colorbar for connectivity strength
    colormap(ax, conn_colormap);
    c = colorbar(ax, 'Location', 'eastoutside');
    c.Label.String = 'Connection Strength';
    c.Label.FontSize = 12;
    caxis(ax, [min_conn, max_conn]);
    
    set(ax, 'FontSize', 11);
    axis(ax, 'off');
    
    saveas(fig, filename);
    close(fig);
end

function plot_circular_network(conn_matrix, node_values, region_map_local, title_str, filename, region_colors_local, channel_labels_local, region_names_local)
    % Circular network plot with region grouping
    fig = figure('Position', [100, 100, 1000, 1000], 'Color', 'w', 'Visible', 'off');
    ax = axes('Parent', fig);
    
    n_nodes = size(conn_matrix, 1);
    node_values = abs(node_values(:));
    
    % Circular layout
    angles = linspace(0, 2*pi, n_nodes+1);
    angles = angles(1:end-1);
    radius = 1;
    x = radius * cos(angles);
    y = radius * sin(angles);
    
    % Draw connections (top 20% strongest)
    conn_flat = abs(conn_matrix(:));
    conn_flat_nonzero = conn_flat(conn_flat > 0);
    if ~isempty(conn_flat_nonzero)
        threshold = prctile(conn_flat_nonzero, 80);
        max_conn = max(conn_flat);
    else
        threshold = 0;
        max_conn = 1;
    end
    
    hold(ax, 'on');
    for i = 1:n_nodes
        for j = i+1:n_nodes
            if abs(conn_matrix(i,j)) > threshold
                strength = abs(conn_matrix(i,j));
                alpha_val = 0.2 + 0.6 * (strength / max_conn);
                line_width = 0.3 + 1.5 * (strength / max_conn);
                
                % Color by region connectivity
                if region_map_local(i) == region_map_local(j)
                    color = region_colors_local(region_map_local(i),:);
                else
                    color = [0.5, 0.5, 0.5];
                end
                
                plot(ax, [x(i), x(j)], [y(i), y(j)], '-', ...
                    'Color', [color, alpha_val], 'LineWidth', line_width);
            end
        end
    end
    
    % Draw nodes
    node_sizes = 100 + 500 * (node_values - min(node_values)) / ...
        (max(node_values) - min(node_values) + eps);
    
    for i = 1:n_nodes
        scatter(ax, x(i), y(i), node_sizes(i), region_colors_local(region_map_local(i),:), ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        text(x(i)*1.15, y(i)*1.15, channel_labels_local{i}, ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', ...
            'Parent', ax);
    end
    
    axis(ax, 'equal');
    xlim(ax, [-1.4, 1.4]); 
    ylim(ax, [-1.4, 1.4]);
    title(ax, title_str, 'FontSize', 16, 'FontWeight', 'bold');
    axis(ax, 'off');
    
    % Legend
    legend_handles = gobjects(4, 1);
    for r = 1:4
        legend_handles(r) = scatter(ax, -999, -999, 100, region_colors_local(r,:), ...
            'filled', 'MarkerEdgeColor', 'k');
    end
    legend(legend_handles, region_names_local, 'Location', 'southoutside', ...
        'Orientation', 'horizontal', 'FontSize', 11, 'Box', 'off');
    
    saveas(fig, filename);
    close(fig);
end

function plot_connectivity_matrix_advanced(conn_matrix, region_map_local, title_str, filename, region_names_local)
    % Advanced connectivity matrix with region blocks
    fig = figure('Position', [100, 100, 1000, 900], 'Color', 'w', 'Visible', 'off');
    ax = axes('Parent', fig);
    
    % Sort by regions
    [sorted_regions, sort_idx] = sort(region_map_local);
    sorted_matrix = conn_matrix(sort_idx, sort_idx);
    
    % Plot matrix
    imagesc(ax, abs(sorted_matrix));
    colormap(ax, hot);
    c = colorbar(ax, 'FontSize', 11);
    c.Label.String = 'Connectivity Strength';
    
    % Add region boundaries
    hold(ax, 'on');
    boundaries = [0.5; find(diff(sorted_regions))' + 0.5; length(region_map_local) + 0.5];
    for i = 1:length(boundaries)-1
        plot(ax, [boundaries(i), boundaries(i)], [0.5, length(region_map_local)+0.5], ...
            'w-', 'LineWidth', 2);
        plot(ax, [0.5, length(region_map_local)+0.5], [boundaries(i), boundaries(i)], ...
            'w-', 'LineWidth', 2);
    end
    
    % Labels
    axis(ax, 'square');
    title(ax, title_str, 'FontSize', 16, 'FontWeight', 'bold');
    xlabel(ax, 'Channel (sorted by region)', 'FontSize', 12);
    ylabel(ax, 'Channel (sorted by region)', 'FontSize', 12);
    
    % Add region labels
    region_centers = (boundaries(1:end-1) + boundaries(2:end)) / 2;
    set(ax, 'XTick', region_centers, 'XTickLabel', region_names_local, ...
        'YTick', region_centers, 'YTickLabel', region_names_local, 'FontSize', 11);
    xtickangle(ax, 45);
    
    saveas(fig, filename);
    close(fig);
end

function plot_region_summary(conn_matrix, node_values, region_map_local, title_str, filename, region_colors_local, region_names_local)
    % IMPROVED: Added explanation for node values by region
    fig = figure('Position', [100, 100, 1600, 800], 'Color', 'w', 'Visible', 'off');
    
    node_values = node_values(:);
    
    % Calculate region statistics
    n_regions = 4;
    intra_conn = zeros(n_regions, 1);
    inter_conn = zeros(n_regions, n_regions);
    region_node_vals = cell(n_regions, 1);
    
    for r = 1:n_regions
        region_node_vals{r} = node_values(region_map_local == r);
    end
    
    % Calculate connectivity
    n = size(conn_matrix, 1);
    for i = 1:n
        for j = 1:n
            if i ~= j
                r_i = region_map_local(i);
                r_j = region_map_local(j);
                if r_i == r_j
                    intra_conn(r_i) = intra_conn(r_i) + abs(conn_matrix(i,j));
                else
                    inter_conn(r_i, r_j) = inter_conn(r_i, r_j) + abs(conn_matrix(i,j));
                end
            end
        end
    end
    
    % Subplot 1: Region node values (Distribution of graph metric values per region)
    subplot(2, 3, 1);
    ax1 = gca;
    hold(ax1, 'on');
    for r = 1:n_regions
        vals = region_node_vals{r};
        if ~isempty(vals)
            y_pos = r * ones(size(vals));
            scatter(ax1, vals, y_pos, 80, region_colors_local(r,:), 'filled', 'MarkerFaceAlpha', 0.6);
            % Black bar shows the mean value
            plot(ax1, [mean(vals), mean(vals)], [r-0.3, r+0.3], 'k-', 'LineWidth', 3);
        end
    end
    set(ax1, 'YTick', 1:n_regions, 'YTickLabel', region_names_local, 'FontSize', 11);
    xlabel(ax1, 'Graph Metric Value (e.g., strength, betweenness)', 'FontSize', 11);
    ylabel(ax1, 'Brain Region', 'FontSize', 11);
    title(ax1, {'Node Values by Region', '(dots = individual electrodes, bar = mean)'}, ...
        'FontSize', 12, 'FontWeight', 'bold');
    grid(ax1, 'on');
    ylim(ax1, [0.5, n_regions+0.5]);
    
    % Subplot 2: Intra-region connectivity
    subplot(2, 3, 2);
    ax2 = gca;
    b = bar(ax2, intra_conn, 'FaceColor', 'flat');
    b.CData = region_colors_local;
    set(ax2, 'XTick', 1:n_regions, 'XTickLabel', region_names_local, 'FontSize', 11);
    ylabel(ax2, 'Total Connectivity Strength', 'FontSize', 12);
    title(ax2, 'Intra-region Connectivity', 'FontSize', 13, 'FontWeight', 'bold');
    xtickangle(ax2, 45);
    grid(ax2, 'on');
    
    % Subplot 3: Inter-region heatmap
    subplot(2, 3, 3);
    ax3 = gca;
    imagesc(ax3, inter_conn);
    colormap(ax3, hot);
    c3 = colorbar(ax3, 'FontSize', 10);
    c3.Label.String = 'Strength';
    set(ax3, 'XTick', 1:n_regions, 'XTickLabel', region_names_local, ...
        'YTick', 1:n_regions, 'YTickLabel', region_names_local, 'FontSize', 11);
    title(ax3, 'Inter-region Connectivity', 'FontSize', 13, 'FontWeight', 'bold');
    axis(ax3, 'square');
    xtickangle(ax3, 45);
    
    % Subplot 4-6: Region pair analysis
    for r = 1:3
        subplot(2, 3, 3+r);
        ax_sub = gca;
        region_conn = inter_conn(r, :);
        b = bar(ax_sub, region_conn, 'FaceColor', region_colors_local(r,:));
        set(ax_sub, 'XTick', 1:n_regions, 'XTickLabel', region_names_local, 'FontSize', 10);
        title(ax_sub, [region_names_local{r} ' → Others'], 'FontSize', 12, 'FontWeight', 'bold');
        ylabel(ax_sub, 'Strength', 'FontSize', 11);
        xtickangle(ax_sub, 45);
        grid(ax_sub, 'on');
    end
    
    sgtitle(title_str, 'FontSize', 16, 'FontWeight', 'bold');
    saveas(fig, filename);
    close(fig);
end

function create_group_average_plots(aggregated_data, output_base, electrode_pos, region_map, region_colors, channel_labels, region_names)
    % Create average plots for epilepsy vs non-epilepsy groups
    
    groups = {'epilepsy', 'non_epilepsy'};
    
    for g = 1:length(groups)
        group_name = groups{g};
        group_data = aggregated_data.(group_name);
        
        fprintf('  Creating group averages for %s...\n', group_name);
        
        % Create output directory for group averages
        group_avg_dir = fullfile(output_base, 'group_averages', group_name);
        if ~exist(group_avg_dir, 'dir'), mkdir(group_avg_dir); end
        
        % Process each metric-feature combination
        field_names = fieldnames(group_data);
        
        for f = 1:length(field_names)
            field = field_names{f};
            
            if isempty(group_data.(field).conn_matrices)
                fprintf('    No data for %s\n', field);
                continue;
            end
            
            % Average connectivity matrices across subjects
            n_subjects = length(group_data.(field).conn_matrices);
            conn_sum = zeros(22, 22);
            node_vals_sum = zeros(22, 1);
            
            for s = 1:n_subjects
                conn_sum = conn_sum + group_data.(field).conn_matrices{s};
                node_vals_sum = node_vals_sum + group_data.(field).node_values{s};
            end
            
            avg_conn = conn_sum / n_subjects;
            avg_node_vals = node_vals_sum / n_subjects;
            
            fprintf('    %s: Averaged %d subjects\n', field, n_subjects);
            
            % Create plots with averaged data
            title_base = sprintf('GROUP AVERAGE: %s\n%s (n=%d)', ...
                strrep(field, '_', ' '), upper(group_name), n_subjects);
            
            try
                plot_topographic_connectivity(avg_conn, electrode_pos, avg_node_vals, ...
                    title_base, fullfile(group_avg_dir, [field '_topo_avg.png']), ...
                    region_map, region_colors, channel_labels);
                
                plot_circular_network(avg_conn, avg_node_vals, region_map, title_base, ...
                    fullfile(group_avg_dir, [field '_network_avg.png']), ...
                    region_colors, channel_labels, region_names);
                
                plot_connectivity_matrix_advanced(avg_conn, region_map, title_base, ...
                    fullfile(group_avg_dir, [field '_matrix_avg.png']), region_names);
                
                plot_region_summary(avg_conn, avg_node_vals, region_map, title_base, ...
                    fullfile(group_avg_dir, [field '_summary_avg.png']), ...
                    region_colors, region_names);
                
                fprintf('      ✓ Created 4 group average plots\n');
            catch ME
                fprintf('      ✗ Error creating plots: %s\n', ME.message);
            end
        end
    end
    
    fprintf('\n=== Group average plots completed ===\n');
end