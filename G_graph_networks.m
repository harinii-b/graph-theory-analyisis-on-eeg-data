% Enhanced Weighted Brain Network Analysis for EEG Connectivity Data
% Single-threshold method approach for PLV and Coherence matrices
% References: 
% - Rubinov & Sporns (2010) - Complex network measures
% - van Wijk et al. (2010) - Comparing brain networks
% - Garrison et al. (2015) - Network thresholding
% - Jalili (2016) - Graph theory analysis of EEG

clear; clc;

%% ==================== CONFIGURATION ====================
base_path = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz';
groups = {'epilepsy', 'non_epilepsy'};

% Define networks to analyze
networks_config = {
    'plv_alpha', 'plv', 'alpha', 3;
    'plv_beta', 'plv', 'beta', 4;
    'phase_lag_index_gamma', 'phase_lag_index', 'gamma', 5;
    'coherence_alpha', 'coherence', 'alpha', 3
};

band_names = {'delta', 'theta', 'alpha', 'beta', 'gamma'};

% ============ ANALYSIS CONFIGURATION ============
% Choose ONE thresholding method (recommended for your analysis)
config = struct();
config.threshold_method = 'proportional';  % OPTIONS: 'proportional', 'absolute', 'mst_plus'

% Set threshold range based on chosen method
switch config.threshold_method
    case 'proportional'
        % Keep top X% of connections (most common for EEG)
        config.threshold_range = [0.20];  % 10-30% density
        config.threshold_label = 'Network Density (%)';
        
    case 'absolute'
        % Fixed cutoff values (for PLV/coherence)
        config.threshold_range = [0.30, 0.35, 0.40, 0.45, 0.50];
        config.threshold_label = 'Connection Strength Threshold';
        
    case 'mst_plus'
        % MST + additional % of connections
        config.threshold_range = [0.05, 0.10, 0.15, 0.20, 0.25];
        config.threshold_label = 'Additional Connections (%)';
end

% Visualization options
config.save_individual_plots = false;  % Set to true only if you need per-patient plots
config.save_group_plots = true;        % Always keep this true
config.verbose = true;                 % Print progress

% Output directory
output_base = fullfile(base_path, 'weighted_brain_networks');
if ~exist(output_base, 'dir'), mkdir(output_base); end

%% ==================== MAIN ANALYSIS ====================
fprintf('Enhanced Weighted EEG Network Analysis\n');
fprintf('======================================\n');
fprintf('Threshold method: %s\n', upper(config.threshold_method));
fprintf('Threshold range: %s\n', mat2str(config.threshold_range));
fprintf('Processing %d network types...\n\n', size(networks_config, 1));

% Initialize storage
all_results = struct();

% Process each group
for g = 1:length(groups)
    group_name = groups{g};
    group_path = fullfile(base_path, group_name);
    
    fprintf('Processing Group: %s\n', upper(group_name));
    fprintf('----------------------------------------\n');
    
    patient_dirs = dir(group_path);
    patient_dirs = patient_dirs([patient_dirs.isdir] & ~ismember({patient_dirs.name}, {'.', '..'}));
    
    % Process each patient
    for p = 1:length(patient_dirs)
        patient_name = patient_dirs(p).name;
        patient_path = fullfile(group_path, patient_name);
        
        fprintf('  Patient: %s\n', patient_name);
        
        feature_folders = findFeatureFolders(patient_path);
        
        % Process each recording session
        for f = 1:length(feature_folders)
            feature_folder = feature_folders{f};
            conn_file = fullfile(feature_folder, 'functional_connectivity.mat');
            
            if exist(conn_file, 'file')
                try
                    data = load(conn_file);
                    [~, folder_name] = fileparts(feature_folder);
                    session_id = extractSessionID(folder_name);
                    
                    fprintf('    Session: %s\n', session_id);
                    
                    % Process each network configuration
                    for net_idx = 1:size(networks_config, 1)
                        network_name = networks_config{net_idx, 1};
                        conn_type = networks_config{net_idx, 2};
                        band_name = networks_config{net_idx, 3};
                        band_idx = networks_config{net_idx, 4};
                        
                        % Extract connectivity matrix
                        W_original = extractConnectivityMatrix(data.connectivity, conn_type, band_idx);
                        
                        if ~isempty(W_original) && any(W_original(:) > 0)
                            % Analyze with chosen threshold method
                            results = analyzeNetworkMultiThreshold(W_original, config);
                            
                            % Add metadata
                            results.metadata.group = group_name;
                            results.metadata.patient = patient_name;
                            results.metadata.session = session_id;
                            results.metadata.network_type = network_name;
                            results.metadata.conn_type = conn_type;
                            results.metadata.band = band_name;
                            
                            % Store results
                            result_key = sprintf('%s_%s_%s_%s', group_name, patient_name, session_id, network_name);
                            all_results.(result_key) = results;
                            
                            % Save results
                            saveNetworkResults(results, output_base, group_name, ...
                                patient_name, session_id, network_name, config);
                            
                            if config.verbose
                                fprintf('      ✓ %s analyzed (%dx%d)\n', network_name, size(W_original,1), size(W_original,2));
                            end
                        else
                            if config.verbose
                                fprintf('      ✗ %s: No valid data\n', network_name);
                            end
                        end
                    end
                catch ME
                    fprintf('    ERROR: %s\n', ME.message);
                end
            end
        end
    end
    fprintf('\n');
end

fprintf('Processing Complete!\n\n');

%% ==================== GROUP ANALYSIS ====================
fprintf('Generating Group Comparisons...\n');
performGroupAnalysis(all_results, output_base, networks_config, groups, config);

