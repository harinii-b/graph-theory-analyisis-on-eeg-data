%% EEG Feature Swarm Plot: Epilepsy vs Non-Epilepsy
% Compares spectral and connectivity features between groups
% Enhanced: Only searches *_processed_bipolar_features folders and tracks skipped files
clear; clc; close all;

%% Configuration
base_folder = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz';
epilepsy_folder = fullfile(base_folder, 'epilepsy');
non_epilepsy_folder = fullfile(base_folder, 'non_epilepsy');

fprintf('=== EEG Feature Analysis: Epilepsy vs Non-Epilepsy ===\n');

%% Find all feature files (only in *_processed_bipolar_features folders)
fprintf('Searching for feature files in *_processed_bipolar_features folders...\n');

% Find all extracted_features.mat files in folders matching pattern
epilepsy_files = dir(fullfile(epilepsy_folder, '**', '*_processed_bipolar_features', 'extracted_features.mat'));
non_epilepsy_files = dir(fullfile(non_epilepsy_folder, '**', '*_processed_bipolar_features', 'extracted_features.mat'));

fprintf('Found %d epilepsy sessions with features\n', length(epilepsy_files));
fprintf('Found %d non-epilepsy sessions with features\n', length(non_epilepsy_files));

if isempty(epilepsy_files) || isempty(non_epilepsy_files)
    error('Need at least one session from each group');
end

%% Initialize tracking structures
epilepsy_data = struct();
non_epilepsy_data = struct();
skipped_sessions = struct('epilepsy', {{}}, 'non_epilepsy', {{}});
loaded_sessions = struct('epilepsy', {{}}, 'non_epilepsy', {{}});

band_names = {'delta', 'theta', 'alpha', 'beta', 'gamma'};

%% Load Epilepsy Data
fprintf('\n=== Loading Epilepsy Features ===\n');
for i = 1:length(epilepsy_files)
    file_path = fullfile(epilepsy_files(i).folder, epilepsy_files(i).name);
    
    % Extract patient and session info from path
    % Path structure: .../patient_id/session_folder/montage/processed_bipolar_features/extracted_features.mat
    path_parts = strsplit(epilepsy_files(i).folder, filesep);
    
    % Get patient ID (3 levels up from features folder)
    patient_id = 'Unknown';
    session_id = 'Unknown';
    if length(path_parts) >= 4
        patient_id = path_parts{end-3};  % patient folder
        session_id = path_parts{end-2};  % session folder
    end
    
    session_name = sprintf('%s/%s', patient_id, session_id);
    
    try
        load(file_path);
        
        % Store band power features (average across channels)
        for b = 1:length(band_names)
            field_name = sprintf('band_power_%s', band_names{b});
            if ~isfield(epilepsy_data, field_name)
                epilepsy_data.(field_name) = [];
            end
            epilepsy_data.(field_name)(end+1) = mean(features.band_power(:, b), 'omitnan');
            
            field_name = sprintf('relative_power_%s', band_names{b});
            if ~isfield(epilepsy_data, field_name)
                epilepsy_data.(field_name) = [];
            end
            epilepsy_data.(field_name)(end+1) = mean(features.relative_power(:, b), 'omitnan');
            
            field_name = sprintf('spectral_entropy_%s', band_names{b});
            if ~isfield(epilepsy_data, field_name)
                epilepsy_data.(field_name) = [];
            end
            epilepsy_data.(field_name)(end+1) = mean(features.spectral_entropy(:, b), 'omitnan');
        end
        
        % Store single-value features (average across channels)
        epilepsy_data.alpha_peak_freq(i) = mean(features.alpha_peak_freq, 'omitnan');
        epilepsy_data.individual_alpha_freq(i) = mean(features.individual_alpha_freq, 'omitnan');
        epilepsy_data.spectral_edge_freq(i) = mean(features.spectral_edge_freq, 'omitnan');
        epilepsy_data.mean_frequency(i) = mean(features.mean_frequency, 'omitnan');
        epilepsy_data.spectral_centroid(i) = mean(features.spectral_centroid, 'omitnan');
        
        loaded_sessions.epilepsy{end+1} = session_name;
        fprintf('  ✓ Loaded: %s\n', session_name);
        
    catch ME
        skipped_sessions.epilepsy{end+1} = struct('session', session_name, ...
            'reason', ME.message, 'file', file_path);
        fprintf('  ✗ SKIPPED: %s\n', session_name);
        fprintf('    Reason: %s\n', ME.message);
    end
