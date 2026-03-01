%% Topographic Mapping of Gamma Features (Relative Power & Spectral Entropy)
% This script creates topographic maps for individual patients and group averages
% Recursively searches for *_bipolar_features folders containing extracted_features.mat

clear; clc; close all;

%% Configuration
base_path = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz';
output_dir = fullfile(base_path, 'topographic_maps');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Electrode positions (x, y coordinates)
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

num_channels = size(electrode_positions, 1);

%% Initialize storage for group averages
epilepsy_rel_power_all = [];
epilepsy_entropy_all = [];
control_rel_power_all = [];
control_entropy_all = [];

epilepsy_patient_count = 0;
control_patient_count = 0;

%% Process both groups
groups = {'epilepsy', 'non_epilepsy'};

for g = 1:length(groups)
    group_name = groups{g};
    group_path = fullfile(base_path, group_name);
    
    fprintf('\n=== Processing %s group ===\n', upper(group_name));
    
    % Get all patient folders
    patient_folders = dir(group_path);
    patient_folders = patient_folders([patient_folders.isdir] & ~ismember({patient_folders.name}, {'.', '..'}));
    
    for p = 1:length(patient_folders)
        patient_id = patient_folders(p).name;
        patient_path = fullfile(group_path, patient_id);
        
        fprintf('\nProcessing patient: %s\n', patient_id);
        
        % Recursively search for *_bipolar_features folders
        bipolar_folders = find_bipolar_feature_folders(patient_path);
        
        if isempty(bipolar_folders)
            fprintf('  No bipolar_features folders found for patient %s\n', patient_id);
            continue;
        end
        
        % Process each bipolar_features folder found
        for b = 1:length(bipolar_folders)
            bipolar_path = bipolar_folders{b};
            
            % Look for extracted_features.mat
            feature_file = fullfile(bipolar_path, 'extracted_features.mat');
            
            if ~exist(feature_file, 'file')
                fprintf('  Skipping %s - no extracted_features.mat found\n', bipolar_path);
                continue;
            end
            
            fprintf('  Loading: %s\n', feature_file);
            
            try
                data = load(feature_file);
                
                % Extract gamma features
                [rel_power_gamma, entropy_gamma] = extract_gamma_features(data);
                
                if isempty(rel_power_gamma) || isempty(entropy_gamma)
                    fprintf('    Warning: Could not extract gamma features\n');
                    continue;
                end
                
                % Create patient label from path
                [~, parent_folder] = fileparts(fileparts(bipolar_path));
                patient_label = sprintf('%s_%s_%s', group_name, patient_id, parent_folder);
                
                % Create individual patient topographic maps
                create_topographic_maps(rel_power_gamma, entropy_gamma, ...
                    electrode_positions, channel_labels, patient_label, output_dir);
                
                % Accumulate for group averages
                if strcmp(group_name, 'epilepsy')
                    epilepsy_rel_power_all = [epilepsy_rel_power_all; rel_power_gamma];
                    epilepsy_entropy_all = [epilepsy_entropy_all; entropy_gamma];
                    epilepsy_patient_count = epilepsy_patient_count + 1;
                else
                    control_rel_power_all = [control_rel_power_all; rel_power_gamma];
                    control_entropy_all = [control_entropy_all; entropy_gamma];
                    control_patient_count = control_patient_count + 1;
                end
                
                fprintf('    Saved topographic map\n');
                
            catch ME
                fprintf('    Error processing file: %s\n', ME.message);
            end
        end
    end
end

%% Create Group Average Topographic Maps
fprintf('\n=== Creating Group Average Maps ===\n');

if epilepsy_patient_count > 0
    fprintf('Epilepsy patients processed: %d\n', epilepsy_patient_count);
    epilepsy_rel_power_avg = mean(epilepsy_rel_power_all, 1);
    epilepsy_entropy_avg = mean(epilepsy_entropy_all, 1);
    
    create_topographic_maps(epilepsy_rel_power_avg, epilepsy_entropy_avg, ...
        electrode_positions, channel_labels, 'GROUP_EPILEPSY', output_dir);
end