fprintf('\n✓ Analysis Complete! Results in: %s\n', output_base);

%% ==================== HELPER FUNCTIONS ====================

function folders = findFeatureFolders(patient_path)
    folders = {};
    all_items = dir(patient_path);
    for i = 1:length(all_items)
        if all_items(i).isdir && ~strcmp(all_items(i).name, '.') && ~strcmp(all_items(i).name, '..')
            current_path = fullfile(patient_path, all_items(i).name);
            if contains(all_items(i).name, '_processed_bipolar_features')
                folders{end+1} = current_path;
            else
                sub_folders = findFeatureFolders(current_path);
                folders = [folders, sub_folders];
            end
        end
    end
end

function session_id = extractSessionID(folder_name)
    tokens = regexp(folder_name, '(s\d+_t\d+)', 'tokens');
    if ~isempty(tokens)
        session_id = tokens{1}{1};
    else
        session_id = 'unknown';
    end
end

function conn_matrix = extractConnectivityMatrix(connectivity, conn_type, band_idx)
    conn_matrix = [];
    field_map = struct('coherence', 'coherence', 'plv', 'plv', 'phase_lag_index', 'phase_lag_index');
    
    if isfield(field_map, conn_type)
        field_name = field_map.(conn_type);
        if isfield(connectivity, field_name)
            full_matrix = connectivity.(field_name);
            if ndims(full_matrix) == 3 && size(full_matrix, 3) >= band_idx
                conn_matrix = full_matrix(:, :, band_idx);
            end
        end
    end
end