end

%% Load Non-Epilepsy Data
fprintf('\n=== Loading Non-Epilepsy Features ===\n');
for i = 1:length(non_epilepsy_files)
    file_path = fullfile(non_epilepsy_files(i).folder, non_epilepsy_files(i).name);
    
    % Extract patient and session info from path
    path_parts = strsplit(non_epilepsy_files(i).folder, filesep);
    
    patient_id = 'Unknown';
    session_id = 'Unknown';
    if length(path_parts) >= 4
        patient_id = path_parts{end-3};
        session_id = path_parts{end-2};
    end
    
    session_name = sprintf('%s/%s', patient_id, session_id);
    
    try
        load(file_path);
        
        % Store band power features (average across channels)
        for b = 1:length(band_names)
            field_name = sprintf('band_power_%s', band_names{b});
            if ~isfield(non_epilepsy_data, field_name)
                non_epilepsy_data.(field_name) = [];
            end
            non_epilepsy_data.(field_name)(end+1) = mean(features.band_power(:, b), 'omitnan');
            
            field_name = sprintf('relative_power_%s', band_names{b});
            if ~isfield(non_epilepsy_data, field_name)
                non_epilepsy_data.(field_name) = [];
            end
            non_epilepsy_data.(field_name)(end+1) = mean(features.relative_power(:, b), 'omitnan');
            
            field_name = sprintf('spectral_entropy_%s', band_names{b});
            if ~isfield(non_epilepsy_data, field_name)
                non_epilepsy_data.(field_name) = [];
            end
            non_epilepsy_data.(field_name)(end+1) = mean(features.spectral_entropy(:, b), 'omitnan');
        end
        
        % Store single-value features (average across channels)
        non_epilepsy_data.alpha_peak_freq(i) = mean(features.alpha_peak_freq, 'omitnan');
        non_epilepsy_data.individual_alpha_freq(i) = mean(features.individual_alpha_freq, 'omitnan');
        non_epilepsy_data.spectral_edge_freq(i) = mean(features.spectral_edge_freq, 'omitnan');
        non_epilepsy_data.mean_frequency(i) = mean(features.mean_frequency, 'omitnan');
        non_epilepsy_data.spectral_centroid(i) = mean(features.spectral_centroid, 'omitnan');
        
        loaded_sessions.non_epilepsy{end+1} = session_name;
        fprintf('  ✓ Loaded: %s\n', session_name);
        
    catch ME
        skipped_sessions.non_epilepsy{end+1} = struct('session', session_name, ...
            'reason', ME.message, 'file', file_path);
        fprintf('  ✗ SKIPPED: %s\n', session_name);
        fprintf('    Reason: %s\n', ME.message);
    end
end

%% Load Connectivity Features
fprintf('\n=== Loading Connectivity Features ===\n');

% Find connectivity files (only in *_processed_bipolar_features folders)
epilepsy_conn_files = dir(fullfile(epilepsy_folder, '**', '*_processed_bipolar_features', 'functional_connectivity.mat'));
non_epilepsy_conn_files = dir(fullfile(non_epilepsy_folder, '**', '*_processed_bipolar_features', 'functional_connectivity.mat'));

fprintf('Found %d epilepsy connectivity files\n', length(epilepsy_conn_files));
fprintf('Found %d non-epilepsy connectivity files\n', length(non_epilepsy_conn_files));