if control_patient_count > 0
    fprintf('Control patients processed: %d\n', control_patient_count);
    control_rel_power_avg = mean(control_rel_power_all, 1);
    control_entropy_avg = mean(control_entropy_all, 1);
    
    create_topographic_maps(control_rel_power_avg, control_entropy_avg, ...
        electrode_positions, channel_labels, 'GROUP_CONTROL', output_dir);
end

%% Create Comparison Plots (Epilepsy vs Control)
if epilepsy_patient_count > 0 && control_patient_count > 0
    fprintf('\n=== Creating Comparison Plots (Epilepsy vs Control) ===\n');
    
    % Create side-by-side comparison for Relative Power
    create_comparison_plot(epilepsy_rel_power_avg, control_rel_power_avg, ...
        electrode_positions, channel_labels, 'Gamma Relative Power', ...
        'Relative_Power_Comparison', output_dir);
    
    % Create side-by-side comparison for Spectral Entropy
    create_comparison_plot(epilepsy_entropy_avg, control_entropy_avg, ...
        electrode_positions, channel_labels, 'Gamma Spectral Entropy', ...
        'Spectral_Entropy_Comparison', output_dir);
    
    fprintf('    Saved comparison plots\n');
    
    % % Create difference maps (Epilepsy - Control)
    % diff_rel_power = epilepsy_rel_power_avg - control_rel_power_avg;
    % diff_entropy = epilepsy_entropy_avg - control_entropy_avg;

    % Create difference maps (Control - Epilepsy)
    diff_rel_power = control_rel_power_avg - epilepsy_rel_power_avg;
    diff_entropy = control_entropy_avg - epilepsy_entropy_avg;
    create_difference_plot(diff_rel_power, diff_entropy, ...
        electrode_positions, channel_labels, 'Difference_Maps', output_dir);
    
    fprintf('    Saved difference maps\n');
end

fprintf('\n=== Processing Complete ===\n');
fprintf('Output saved to: %s\n', output_dir);

%% Helper Functions

function bipolar_folders = find_bipolar_feature_folders(root_path)
    % Recursively search for folders ending with _bipolar_features
    
    bipolar_folders = {};
    
    % Get all items in current directory
    items = dir(root_path);
    items = items(~ismember({items.name}, {'.', '..'}));
    
    for i = 1:length(items)
        item_path = fullfile(root_path, items(i).name);
        
        if items(i).isdir
            % Check if this folder name ends with _bipolar_features
            if endsWith(items(i).name, '_bipolar_features')
                bipolar_folders{end+1} = item_path;
            else
                % Recursively search subdirectories
                sub_folders = find_bipolar_feature_folders(item_path);
                bipolar_folders = [bipolar_folders, sub_folders];
            end
        end
    end
end

function [rel_power_gamma, entropy_gamma] = extract_gamma_features(data)
    % Extract gamma band (30-100 Hz) relative power and spectral entropy
    % Data is stored as 22x5 where columns are bands and gamma is index 5
    
    rel_power_gamma = [];
    entropy_gamma = [];
    
    % Check if features structure exists
    if ~isfield(data, 'features')
        return;
    end
    
    features = data.features;
    
    % Gamma is the 5th band (index 5)
    gamma_idx = 5;
    
    % Extract relative power for gamma band
    if isfield(features, 'relative_power')
        rel_power_data = features.relative_power;
        if size(rel_power_data, 2) >= gamma_idx
            rel_power_gamma = rel_power_data(:, gamma_idx)'; % Extract gamma column and transpose to row
        end
    end
    
    % Extract spectral entropy for gamma band
    if isfield(features, 'spectral_entropy')
        entropy_data = features.spectral_entropy;
        if size(entropy_data, 2) >= gamma_idx
            entropy_gamma = entropy_data(:, gamma_idx)'; % Extract gamma column and transpose to row
        end
    end
    
    % Verify we have 22 channels
    if ~isempty(rel_power_gamma) && length(rel_power_gamma) ~= 22
        fprintf('    Warning: Expected 22 channels for relative_power, got %d\n', length(rel_power_gamma));
    end
    
    if ~isempty(entropy_gamma) && length(entropy_gamma) ~= 22
        fprintf('    Warning: Expected 22 channels for spectral_entropy, got %d\n', length(entropy_gamma));
    end