function results = analyzeNetworkMultiThreshold(W_original, config)
    % Multi-threshold analysis of weighted network using SINGLE chosen method
    
    n = size(W_original, 1);
    
    % Ensure symmetry and remove diagonal
    W_original = (W_original + W_original') / 2;
    W_original(1:n+1:end) = 0;
    
    % Store original network info
    results.original = struct();
    results.original.matrix = W_original;
    results.original.num_nodes = n;
    results.original.mean_weight = mean(W_original(W_original > 0));
    results.original.std_weight = std(W_original(W_original > 0));
    results.original.max_weight = max(W_original(:));
    results.original.num_edges_total = sum(W_original(:) > 0) / 2;
    
    % Store configuration
    results.config = config;
    % Prepare storage for thresholded networks
    num_thresholds = length(config.threshold_range);
    results.thresholded = struct();
    % If there's only one threshold, store the matrix directly (numeric),
    % otherwise use a cell array where each cell contains a matrix.
    if num_thresholds > 1
        results.thresholded.matrix = cell(num_thresholds, 1);
        results.thresholded.num_edges = zeros(num_thresholds, 1);
        results.thresholded.density = zeros(num_thresholds, 1);
    else
        results.thresholded.matrix = [];
        results.thresholded.num_edges = 0;
        results.thresholded.density = 0;
    end
    
    % Initialize results array for the chosen method
    results.metrics = [];
    
    % Apply the chosen thresholding method
    fprintf('        %s thresholds: ', upper(config.threshold_method));
    
    for i = 1:length(config.threshold_range)
        threshold_val = config.threshold_range(i);
        
        % Apply threshold based on chosen method
        switch config.threshold_method
            case 'proportional'
                W_thresh = applyProportionalThreshold(W_original, threshold_val);
            case 'absolute'
                W_thresh = W_original;
                W_thresh(W_thresh < threshold_val) = 0;
            case 'mst_plus'
                W_thresh = applyMSTPlus(W_original, threshold_val);
        end
        
        % Calculate metrics
        metrics = calculateWeightedGraphMetrics(W_thresh, W_original);
        % Save thresholded matrix and simple summaries
        if num_thresholds > 1
            results.thresholded.matrix{i} = W_thresh;
            results.thresholded.num_edges(i) = sum(W_thresh(:) > 0) / 2;
            results.thresholded.density(i) = metrics.density;
        else
            % Single threshold: store matrix directly and scalars
            results.thresholded.matrix = W_thresh;
            results.thresholded.num_edges = sum(W_thresh(:) > 0) / 2;
            results.thresholded.density = metrics.density;
        end
        metrics.threshold_value = threshold_val;
        metrics.threshold_method = config.threshold_method;
        
        % Store metrics
        results.metrics = [results.metrics; metrics];
        
        % Progress indicator
        if strcmp(config.threshold_method, 'proportional')
            fprintf('%.0f%% ', threshold_val*100);
        else
            fprintf('%.2f ', threshold_val);
        end
    end
    fprintf('\n');
end

function W_thresh = applyProportionalThreshold(W, density)
    % Keep top density% of connections by weight
    n = size(W, 1);
    num_edges_keep = round(density * n * (n-1) / 2);
    
    % Get upper triangle values
    upper_vals = W(triu(true(n), 1));
    upper_vals_sorted = sort(upper_vals, 'descend');
    
    if num_edges_keep > 0 && num_edges_keep <= length(upper_vals_sorted)
        threshold = upper_vals_sorted(num_edges_keep);
    else
        threshold = 0;
    end
    
    W_thresh = W;
    W_thresh(W_thresh < threshold) = 0;
end

function W_mst_plus = applyMSTPlus(W, additional_density)
    % MST + additional strongest connections
    % Ensures connectivity while maintaining network properties
    n = size(W, 1);
    
    % Create distance matrix (inverse weights)
    D = 1 ./ (W + eps);
    D(W == 0) = inf;
    D(1:n+1:end) = 0;
    
    % Find MST using Prim's algorithm
    W_mst = zeros(n);
    visited = false(n, 1);
    visited(1) = true;
    
    for iter = 1:(n-1)
        min_dist = inf;
        best_i = 0;
        best_j = 0;
        
        for i = 1:n
            if visited(i)
                for j = 1:n
                    if ~visited(j) && D(i,j) < min_dist
                        min_dist = D(i,j);
                        best_i = i;
                        best_j = j;
                    end
                end
            end
        end
        
        if best_i > 0 && best_j > 0
            W_mst(best_i, best_j) = W(best_i, best_j);
            W_mst(best_j, best_i) = W(best_i, best_j);
            visited(best_j) = true;
        end
    end
    
    % Add additional strongest connections
    num_additional = round(additional_density * n * (n-1) / 2);
    
    % Find connections not in MST
    W_remaining = W;
    W_remaining(W_mst > 0) = 0;
    
    % Add strongest remaining connections
    upper_vals = W_remaining(triu(true(n), 1));
    upper_vals_sorted = sort(upper_vals, 'descend');
    
    if num_additional > 0 && num_additional <= length(upper_vals_sorted)
        threshold = upper_vals_sorted(min(num_additional, length(upper_vals_sorted)));
        W_additional = W_remaining;
        W_additional(W_additional < threshold) = 0;
    else
        W_additional = zeros(n);
    end
    
    W_mst_plus = W_mst + W_additional;
end

function metrics = calculateWeightedGraphMetrics(W_thresh, W_original)
    % Calculate comprehensive weighted graph metrics
    n = size(W_thresh, 1);
    
    % Normalize thresholded network
    if max(W_thresh(:)) > 0
        W_norm = W_thresh / max(W_original(:)); % Normalize by original max
    else
        W_norm = W_thresh;
    end
    
    %% BASIC METRICS
    metrics.num_nodes = n;
    metrics.num_edges = sum(W_thresh(:) > 0) / 2;
    metrics.density = metrics.num_edges / (n * (n-1) / 2);
    
    % Strength (weighted degree)
    metrics.strength = sum(W_norm, 2);
    metrics.mean_strength = mean(metrics.strength);
    metrics.std_strength = std(metrics.strength);
    
    %% CLUSTERING COEFFICIENT (Onnela et al., 2005 - weighted version)
    metrics.clustering_coeff = zeros(n, 1);
    for i = 1:n
        neighbors = find(W_norm(i, :) > 0);
        k_i = length(neighbors);
        if k_i >= 2
            % Weighted clustering (geometric mean version)
            W_cube = W_norm.^(1/3);
            triangles = sum(sum(W_cube(i, neighbors) .* W_cube(neighbors, neighbors))) / 2;
            metrics.clustering_coeff(i) = triangles / (k_i * (k_i - 1) / 2);
        end
    end
    metrics.mean_clustering = mean(metrics.clustering_coeff);
    
    %% TRANSITIVITY
    numerator = 0;
    denominator = 0;
    for i = 1:n
        neighbors = find(W_norm(i, :) > 0);
        k_i = length(neighbors);
        if k_i >= 2
            for j = 1:length(neighbors)
                for k = j+1:length(neighbors)
                    n1 = neighbors(j);
                    n2 = neighbors(k);
                    denominator = denominator + 1;
                    if W_norm(n1, n2) > 0
                        numerator = numerator + (W_norm(i,n1) * W_norm(i,n2) * W_norm(n1,n2))^(1/3);
                    end
                end
            end
        end
    end
    metrics.transitivity = numerator / max(denominator, 1);
    
    %% PATH LENGTH & EFFICIENCY
    D = W_norm;
    D(D > 0) = 1 ./ D(D > 0);
    D(D == 0) = inf;
    D(1:n+1:end) = 0;
    
    % Floyd-Warshall
    for k = 1:n
        D = min(D, D(:,k) + D(k,:));
    end
    
    valid_paths = D(~isinf(D) & D > 0);
    metrics.path_length = mean(valid_paths);
    if isempty(valid_paths), metrics.path_length = inf; end
    
    % Global efficiency
    E = D;
    E(isinf(E)) = 0;
    E(E > 0) = 1 ./ E(E > 0);
    metrics.global_efficiency = sum(E(:)) / (n * (n-1));
    
    % Local efficiency
    metrics.local_efficiency = 0;
    for i = 1:n
        neighbors = find(W_norm(i, :) > 0);
        k_i = length(neighbors);
        if k_i >= 2
            W_sub = W_norm(neighbors, neighbors);
            D_sub = W_sub;
            D_sub(D_sub > 0) = 1 ./ D_sub(D_sub > 0);
            D_sub(D_sub == 0) = inf;
            D_sub(1:k_i+1:end) = 0;
            
            for k = 1:k_i
                D_sub = min(D_sub, D_sub(:,k) + D_sub(k,:));
            end
            
            D_sub(isinf(D_sub)) = 0;
            D_sub(D_sub > 0) = 1 ./ D_sub(D_sub > 0);
            metrics.local_efficiency = metrics.local_efficiency + sum(D_sub(:)) / (k_i * (k_i-1));
        end
    end
    metrics.local_efficiency = metrics.local_efficiency / n;
    
    %% CENTRALITY MEASURES
    % Betweenness
    metrics.betweenness = calculateBetweenness(W_norm);
    metrics.mean_betweenness = mean(metrics.betweenness);
    
    % Eigenvector centrality
    try
        [V, ~] = eigs(W_norm, 1, 'largestabs');
        metrics.eigenvector_centrality = abs(V);
        metrics.mean_eigenvector = mean(metrics.eigenvector_centrality);
    catch
        metrics.eigenvector_centrality = zeros(n, 1);
        metrics.mean_eigenvector = 0;
    end
    
    %% MODULARITY (Newman's algorithm)
    [metrics.communities, metrics.modularity] = calculateModularity(W_norm);
    metrics.num_communities = length(unique(metrics.communities));
    
    %% ASSORTATIVITY
    metrics.assortativity = calculateAssortativity(W_norm, metrics.strength);
    
    %% SMALL-WORLDNESS
    metrics.small_worldness = calculateSmallWorldness(W_norm, metrics.mean_clustering, metrics.path_length);
    
    %% HUB DETECTION
    hub_threshold = metrics.mean_strength + 1.5 * metrics.std_strength;
    metrics.hub_nodes = find(metrics.strength > hub_threshold);
    metrics.num_hubs = length(metrics.hub_nodes);
    
    %% NETWORK RESILIENCE
    metrics.resilience = assessResilience(W_norm);
    
    %% SANITIZE ALL METRICS (ensure real, non-NaN, non-Inf values)
    metric_fields = fieldnames(metrics);
    for i = 1:length(metric_fields)
        field_name = metric_fields{i};
        if isnumeric(metrics.(field_name)) && isscalar(metrics.(field_name))
            val = real(metrics.(field_name));
            if isnan(val) || isinf(val)
                metrics.(field_name) = 0;
            else
                metrics.(field_name) = val;
            end
        end
    end
end

function BC = calculateBetweenness(W)
    n = size(W, 1);
    BC = zeros(n, 1);
    
    for s = 1:n
        [dist, num_paths, pred] = dijkstraAllPaths(W, s);
        delta = zeros(n, 1);
        [~, order] = sort(dist, 'descend');
        
        for i = 1:n
            w = order(i);
            if w ~= s && ~isinf(dist(w))
                for p = pred{w}
                    if num_paths(w) > 0
                        delta(p) = delta(p) + (num_paths(p) / num_paths(w)) * (1 + delta(w));
                    end
                end
            end
        end
        BC = BC + delta;
    end
    
    if n > 2
        BC = BC / ((n-1) * (n-2));
    end
end

function [dist, num_paths, pred] = dijkstraAllPaths(W, source)
    n = size(W, 1);
    dist = inf(n, 1);
    dist(source) = 0;
    num_paths = zeros(n, 1);
    num_paths(source) = 1;
    pred = cell(n, 1);
    visited = false(n, 1);
    
    D = W;
    D(D > 0) = 1 ./ D(D > 0);
    D(D == 0) = inf;
    
    for i = 1:n
        [~, u] = min(dist + visited * inf);
        visited(u) = true;
        
        for v = find(W(u, :) > 0)
            alt = dist(u) + D(u, v);
            if alt < dist(v) - 1e-10
                dist(v) = alt;
                num_paths(v) = num_paths(u);
                pred{v} = u;
            elseif abs(alt - dist(v)) < 1e-10
                num_paths(v) = num_paths(v) + num_paths(u);
                pred{v} = [pred{v}, u];
            end
        end
    end
end

function [communities, Q] = calculateModularity(W)
    n = size(W, 1);
    k = sum(W, 2);
    m = sum(k) / 2;
    
    if m == 0 || n < 2
        communities = ones(n, 1);
        Q = 0;
        return;
    end
    
    B = W - (k * k') / (2 * m);
    B = (B + B') / 2;
    
    try
        [V, ~] = eigs(B, min(5, n-1), 'largestreal');
        V = real(V);
        
        if size(V, 2) >= 2
            communities = kmeans(V, min(2, n), 'Replicates', 10, 'MaxIter', 100);
        else
            communities = ones(n, 1);
        end
        
        Q = 0;
        for i = 1:n
            for j = 1:n
                if communities(i) == communities(j)
                    Q = Q + (W(i,j) - k(i)*k(j)/(2*m));
                end
            end
        end
        Q = real(Q / (2 * m));
        Q = max(-1, min(1, Q));
        
    catch
        communities = ones(n, 1);
        Q = 0;
    end
end

function r = calculateAssortativity(W, strength)
    n = size(W, 1);
    edges = [];
    
    for i = 1:n
        for j = i+1:n
            if W(i,j) > 0
                edges = [edges; strength(i), strength(j), W(i,j)];
            end
        end
    end
    
    if isempty(edges)
        r = 0;
        return;
    end
    
    w_sum = sum(edges(:,3));
    mean_deg = sum(edges(:,3) .* (edges(:,1) + edges(:,2))) / (2 * w_sum);
    
    numerator = sum(edges(:,3) .* edges(:,1) .* edges(:,2)) / w_sum - mean_deg^2;
    denom = sum(edges(:,3) .* (edges(:,1).^2 + edges(:,2).^2) / 2) / w_sum - mean_deg^2;
    
    r = numerator / max(denom, eps);
end

function sigma = calculateSmallWorldness(W, C, L)
    if C == 0 || isinf(L)
        sigma = 0;
        return;
    end
    
    n = size(W, 1);
    num_rand = 10;
    C_rand_sum = 0;
    L_rand_sum = 0;
    
    for r = 1:num_rand
        W_rand = generateRandomNetwork(W);
        C_rand_sum = C_rand_sum + mean(calculateClusteringPerNode(W_rand));
        L_temp = calculateAvgPathLength(W_rand);
        if ~isinf(L_temp)
            L_rand_sum = L_rand_sum + L_temp;
        end
    end
    
    C_rand = C_rand_sum / num_rand;
    L_rand = L_rand_sum / num_rand;
    
    if C_rand > 0 && L_rand > 0
        sigma = (C / C_rand) / (L / L_rand);
    else
        sigma = 0;
    end
end

function W_rand = generateRandomNetwork(W)
    n = size(W, 1);
    [i, j] = find(triu(W, 1) > 0);
    weights = W(sub2ind(size(W), i, j));
    
    W_rand = zeros(n);
    perm = randperm(length(i));
    
    for k = 1:length(i)
        W_rand(i(k), j(perm(k))) = weights(k);
        W_rand(j(perm(k)), i(k)) = weights(k);
    end
end

function C = calculateClusteringPerNode(W)
    n = size(W, 1);
    C = zeros(n, 1);
    
    for i = 1:n
        neighbors = find(W(i, :) > 0);
        k_i = length(neighbors);
        if k_i >= 2
            W_cube = W.^(1/3);
            C(i) = sum(sum(W_cube(i, neighbors) .* W_cube(neighbors, neighbors))) / (2 * k_i * (k_i-1) / 2);
        end
    end
end

function L = calculateAvgPathLength(W)
    n = size(W, 1);
    D = W;
    D(D > 0) = 1 ./ D(D > 0);
    D(D == 0) = inf;
    D(1:n+1:end) = 0;
    
    for k = 1:n
        D = min(D, D(:,k) + D(k,:));
    end
    
    valid = D(~isinf(D) & D > 0);
    L = mean(valid);
    if isempty(valid), L = inf; end
end

function resilience = assessResilience(W)
    n = size(W, 1);
    GE_init = calculateGE(W);
    strength = sum(W, 2);
    [~, order] = sort(strength, 'descend');
    
    % Targeted attack
    W_temp = W;
    GE_targeted = zeros(min(10, n), 1);
    for i = 1:min(10, n)
        if i > 1
            W_temp(order(i-1), :) = 0;
            W_temp(:, order(i-1)) = 0;
        end
        GE_targeted(i) = calculateGE(W_temp);
    end
    resilience.targeted = trapz(GE_targeted) / (GE_init * min(10, n));
    
    % Random failure
    GE_random = 0;
    for trial = 1:5
        W_temp = W;
        rand_order = randperm(n);
        GE_trial = zeros(min(10, n), 1);
        for i = 1:min(10, n)
            if i > 1
                W_temp(rand_order(i-1), :) = 0;
                W_temp(:, rand_order(i-1)) = 0;
            end
            GE_trial(i) = calculateGE(W_temp);
        end
        GE_random = GE_random + trapz(GE_trial);
    end
    resilience.random = (GE_random / 5) / (GE_init * min(10, n));
end

function GE = calculateGE(W)
    n = size(W, 1);
    D = W;
    D(D > 0) = 1 ./ D(D > 0);
    D(D == 0) = inf;
    D(1:n+1:end) = 0;
    
    for k = 1:n
        D = min(D, D(:,k) + D(k,:));
    end
    
    D(isinf(D)) = 0;
    D(D > 0) = 1 ./ D(D > 0);
    GE = sum(D(:)) / (n * (n-1));
end

function saveNetworkResults(results, output_base, group, patient, session, network_name, config)
    output_dir = fullfile(output_base, group, patient, session);
    if ~exist(output_dir, 'dir'), mkdir(output_dir); end
    
    % Save MAT file
    filename = fullfile(output_dir, sprintf('%s_%s_results.mat', network_name, config.threshold_method));
    save(filename, 'results');
    
    % Save summary report
    reportfile = fullfile(output_dir, sprintf('%s_%s_summary.txt', network_name, config.threshold_method));
    fid = fopen(reportfile, 'w');
    fprintf(fid, 'Network Analysis: %s\n', network_name);
    fprintf(fid, 'Thresholding Method: %s\n', upper(config.threshold_method));
    fprintf(fid, '================================================\n\n');
    
    fprintf(fid, 'ORIGINAL NETWORK:\n');
    fprintf(fid, '  Nodes: %d\n', results.original.num_nodes);
    fprintf(fid, '  Total Edges: %.0f\n', results.original.num_edges_total);
    fprintf(fid, '  Weight: %.4f ± %.4f (range: [0, %.4f])\n\n', ...
        results.original.mean_weight, results.original.std_weight, results.original.max_weight);
    
    % Find best threshold (based on small-worldness)
    if ~isempty(results.metrics)
        sw_vals = [results.metrics.small_worldness];
        [best_sw, best_idx] = max(sw_vals);
        best_metrics = results.metrics(best_idx);
        
        fprintf(fid, 'BEST THRESHOLD (highest small-worldness):\n');
        fprintf(fid, '  Threshold Value: %.4f\n', best_metrics.threshold_value);
        fprintf(fid, '  Small-Worldness: %.4f\n', best_sw);
        fprintf(fid, '  Density: %.4f | Edges: %.0f\n', best_metrics.density, best_metrics.num_edges);
        fprintf(fid, '  Clustering: %.4f | Path Length: %.4f\n', ...
            best_metrics.mean_clustering, best_metrics.path_length);
        fprintf(fid, '  Global Eff: %.4f | Local Eff: %.4f\n', ...
            best_metrics.global_efficiency, best_metrics.local_efficiency);
        fprintf(fid, '  Modularity: %.4f | Communities: %d\n', ...
            best_metrics.modularity, best_metrics.num_communities);
        fprintf(fid, '  Assortativity: %.4f | Hubs: %d\n\n', ...
            best_metrics.assortativity, best_metrics.num_hubs);
        
        fprintf(fid, '\nALL THRESHOLDS:\n');
        fprintf(fid, '%s\n', repmat('-', 1, 120));
        fprintf(fid, '%-10s | %-8s | %-8s | %-8s | %-8s | %-8s | %-8s | %-8s | %-8s\n', ...
            'Threshold', 'Density', 'Cluster', 'PathLen', 'GlobEff', 'LocEff', 'Modul', 'Assort', 'SW');
        fprintf(fid, '%s\n', repmat('-', 1, 120));
        
        for i = 1:length(results.metrics)
            m = results.metrics(i);
            fprintf(fid, '%-10.4f | %-8.4f | %-8.4f | %-8.4f | %-8.4f | %-8.4f | %-8.4f | %-8.4f | %-8.4f\n', ...
                m.threshold_value, m.density, m.mean_clustering, m.path_length, ...
                m.global_efficiency, m.local_efficiency, m.modularity, m.assortativity, m.small_worldness);
        end
    end
    
    fclose(fid);
    
    % Create visualization
    createSingleMethodVisualization(results, output_dir, network_name, config);
end

function createSingleMethodVisualization(results, output_dir, network_name, config)
    fig = figure('Visible', 'off', 'Position', [50, 50, 1800, 1200]);
    
    % Extract threshold values
    thresh_vals = [results.metrics.threshold_value];
    
    % Plot 1: Original Connectivity Matrix
    subplot(3, 4, 1);
    imagesc(results.original.matrix);
    colorbar;
    title('Original Connectivity Matrix');
    xlabel('Channel'); ylabel('Channel');
    colormap(gca, 'jet');
    axis square;
    
    % Plot 2: Weight Distribution
    subplot(3, 4, 2);
    W_vals = results.original.matrix(results.original.matrix > 0);
    histogram(W_vals, 30, 'FaceColor', [0.3, 0.3, 0.8]);
    xlabel('Connection Strength');
    ylabel('Frequency');
    title('Weight Distribution');
    grid on;
    
    % Plot 3: Density vs Threshold
    subplot(3, 4, 3);
    density_vals = [results.metrics.density];
    plot(thresh_vals, density_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0, 0.4470, 0.7410]);
    xlabel(config.threshold_label);
    ylabel('Network Density');
    title('Density vs Threshold');
    grid on;
    
    % Plot 4: Small-Worldness vs Threshold
    subplot(3, 4, 4);
    sw_vals = [results.metrics.small_worldness];
    plot(thresh_vals, sw_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.8500, 0.3250, 0.0980]);
    xlabel(config.threshold_label);
    ylabel('Small-Worldness (σ)');
    title('Small-Worldness vs Threshold');
    grid on;
    yline(1, '--k', 'SW=1');
    
    % Plot 5: Clustering Coefficient
    subplot(3, 4, 5);
    cc_vals = [results.metrics.mean_clustering];
    plot(thresh_vals, cc_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.9290, 0.6940, 0.1250]);
    xlabel(config.threshold_label);
    ylabel('Clustering Coefficient');
    title('Clustering vs Threshold');
    grid on;
    
    % Plot 6: Path Length
    subplot(3, 4, 6);
    pl_vals = [results.metrics.path_length];
    pl_vals(isinf(pl_vals)) = NaN;
    plot(thresh_vals, pl_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.4940, 0.1840, 0.5560]);
    xlabel(config.threshold_label);
    ylabel('Path Length');
    title('Path Length vs Threshold');
    grid on;
    
    % Plot 7: Global Efficiency
    subplot(3, 4, 7);
    ge_vals = [results.metrics.global_efficiency];
    plot(thresh_vals, ge_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.4660, 0.6740, 0.1880]);
    xlabel(config.threshold_label);
    ylabel('Global Efficiency');
    title('Global Efficiency vs Threshold');
    grid on;
    
    % Plot 8: Local Efficiency
    subplot(3, 4, 8);
    le_vals = [results.metrics.local_efficiency];
    plot(thresh_vals, le_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.3010, 0.7450, 0.9330]);
    xlabel(config.threshold_label);
    ylabel('Local Efficiency');
    title('Local Efficiency vs Threshold');
    grid on;
    
    % Plot 9: Modularity
    subplot(3, 4, 9);
    mod_vals = [results.metrics.modularity];
    plot(thresh_vals, mod_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.6350, 0.0780, 0.1840]);
    xlabel(config.threshold_label);
    ylabel('Modularity (Q)');
    title('Modularity vs Threshold');
    grid on;
    
    % Plot 10: Assortativity
    subplot(3, 4, 10);
    assort_vals = [results.metrics.assortativity];
    plot(thresh_vals, assort_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0, 0.5, 0]);
    xlabel(config.threshold_label);
    ylabel('Assortativity');
    title('Assortativity vs Threshold');
    grid on;
    yline(0, '--k');
    
    % Plot 11: Number of Hubs
    subplot(3, 4, 11);
    hub_vals = real([results.metrics.num_hubs]);
    plot(thresh_vals, hub_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.75, 0, 0.75]);
    xlabel(config.threshold_label);
    ylabel('Number of Hubs');
    title('Hub Nodes vs Threshold');
    grid on;
    
    % Plot 12: Network Resilience
    subplot(3, 4, 12);
    resil_vals = arrayfun(@(x) real(x.targeted), [results.metrics.resilience]);
    plot(thresh_vals, resil_vals, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [1, 0.5, 0]);
    xlabel(config.threshold_label);
    ylabel('Resilience (Targeted)');
    title('Network Resilience vs Threshold');
    grid on;
    
    sgtitle(sprintf('%s Analysis: %s (%s)', upper(config.threshold_method), ...
        strrep(network_name, '_', ' '), upper(config.threshold_method)), ...
        'FontSize', 14, 'FontWeight', 'bold');
    
    % Save figure
    img_file = fullfile(output_dir, sprintf('%s_%s_analysis.png', network_name, config.threshold_method));
    saveas(fig, img_file);
    close(fig);