% Load Epilepsy Connectivity
fprintf('\nLoading epilepsy connectivity...\n');
for i = 1:length(epilepsy_conn_files)
    file_path = fullfile(epilepsy_conn_files(i).folder, epilepsy_conn_files(i).name);
    
    % Extract patient and session info
    path_parts = strsplit(epilepsy_conn_files(i).folder, filesep);
    patient_id = 'Unknown';
    session_id = 'Unknown';
    if length(path_parts) >= 4
        patient_id = path_parts{end-3};
        session_id = path_parts{end-2};
    end
    session_name = sprintf('%s/%s', patient_id, session_id);
    
    try
        load(file_path);
        
        % Average connectivity across all channel pairs for each band
        for b = 1:length(band_names)
            % Coherence
            field_name = sprintf('coherence_%s', band_names{b});
            if ~isfield(epilepsy_data, field_name)
                epilepsy_data.(field_name) = [];
            end
            conn_matrix = connectivity.coherence(:, :, b);
            epilepsy_data.(field_name)(end+1) = mean(conn_matrix(~isnan(conn_matrix) & conn_matrix~=0));
            
            % PLV
            field_name = sprintf('plv_%s', band_names{b});
            if ~isfield(epilepsy_data, field_name)
                epilepsy_data.(field_name) = [];
            end
            conn_matrix = connectivity.plv(:, :, b);
            epilepsy_data.(field_name)(end+1) = mean(conn_matrix(~isnan(conn_matrix) & conn_matrix~=0));
            
            % PLI
            field_name = sprintf('pli_%s', band_names{b});
            if ~isfield(epilepsy_data, field_name)
                epilepsy_data.(field_name) = [];
            end
            conn_matrix = connectivity.phase_lag_index(:, :, b);
            epilepsy_data.(field_name)(end+1) = mean(conn_matrix(~isnan(conn_matrix) & conn_matrix~=0));
        end
        
        % Granger causality (overall)
        gc_matrix = connectivity.granger_causality;
        epilepsy_data.granger_causality(i) = mean(gc_matrix(~isnan(gc_matrix) & gc_matrix~=0));
        
        fprintf('  ✓ Loaded connectivity: %s\n', session_name);
        
    catch ME
        fprintf('  ✗ SKIPPED connectivity: %s\n', session_name);
        fprintf('    Reason: %s\n', ME.message);
    end
end

% Load Non-Epilepsy Connectivity
fprintf('\nLoading non-epilepsy connectivity...\n');
for i = 1:length(non_epilepsy_conn_files)
    file_path = fullfile(non_epilepsy_conn_files(i).folder, non_epilepsy_conn_files(i).name);
    
    % Extract patient and session info
    path_parts = strsplit(non_epilepsy_conn_files(i).folder, filesep);
    patient_id = 'Unknown';
    session_id = 'Unknown';
    if length(path_parts) >= 4
        patient_id = path_parts{end-3};
        session_id = path_parts{end-2};
    end
    session_name = sprintf('%s/%s', patient_id, session_id);
    
    try
        load(file_path);
        
        % Average connectivity across all channel pairs for each band
        for b = 1:length(band_names)
            % Coherence
            field_name = sprintf('coherence_%s', band_names{b});
            if ~isfield(non_epilepsy_data, field_name)
                non_epilepsy_data.(field_name) = [];
            end
            conn_matrix = connectivity.coherence(:, :, b);
            non_epilepsy_data.(field_name)(end+1) = mean(conn_matrix(~isnan(conn_matrix) & conn_matrix~=0));
            
            % PLV
            field_name = sprintf('plv_%s', band_names{b});
            if ~isfield(non_epilepsy_data, field_name)
                non_epilepsy_data.(field_name) = [];
            end
            conn_matrix = connectivity.plv(:, :, b);
            non_epilepsy_data.(field_name)(end+1) = mean(conn_matrix(~isnan(conn_matrix) & conn_matrix~=0));
            
            % PLI
            field_name = sprintf('pli_%s', band_names{b});
            if ~isfield(non_epilepsy_data, field_name)
                non_epilepsy_data.(field_name) = [];
            end
            conn_matrix = connectivity.phase_lag_index(:, :, b);
            non_epilepsy_data.(field_name)(end+1) = mean(conn_matrix(~isnan(conn_matrix) & conn_matrix~=0));
        end
        
        % Granger causality (overall)
        gc_matrix = connectivity.granger_causality;
        non_epilepsy_data.granger_causality(i) = mean(gc_matrix(~isnan(gc_matrix) & gc_matrix~=0));
        
        fprintf('  ✓ Loaded connectivity: %s\n', session_name);
        
    catch ME
        fprintf('  ✗ SKIPPED connectivity: %s\n', session_name);
        fprintf('    Reason: %s\n', ME.message);
    end
end

%% Print Summary of Loaded and Skipped Sessions
fprintf('\n========================================\n');
fprintf('LOADING SUMMARY\n');
fprintf('========================================\n');
fprintf('Epilepsy:\n');
fprintf('  ✓ Successfully loaded: %d sessions\n', length(loaded_sessions.epilepsy));
fprintf('  ✗ Skipped: %d sessions\n', length(skipped_sessions.epilepsy));
fprintf('Non-Epilepsy:\n');
fprintf('  ✓ Successfully loaded: %d sessions\n', length(loaded_sessions.non_epilepsy));
fprintf('  ✗ Skipped: %d sessions\n', length(skipped_sessions.non_epilepsy));
fprintf('========================================\n\n');