end

function create_topographic_maps(rel_power, entropy, electrode_pos, channel_labels, label, output_dir)
    % Create and save topographic maps for relative power and entropy
    
    fig = figure('Position', [100, 100, 1400, 600], 'Visible', 'off');
    
    % Plot 1: Relative Power Gamma
    subplot(1, 2, 1);
    plot_topomap(rel_power, electrode_pos, channel_labels);
    title(sprintf('Gamma Relative Power - %s', strrep(label, '_', ' ')), 'FontSize', 12, 'FontWeight', 'bold');
    colorbar;
    
    % Plot 2: Spectral Entropy Gamma
    subplot(1, 2, 2);
    plot_topomap(entropy, electrode_pos, channel_labels);
    title(sprintf('Gamma Spectral Entropy - %s', strrep(label, '_', ' ')), 'FontSize', 12, 'FontWeight', 'bold');
    colorbar;
    
    % Save figure
    sgtitle(sprintf('Topographic Maps: %s', strrep(label, '_', ' ')), 'FontSize', 14, 'FontWeight', 'bold');
    
    filename = fullfile(output_dir, sprintf('topomap_%s.png', label));
    saveas(fig, filename);
    
    close(fig);
end

function create_comparison_plot(epilepsy_values, control_values, electrode_pos, channel_labels, feature_name, filename_base, output_dir)
    % Create side-by-side comparison plot for epilepsy vs control
    
    fig = figure('Position', [100, 100, 1600, 600], 'Visible', 'off');
    
    % Find common color scale for both plots
    all_values = [epilepsy_values, control_values];
    cmin = min(all_values);
    cmax = max(all_values);
    
    % Plot 1: Epilepsy
    subplot(1, 2, 1);
    plot_topomap(epilepsy_values, electrode_pos, channel_labels);
    title(sprintf('Epilepsy - %s', feature_name), 'FontSize', 14, 'FontWeight', 'bold');
    colorbar;
    caxis([cmin, cmax]);
    
    % Plot 2: Control
    subplot(1, 2, 2);
    plot_topomap(control_values, electrode_pos, channel_labels);
    title(sprintf('Control - %s', feature_name), 'FontSize', 14, 'FontWeight', 'bold');
    colorbar;
    caxis([cmin, cmax]);
    
    % Overall title
    sgtitle(sprintf('Comparison: %s (Epilepsy vs Control)', feature_name), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    % Save figure
    filename = fullfile(output_dir, sprintf('%s.png', filename_base));
    saveas(fig, filename);
    
    close(fig);
end

function create_difference_plot(diff_rel_power, diff_entropy, electrode_pos, channel_labels, filename_base, output_dir)
    % Create difference maps showing (Epilepsy - Control)
    
    fig = figure('Position', [100, 100, 1400, 600], 'Visible', 'off');
    
    % Plot 1: Relative Power Difference
    subplot(1, 2, 1);
    plot_topomap(diff_rel_power, electrode_pos, channel_labels);
    title('Gamma Relative Power Difference (Epilepsy - Control)', 'FontSize', 12, 'FontWeight', 'bold');
    colorbar;
    colormap(subplot(1,2,1), redblue(256)); % Use diverging colormap
    
    % Plot 2: Spectral Entropy Difference
    subplot(1, 2, 2);
    plot_topomap(diff_entropy, electrode_pos, channel_labels);
    title('Gamma Spectral Entropy Difference (Epilepsy - Control)', 'FontSize', 12, 'FontWeight', 'bold');
    colorbar;
    colormap(subplot(1,2,2), redblue(256)); % Use diverging colormap
    
    % Overall title
    sgtitle('Difference Maps: Epilepsy minus Control', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Save figure
    filename = fullfile(output_dir, sprintf('%s.png', filename_base));
    saveas(fig, filename);
    
    close(fig);
end

function cmap = redblue(n)
    % Create red-white-blue diverging colormap
    % Red = positive (epilepsy > control)
    % Blue = negative (epilepsy < control)
    
    if nargin < 1
        n = 256;
    end
    
    half = ceil(n/2);
    
    % Blue to white
    r1 = linspace(0, 1, half)';
    g1 = linspace(0, 1, half)';
    b1 = ones(half, 1);
    
    % White to red
    r2 = ones(n-half, 1);
    g2 = linspace(1, 0, n-half)';
    b2 = linspace(1, 0, n-half)';
    
    cmap = [r1, g1, b1; r2, g2, b2];
end

function plot_topomap(values, electrode_pos, channel_labels)
    % Plot topographic map with interpolation
    
    % Create interpolation grid
    grid_res = 100;
    xi = linspace(-1, 1, grid_res);
    yi = linspace(-1, 1, grid_res);
    [Xi, Yi] = meshgrid(xi, yi);
    
    % Interpolate values
    F = scatteredInterpolant(electrode_pos(:,1), electrode_pos(:,2), values(:), 'natural', 'none');
    Zi = F(Xi, Yi);
    
    % Create circular mask (head boundary)
    mask = sqrt(Xi.^2 + Yi.^2) <= 1;
    Zi(~mask) = NaN;
    
    % Plot interpolated surface
    contourf(Xi, Yi, Zi, 20, 'LineColor', 'none');
    hold on;
    
    % Draw head outline
    theta = linspace(0, 2*pi, 100);
    plot(cos(theta), sin(theta), 'k', 'LineWidth', 2);
    
    % Draw nose
    nose_x = [0, -0.15, 0.15, 0];
    nose_y = [1, 1.15, 1.15, 1];
    plot(nose_x, nose_y, 'k', 'LineWidth', 2);
    
    % Draw ears
    ear_theta = linspace(-pi/4, pi/4, 20);
    % Left ear
    plot(-1 + 0.08*cos(ear_theta), 0.08*sin(ear_theta), 'k', 'LineWidth', 2);
    % Right ear
    plot(1 - 0.08*cos(ear_theta), 0.08*sin(ear_theta), 'k', 'LineWidth', 2);
    
    % Plot electrode positions
    scatter(electrode_pos(:,1), electrode_pos(:,2), 50, 'k', 'filled');
    
    % Add electrode labels
    for i = 1:length(channel_labels)
        text(electrode_pos(i,1), electrode_pos(i,2), channel_labels{i}, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 8, 'FontWeight', 'bold', 'Color', 'white', ...
            'BackgroundColor', 'black', 'EdgeColor', 'white', 'Margin', 1);
    end
    
    % Add region labels
    % Frontal region (top)
    text(0, 0.85, 'FRONTAL', 'HorizontalAlignment', 'center', ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', 'black', ...
        'BackgroundColor', [1 1 1 0.7], 'EdgeColor', 'black', 'LineWidth', 1.5);
    
    % Temporal regions (sides)
    text(-0.85, 0, 'TEMPORAL', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black', 'Rotation', 90, ...
        'BackgroundColor', [1 1 1 0.7], 'EdgeColor', 'black', 'LineWidth', 1.5);
    text(0.85, 0, 'TEMPORAL', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black', 'Rotation', -90, ...
        'BackgroundColor', [1 1 1 0.7], 'EdgeColor', 'black', 'LineWidth', 1.5);
    
    % Central region (middle)
    text(0, 0.15, 'CENTRAL', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black', ...
        'BackgroundColor', [1 1 1 0.7], 'EdgeColor', 'black', 'LineWidth', 1.5);
    
    % Parietal region (middle-back)
    text(0, -0.35, 'PARIETAL', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black', ...
        'BackgroundColor', [1 1 1 0.7], 'EdgeColor', 'black', 'LineWidth', 1.5);
    
    % Occipital region (bottom)
    text(0, -0.75, 'OCCIPITAL', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black', ...
        'BackgroundColor', [1 1 1 0.7], 'EdgeColor', 'black', 'LineWidth', 1.5);
    
    axis equal;
    axis off;
    xlim([-1.2, 1.2]);
    ylim([-1.2, 1.3]);
    
    colormap(jet);
    hold off;
end