end

function performGroupAnalysis(all_results, output_base, networks_config, groups, config)
    % Group comparison for the chosen thresholding method
    
    report_file = fullfile(output_base, sprintf('GROUP_COMPARISON_%s.txt', upper(config.threshold_method)));
    fid = fopen(report_file, 'w');
    
    fprintf(fid, '================================================================\n');
    fprintf(fid, '       WEIGHTED EEG NETWORK ANALYSIS - GROUP COMPARISON        \n');
    fprintf(fid, '       Thresholding Method: %s                                 \n', upper(config.threshold_method));
    fprintf(fid, '================================================================\n\n');
    fprintf(fid, 'Analysis Date: %s\n', datestr(now));
    fprintf(fid, 'Groups: %s vs %s\n\n', groups{1}, groups{2});
    
    fields = fieldnames(all_results);
    
    % Process each network type
    for net_idx = 1:size(networks_config, 1)
        network_name = networks_config{net_idx, 1};
        
        fprintf(fid, '\n\n');
        fprintf(fid, '================================================================\n');
        fprintf(fid, '  NETWORK: %s\n', upper(strrep(network_name, '_', ' ')));
        fprintf(fid, '================================================================\n\n');
        
        % For each threshold level
        for t = 1:length(config.threshold_range)
            thresh_val = config.threshold_range(t);
            
            fprintf(fid, 'Threshold: %.4f\n', thresh_val);
            fprintf(fid, '%s\n', repmat('=', 1, 100));
            
            % Collect metrics for both groups
            group_data = cell(2, 1);
            
            for g = 1:2
                group_name = groups{g};
                metrics_collection = struct();
                
                % Find all matching results
                for f = 1:length(fields)
                    result = all_results.(fields{f});
                    if strcmp(result.metadata.network_type, network_name) && ...
                       strcmp(result.metadata.group, group_name)
                        
                        % Extract metrics at this threshold
                        if ~isempty(result.metrics)
                            % Find closest threshold
                            thresh_diffs = abs([result.metrics.threshold_value] - thresh_val);
                            [min_diff, idx] = min(thresh_diffs);
                            
                            if min_diff < 0.01  % Tolerance
                                metrics = result.metrics(idx);
                                
                                % Store metrics
                                fn = fieldnames(metrics);
                                for fi = 1:length(fn)
                                    field_name = fn{fi};
                                    if isnumeric(metrics.(field_name)) && isscalar(metrics.(field_name))
                                        if ~isfield(metrics_collection, field_name)
                                            metrics_collection.(field_name) = [];
                                        end
                                        metrics_collection.(field_name)(end+1) = metrics.(field_name);
                                    end
                                end
                            end
                        end
                    end
                end
                
                group_data{g} = metrics_collection;
            end
            
            % Statistical comparison
            if ~isempty(fieldnames(group_data{1})) && ~isempty(fieldnames(group_data{2}))
                
                fprintf(fid, '\n%-30s | %-25s | %-25s | p-value (d)\n', ...
                    'Metric', groups{1}, groups{2});
                fprintf(fid, '%s\n', repmat('-', 1, 100));
                
                key_metrics = {'density', 'mean_clustering', 'path_length', ...
                    'global_efficiency', 'local_efficiency', 'modularity', ...
                    'assortativity', 'small_worldness', 'num_hubs'};
                
                metric_labels = {'Density', 'Clustering Coeff', 'Path Length', ...
                    'Global Efficiency', 'Local Efficiency', 'Modularity', ...
                    'Assortativity', 'Small-Worldness', 'Hub Count'};
                
                for k = 1:length(key_metrics)
                    metric = key_metrics{k};
                    
                    if isfield(group_data{1}, metric) && isfield(group_data{2}, metric)
                        data1 = group_data{1}.(metric);
                        data2 = group_data{2}.(metric);
                        
                        % Remove inf values
                        data1(isinf(data1)) = [];
                        data2(isinf(data2)) = [];
                        
                        if length(data1) > 1 && length(data2) > 1
                            % T-test
                            [~, p] = ttest2(data1, data2);
                            
                            % Effect size (Cohen's d)
                            pooled_std = sqrt(((length(data1)-1)*var(data1) + ...
                                (length(data2)-1)*var(data2)) / (length(data1)+length(data2)-2));
                            if pooled_std > 0
                                cohens_d = (mean(data1) - mean(data2)) / pooled_std;
                            else
                                cohens_d = 0;
                            end
                            
                            sig = '';
                            if p < 0.001, sig = '***';
                            elseif p < 0.01, sig = '**';
                            elseif p < 0.05, sig = '*';
                            end
                            
                            fprintf(fid, '%-30s | %8.4f ± %6.4f (n=%2d) | %8.4f ± %6.4f (n=%2d) | %.4f (%.2f)%s\n', ...
                                metric_labels{k}, mean(data1), std(data1), length(data1), ...
                                mean(data2), std(data2), length(data2), p, cohens_d, sig);
                        end
                    end
                end
                
                fprintf(fid, '\nSignificance: * p<0.05, ** p<0.01, *** p<0.001\n');
            else
                fprintf(fid, 'Insufficient data for comparison at this threshold.\n');
            end
            
            fprintf(fid, '\n\n');
        end
    end
    
    fclose(fid);
    fprintf('✓ Group comparison report saved: %s\n', report_file);
    
    % Export to CSV
    exportGroupMetricsToCSV(all_results, output_base, networks_config, groups, config);
    
    % Create comparison visualizations
    createGroupComparisonPlots(all_results, output_base, networks_config, groups, config);
end

function exportGroupMetricsToCSV(all_results, output_base, networks_config, groups, config)
    fprintf('Exporting metrics to CSV files...\n');
    
    fields = fieldnames(all_results);
    
    for net_idx = 1:size(networks_config, 1)
        network_name = networks_config{net_idx, 1};
        
        csv_file = fullfile(output_base, sprintf('%s_%s_all_metrics.csv', network_name, config.threshold_method));
        fid_csv = fopen(csv_file, 'w');
        
        % Header
        fprintf(fid_csv, 'Group,Patient,Session,Threshold,Density,NumEdges,');
        fprintf(fid_csv, 'MeanStrength,Clustering,Transitivity,PathLength,');
        fprintf(fid_csv, 'GlobalEff,LocalEff,Betweenness,Eigenvector,');
        fprintf(fid_csv, 'Modularity,NumCommunities,Assortativity,SmallWorldness,NumHubs,');
        fprintf(fid_csv, 'ResilienceTargeted,ResilienceRandom\n');
        
        % Data
        for f = 1:length(fields)
            result = all_results.(fields{f});
            
            if strcmp(result.metadata.network_type, network_name)
                metrics_data = result.metrics;
                
                if ~isempty(metrics_data)
                    for i = 1:length(metrics_data)
                        m_data = metrics_data(i);
                        
                        fprintf(fid_csv, '%s,%s,%s,%.6f,%.6f,%d,', ...
                            result.metadata.group, result.metadata.patient, ...
                            result.metadata.session, m_data.threshold_value, ...
                            m_data.density, round(m_data.num_edges));
                        
                        fprintf(fid_csv, '%.6f,%.6f,%.6f,%.6f,', ...
                            m_data.mean_strength, m_data.mean_clustering, ...
                            m_data.transitivity, m_data.path_length);
                        
                        fprintf(fid_csv, '%.6f,%.6f,%.6f,%.6f,', ...
                            m_data.global_efficiency, m_data.local_efficiency, ...
                            m_data.mean_betweenness, m_data.mean_eigenvector);
                        
                        fprintf(fid_csv, '%.6f,%d,%.6f,%.6f,%d,', ...
                            m_data.modularity, m_data.num_communities, ...
                            m_data.assortativity, m_data.small_worldness, m_data.num_hubs);
                        
                        fprintf(fid_csv, '%.6f,%.6f\n', ...
                            m_data.resilience.targeted, m_data.resilience.random);
                    end
                end
            end
        end
        
        fclose(fid_csv);
        fprintf('  ✓ %s\n', csv_file);
    end
end

function createGroupComparisonPlots(all_results, output_base, networks_config, groups, config)
    fprintf('Creating group comparison visualizations...\n');
    
    fields = fieldnames(all_results);
    
    for net_idx = 1:size(networks_config, 1)
        network_name = networks_config{net_idx, 1};
        
        fig = figure('Visible', 'off', 'Position', [50, 50, 1600, 1200]);
        
        key_metrics = {'mean_clustering', 'global_efficiency', 'modularity', 'small_worldness'};
        metric_labels = {'Clustering Coefficient', 'Global Efficiency', 'Modularity', 'Small-Worldness'};
        
        for met_idx = 1:length(key_metrics)
            subplot(2, 2, met_idx);
            hold on;
            
            colors = {[0.8, 0.2, 0.2], [0.2, 0.2, 0.8]};
            
            for g = 1:2
                group_name = groups{g};
                
                % Collect data across all subjects
                thresh_range = config.threshold_range;
                
                mean_vals = zeros(length(thresh_range), 1);
                std_vals = zeros(length(thresh_range), 1);
                
                for t = 1:length(thresh_range)
                    thresh_val = thresh_range(t);
                    values = [];
                    
                    for f = 1:length(fields)
                        result = all_results.(fields{f});
                        if strcmp(result.metadata.network_type, network_name) && ...
                           strcmp(result.metadata.group, group_name)
                            
                            if ~isempty(result.metrics)
                                thresh_diffs = abs([result.metrics.threshold_value] - thresh_val);
                                [min_diff, idx] = min(thresh_diffs);
                                if min_diff < 0.01
                                    val = result.metrics(idx).(key_metrics{met_idx});
                                    if ~isinf(val)
                                        values(end+1) = val;
                                    end
                                end
                            end
                        end
                    end
                    
                    if ~isempty(values)
                        mean_vals(t) = mean(values);
                        std_vals(t) = std(values) / sqrt(length(values));  % SEM
                    end
                end
                
                % Scale x-axis based on method
                if strcmp(config.threshold_method, 'proportional')
                    x_vals = thresh_range * 100;  % Convert to percentage
                else
                    x_vals = thresh_range;
                end
                
                % Plot with error bars
                errorbar(x_vals, mean_vals, std_vals, '-o', ...
                    'LineWidth', 2, 'Color', colors{g}, 'DisplayName', groups{g}, ...
                    'MarkerFaceColor', colors{g}, 'MarkerSize', 6);
            end
            
            xlabel(config.threshold_label);
            ylabel(metric_labels{met_idx});
            title(metric_labels{met_idx});
            legend('Location', 'best');
            grid on;
            hold off;
        end
        
        sgtitle(sprintf('Group Comparison: %s (%s)', strrep(network_name, '_', ' '), upper(config.threshold_method)), ...
            'FontSize', 14, 'FontWeight', 'bold');
        
        img_file = fullfile(output_base, sprintf('%s_%s_group_comparison.png', network_name, config.threshold_method));
        saveas(fig, img_file);
        close(fig);
        
        fprintf('  ✓ %s\n', img_file);
    end
end