% Save detailed skip report
skip_report_file = fullfile(base_folder, 'skipped_sessions_report.txt');
fid = fopen(skip_report_file, 'w');
fprintf(fid, '========================================\n');
fprintf(fid, 'SKIPPED SESSIONS REPORT\n');
fprintf(fid, 'Generated: %s\n', datestr(now));
fprintf(fid, '========================================\n\n');

fprintf(fid, 'EPILEPSY GROUP - Skipped Sessions (%d total):\n', length(skipped_sessions.epilepsy));
fprintf(fid, '%s\n', repmat('-', 1, 80));
for i = 1:length(skipped_sessions.epilepsy)
    skip_info = skipped_sessions.epilepsy{i};
    fprintf(fid, '\n%d. Session: %s\n', i, skip_info.session);
    fprintf(fid, '   File: %s\n', skip_info.file);
    fprintf(fid, '   Reason: %s\n', skip_info.reason);
end

fprintf(fid, '\n\nNON-EPILEPSY GROUP - Skipped Sessions (%d total):\n', length(skipped_sessions.non_epilepsy));
fprintf(fid, '%s\n', repmat('-', 1, 80));
for i = 1:length(skipped_sessions.non_epilepsy)
    skip_info = skipped_sessions.non_epilepsy{i};
    fprintf(fid, '\n%d. Session: %s\n', i, skip_info.session);
    fprintf(fid, '   File: %s\n', skip_info.file);
    fprintf(fid, '   Reason: %s\n', skip_info.reason);
end

fclose(fid);
fprintf('📄 Detailed skip report saved: %s\n\n', skip_report_file);

%% Statistical Analysis
fprintf('=== Statistical Analysis (t-test) ===\n');

all_fields = fieldnames(epilepsy_data);
p_values = struct();
effect_sizes = struct();

for f = 1:length(all_fields)
    field = all_fields{f};
    
    if isfield(epilepsy_data, field) && isfield(non_epilepsy_data, field)
        epi_vals = epilepsy_data.(field);
        non_epi_vals = non_epilepsy_data.(field);
        
        % Remove NaN and Inf
        epi_vals = epi_vals(isfinite(epi_vals));
        non_epi_vals = non_epi_vals(isfinite(non_epi_vals));
        
        if length(epi_vals) > 1 && length(non_epi_vals) > 1
            [~, p] = ttest2(epi_vals, non_epi_vals);
            p_values.(field) = p;
            
            % Cohen's d effect size
            pooled_std = sqrt((std(epi_vals)^2 + std(non_epi_vals)^2) / 2);
            if pooled_std > 0
                effect_sizes.(field) = abs(mean(epi_vals) - mean(non_epi_vals)) / pooled_std;
            else
                effect_sizes.(field) = 0;
            end
        end
    end
end

% Sort by p-value
[sorted_p, sort_idx] = sort(struct2array(p_values));
sorted_fields = all_fields(sort_idx);

% Display top 10 most significant features
fprintf('\nTop 10 Most Significant Features:\n');
fprintf('%-30s %12s %12s\n', 'Feature', 'p-value', 'Effect Size');
fprintf('%s\n', repmat('-', 1, 60));
for i = 1:min(10, length(sorted_fields))
    field = sorted_fields{i};
    fprintf('%-30s %12.6f %12.3f', field, p_values.(field), effect_sizes.(field));
    if p_values.(field) < 0.001
        fprintf('  ***\n');
    elseif p_values.(field) < 0.01
        fprintf('  **\n');
    elseif p_values.(field) < 0.05
        fprintf('  *\n');
    else
        fprintf('\n');
    end
end

%% Create Swarm Plots
fprintf('\nGenerating swarm plots...\n');

% Select top significant features for plotting
n_plots = min(12, length(sorted_fields));
top_features = sorted_fields(1:n_plots);

% Create figure with subplots
figure('Position', [50, 50, 1600, 1000]);

for i = 1:n_plots
    field = top_features{i};
    
    epi_vals = epilepsy_data.(field);
    non_epi_vals = non_epilepsy_data.(field);
    
    % Remove NaN and Inf
    epi_vals = epi_vals(isfinite(epi_vals));
    non_epi_vals = non_epi_vals(isfinite(non_epi_vals));
    
    subplot(3, 4, i);
    hold on;
    
    % Create swarm plot manually
    n_epi = length(epi_vals);
    n_non_epi = length(non_epi_vals);
    
    % Add jitter for visualization
    jitter_amount = 0.15;
    x_epi = ones(n_epi, 1) + (rand(n_epi, 1) - 0.5) * jitter_amount;
    x_non_epi = 2 * ones(n_non_epi, 1) + (rand(n_non_epi, 1) - 0.5) * jitter_amount;
    
    % Plot points
    scatter(x_epi, epi_vals, 50, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
    scatter(x_non_epi, non_epi_vals, 50, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    
    % Add mean lines
    plot([0.7, 1.3], [mean(epi_vals), mean(epi_vals)], 'r-', 'LineWidth', 2);
    plot([1.7, 2.3], [mean(non_epi_vals), mean(non_epi_vals)], 'b-', 'LineWidth', 2);
    
    % Formatting
    xlim([0.5, 2.5]);
    set(gca, 'XTick', [1, 2], 'XTickLabel', {'Epilepsy', 'Non-Epilepsy'});
    
    % Clean up feature name for title
    title_str = strrep(field, '_', ' ');
    title_str = [title_str sprintf('\np=%.4f, d=%.2f', p_values.(field), effect_sizes.(field))];
    title(title_str, 'FontSize', 9);
    ylabel('Value');
    grid on;
    
    hold off;
end

sgtitle('Top Significant Features: Epilepsy vs Non-Epilepsy', 'FontSize', 14, 'FontWeight', 'bold');

% Save figure
saveas(gcf, fullfile(base_folder, 'swarm_plot_top_features.png'));
saveas(gcf, fullfile(base_folder, 'swarm_plot_top_features.fig'));

%% Create comprehensive plot for all band power features
figure('Position', [100, 100, 1400, 900]);

subplot_idx = 1;
for b = 1:length(band_names)
    band = band_names{b};
    
    % Band Power
    subplot(3, 5, subplot_idx);
    field = sprintf('band_power_%s', band);
    if isfield(epilepsy_data, field) && isfield(p_values, field)
        epi_vals = epilepsy_data.(field);
        non_epi_vals = non_epilepsy_data.(field);
        epi_vals = epi_vals(isfinite(epi_vals));
        non_epi_vals = non_epi_vals(isfinite(non_epi_vals));
        
        x_epi = ones(length(epi_vals), 1) + (rand(length(epi_vals), 1) - 0.5) * 0.15;
        x_non_epi = 2 * ones(length(non_epi_vals), 1) + (rand(length(non_epi_vals), 1) - 0.5) * 0.15;
        
        hold on;
        scatter(x_epi, epi_vals, 40, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
        scatter(x_non_epi, non_epi_vals, 40, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
        plot([0.7, 1.3], [mean(epi_vals), mean(epi_vals)], 'r-', 'LineWidth', 2);
        plot([1.7, 2.3], [mean(non_epi_vals), mean(non_epi_vals)], 'b-', 'LineWidth', 2);
        xlim([0.5, 2.5]);
        set(gca, 'XTick', [1, 2], 'XTickLabel', {'Epi', 'Non-Epi'});
        title(sprintf('%s Band Power\np=%.4f', band, p_values.(field)), 'FontSize', 9);
        grid on;
    end
    subplot_idx = subplot_idx + 1;
    
    % Relative Power
    subplot(3, 5, subplot_idx);
    field = sprintf('relative_power_%s', band);
    if isfield(epilepsy_data, field) && isfield(p_values, field)
        epi_vals = epilepsy_data.(field);
        non_epi_vals = non_epilepsy_data.(field);
        epi_vals = epi_vals(isfinite(epi_vals));
        non_epi_vals = non_epi_vals(isfinite(non_epi_vals));
        
        x_epi = ones(length(epi_vals), 1) + (rand(length(epi_vals), 1) - 0.5) * 0.15;
        x_non_epi = 2 * ones(length(non_epi_vals), 1) + (rand(length(non_epi_vals), 1) - 0.5) * 0.15;
        
        hold on;
        scatter(x_epi, epi_vals, 40, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
        scatter(x_non_epi, non_epi_vals, 40, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
        plot([0.7, 1.3], [mean(epi_vals), mean(epi_vals)], 'r-', 'LineWidth', 2);
        plot([1.7, 2.3], [mean(non_epi_vals), mean(non_epi_vals)], 'b-', 'LineWidth', 2);
        xlim([0.5, 2.5]);
        set(gca, 'XTick', [1, 2], 'XTickLabel', {'Epi', 'Non-Epi'});
        title(sprintf('%s Rel Power\np=%.4f', band, p_values.(field)), 'FontSize', 9);
        grid on;
    end
    subplot_idx = subplot_idx + 1;
    
    % Spectral Entropy
    subplot(3, 5, subplot_idx);
    field = sprintf('spectral_entropy_%s', band);
    if isfield(epilepsy_data, field) && isfield(p_values, field)
        epi_vals = epilepsy_data.(field);
        non_epi_vals = non_epilepsy_data.(field);
        epi_vals = epi_vals(isfinite(epi_vals));
        non_epi_vals = non_epi_vals(isfinite(non_epi_vals));
        
        x_epi = ones(length(epi_vals), 1) + (rand(length(epi_vals), 1) - 0.5) * 0.15;
        x_non_epi = 2 * ones(length(non_epi_vals), 1) + (rand(length(non_epi_vals), 1) - 0.5) * 0.15;
        
        hold on;
        scatter(x_epi, epi_vals, 40, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
        scatter(x_non_epi, non_epi_vals, 40, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
        plot([0.7, 1.3], [mean(epi_vals), mean(epi_vals)], 'r-', 'LineWidth', 2);
        plot([1.7, 2.3], [mean(non_epi_vals), mean(non_epi_vals)], 'b-', 'LineWidth', 2);
        xlim([0.5, 2.5]);
        set(gca, 'XTick', [1, 2], 'XTickLabel', {'Epi', 'Non-Epi'});
        title(sprintf('%s Entropy\np=%.4f', band, p_values.(field)), 'FontSize', 9);
        grid on;
    end
    subplot_idx = subplot_idx + 1;
end

sgtitle('Band-wise Feature Comparison', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, fullfile(base_folder, 'swarm_plot_bandwise.png'));
saveas(gcf, fullfile(base_folder, 'swarm_plot_bandwise.fig'));

%% Save statistical results (NO WARNING VERSION)
fprintf('Saving statistical results to CSV...\n');

% Pre-allocate vectors to collect valid data (avoids table warning)
valid_features = {};
valid_pvalues = [];
valid_effect_sizes = [];
valid_epi_means = [];
valid_epi_stds = [];
valid_non_epi_means = [];
valid_non_epi_stds = [];

% Collect all valid entries first
for f = 1:length(all_fields)
    field = all_fields{f};
    
    if isfield(p_values, field) && isfield(epilepsy_data, field) && isfield(non_epilepsy_data, field)
        epi_vals = epilepsy_data.(field);
        non_epi_vals = non_epilepsy_data.(field);
        
        % Remove NaN and Inf
        epi_vals = epi_vals(isfinite(epi_vals));
        non_epi_vals = non_epi_vals(isfinite(non_epi_vals));
        
        if ~isempty(epi_vals) && ~isempty(non_epi_vals)
            valid_features{end+1} = field;
            valid_pvalues(end+1) = p_values.(field);
            valid_effect_sizes(end+1) = effect_sizes.(field);
            valid_epi_means(end+1) = mean(epi_vals);
            valid_epi_stds(end+1) = std(epi_vals);
            valid_non_epi_means(end+1) = mean(non_epi_vals);
            valid_non_epi_stds(end+1) = std(non_epi_vals);
        end
    end
end

% Create table in one shot (NO WARNING!)
results_table = table(valid_features', valid_pvalues', valid_effect_sizes', ...
    valid_epi_means', valid_epi_stds', valid_non_epi_means', valid_non_epi_stds', ...
    'VariableNames', {'Feature', 'PValue', 'EffectSize', ...
    'Epilepsy_Mean', 'Epilepsy_Std', 'NonEpilepsy_Mean', 'NonEpilepsy_Std'});

% Sort by p-value
results_table = sortrows(results_table, 'PValue');

% Save to CSV
writetable(results_table, fullfile(base_folder, 'feature_statistics.csv'));

fprintf('\n✅ Analysis complete!\n');
fprintf('========================================\n');
fprintf('📊 Plots saved:\n');
fprintf('   %s\n', fullfile(base_folder, 'swarm_plot_top_features.png'));
fprintf('   %s\n', fullfile(base_folder, 'swarm_plot_bandwise.png'));
fprintf('📄 Statistics saved:\n');
fprintf('   %s\n', fullfile(base_folder, 'feature_statistics.csv'));
fprintf('   %s\n', fullfile(base_folder, 'skipped_sessions_report.txt'));
fprintf('========================================\n');
fprintf('\n🎯 Done!\n');