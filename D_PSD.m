%% ==========================
%  EEG Feature Extraction Script (Using Preprocessed Data)
%  ==========================
clear; clc; close all;

baseDir = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz';
groupFolders = {'non_epilepsy','epilepsy'};
dataSummary = [];
labelSummary = [];

% Storage for group-level PSD
group_psd_storage = struct();
group_psd_storage.non_epilepsy = [];  % Will store all PSDs from non-epilepsy
group_psd_storage.epilepsy = [];      % Will store all PSDs from epilepsy

for g = 1:length(groupFolders)
    groupPath = fullfile(baseDir, groupFolders{g});
    
    % Find all *_processed_features folders
    processingDirs = dir(fullfile(groupPath, '**', '*_processed_bipolar_features'));
    processingDirs = processingDirs([processingDirs.isdir]);
    
    fprintf('\n=== Processing Group: %s ===\n', groupFolders{g});
    fprintf('Found %d processing directories\n', length(processingDirs));
    
    for f = 1:length(processingDirs)
        procDir = fullfile(processingDirs(f).folder, processingDirs(f).name);
        
        % Construct path to *_processed.mat file (in PARENT folder)
        [~, folderName, ~] = fileparts(procDir);
        processedMatName = [strrep(folderName, '_processed_bipolar_features', ''), '_processed.mat'];
        processedMatPath = fullfile(processingDirs(f).folder, processedMatName);
        
        if ~exist(processedMatPath, 'file')
            warning('Preprocessed MAT file not found: %s', processedMatPath);
            continue;
        end
        
        fprintf('\n[%d/%d] Processing: %s\n', f, length(processingDirs), processedMatName);
        
        % --- Load Preprocessed Data ---
        try
            loadedData = load(processedMatPath);
            
            % Check what variables are available
            if isfield(loadedData, 'processed_data')
                dataMat = loadedData.processed_data;
            elseif isfield(loadedData, 'data')
                dataMat = loadedData.data;
            else
                varNames = fieldnames(loadedData);
                warning('Unknown variable names in MAT file. Found: %s', strjoin(varNames, ', '));
                continue;
            end
            
            target_fs = 250;
            if isfield(loadedData, 'fs')
                fs = loadedData.fs;
            else
                fs = target_fs;
            end

            % Resample if different from target
            if fs ~= target_fs
                fprintf('⚠️ Resampling from %.1f Hz to %.1f Hz...\n', fs, target_fs);
                dataMat = resample(dataMat', target_fs, fs)';
                fs = target_fs;
            end
            
        catch ME
            warning('Failed to load preprocessed MAT: %s\nReason: %s', processedMatPath, ME.message);
            continue;
        end
        
        % --- Validate Data ---
        if isempty(dataMat) || ~isnumeric(dataMat)
            warning('Invalid data in: %s', processedMatPath);
            continue;
        end
        
        % Ensure correct orientation: channels × time
        [nRows, nCols] = size(dataMat);
        if nRows > nCols
            % Likely transposed: more rows than columns
            dataMat = dataMat';
            fprintf('  ⚠️  Transposed data: %d×%d → %d×%d\n', nRows, nCols, size(dataMat,1), size(dataMat,2));
        end
        
        if all(dataMat(:) == 0)
            warning('All-zero signal data in: %s', processedMatPath);
            continue;
        end
        
        fprintf('  ✓ Loaded: %d channels × %d samples (%.2f sec @ %d Hz)\n', ...
                size(dataMat,1), size(dataMat,2), size(dataMat,2)/fs, fs);
        
        % --- Adaptive PSD Parameters ---
        signalLength = size(dataMat, 2);
        
        if signalLength < 256
            warning('Signal too short (%d samples) for reliable PSD', signalLength);
            continue;
        elseif signalLength < 512
            windowSize = floor(signalLength / 4);
            NFFT = 2^nextpow2(windowSize);
            noverlap = floor(windowSize / 2);
        else
            windowSize = 256;
            NFFT = 512;
            noverlap = 128;
        end
        
        window = hamming(windowSize);
        
        % --- Calculate PSD ---
        try
            [pxx, f] = pwelch(dataMat', window, noverlap, NFFT, fs);
            mean_psd = mean(pxx, 2);  % Average across channels
            fprintf('  ✓ PSD: %.2f–%.2f Hz (%d frequency points)\n', min(f), max(f), numel(f));
            
        catch ME
            warning('PSD calculation failed: %s', ME.message);
            continue;
        end
        
        % --- Store PSD for Group-Level Statistics ---
        if strcmp(groupFolders{g}, 'non_epilepsy')
            group_psd_storage.non_epilepsy = cat(2, group_psd_storage.non_epilepsy, mean_psd);
        else
            group_psd_storage.epilepsy = cat(2, group_psd_storage.epilepsy, mean_psd);
        end
        
        % --- Extract Features ---
        % Define frequency bands
        idx_alpha = f >= 8 & f < 13;   % Alpha: 8-12.99 Hz
        idx_beta  = f >= 13 & f <= 30; % Beta: 13-30 Hz
        
        numAlphaPoints = sum(idx_alpha);
        numBetaPoints = sum(idx_beta);
        
        if numAlphaPoints < 3 || numBetaPoints < 3
            warning('Insufficient frequency resolution (alpha: %d pts, beta: %d pts)', ...
                    numAlphaPoints, numBetaPoints);
            continue;
        end
        
        % Validate PSD values
        if any(mean_psd(idx_alpha) <= 0) || any(mean_psd(idx_beta) <= 0)
            warning('Non-positive PSD values detected');
            continue;
        end
        
        % Power features
        alpha_power = mean(mean_psd(idx_alpha));
        beta_power  = mean(mean_psd(idx_beta));
        
        % Spectral slope features (in log-log space)
        p_alpha = polyfit(log10(f(idx_alpha)), log10(mean_psd(idx_alpha)), 1);
        alpha_slope = p_alpha(1);
        
        p_beta = polyfit(log10(f(idx_beta)), log10(mean_psd(idx_beta)), 1);
        beta_slope = p_beta(1);
        
        featureVec = [alpha_power, beta_power, alpha_slope, beta_slope];
        
        % Final validation
        if any(isnan(featureVec)) || any(isinf(featureVec))
            warning('Invalid features: [%.4f, %.4f, %.4f, %.4f]', featureVec);
            continue;
        end
        
        % Store features
        dataSummary = [dataSummary; featureVec];
        labelSummary = [labelSummary; g-1];
        
        fprintf('  ✓ Features: α_pwr=%.2e, β_pwr=%.2e, α_slope=%.2f, β_slope=%.2f\n', ...
                featureVec(1), featureVec(2), featureVec(3), featureVec(4));
    end
end

%% ==========================
%  Calculate Group-Level PSD Statistics (with SEM and Log Transform)
%  ==========================
fprintf('\n=== Group-Level PSD Statistics ===\n');

if ~isempty(group_psd_storage.non_epilepsy)
    % Linear scale statistics
    mean_psd_non_epilepsy = mean(group_psd_storage.non_epilepsy, 2);
    median_psd_non_epilepsy = median(group_psd_storage.non_epilepsy, 2);
    std_psd_non_epilepsy = std(group_psd_storage.non_epilepsy, 0, 2);
    n_non = size(group_psd_storage.non_epilepsy, 2);
    sem_psd_non_epilepsy = std_psd_non_epilepsy / sqrt(n_non);  % Calculate SEM
    
    % Log-transformed statistics
    log_psd_non = log10(group_psd_storage.non_epilepsy);
    mean_log_psd_non_epilepsy = mean(log_psd_non, 2);
    median_log_psd_non_epilepsy = median(log_psd_non, 2);
    std_log_psd_non_epilepsy = std(log_psd_non, 0, 2);
    sem_log_psd_non_epilepsy = std_log_psd_non_epilepsy / sqrt(n_non);  % Calculate SEM for log
    
    fprintf('Non-Epilepsy Group:\n');
    fprintf('  Number of patients: %d\n', n_non);
    fprintf('  Mean PSD size: %d frequency points\n', length(mean_psd_non_epilepsy));
else
    mean_psd_non_epilepsy = [];
    sem_psd_non_epilepsy = [];
    mean_log_psd_non_epilepsy = [];
    sem_log_psd_non_epilepsy = [];
    n_non = 0;
    fprintf('Non-Epilepsy Group: No valid data\n');
end

if ~isempty(group_psd_storage.epilepsy)
    % Linear scale statistics
    mean_psd_epilepsy = mean(group_psd_storage.epilepsy, 2);
    median_psd_epilepsy = median(group_psd_storage.epilepsy, 2);
    std_psd_epilepsy = std(group_psd_storage.epilepsy, 0, 2);
    n_epi = size(group_psd_storage.epilepsy, 2);
    sem_psd_epilepsy = std_psd_epilepsy / sqrt(n_epi);  % Calculate SEM
    
    % Log-transformed statistics
    log_psd_epi = log10(group_psd_storage.epilepsy);
    mean_log_psd_epilepsy = mean(log_psd_epi, 2);
    median_log_psd_epilepsy = median(log_psd_epi, 2);
    std_log_psd_epilepsy = std(log_psd_epi, 0, 2);
    sem_log_psd_epilepsy = std_log_psd_epilepsy / sqrt(n_epi);  % Calculate SEM for log
    
    fprintf('Epilepsy Group:\n');
    fprintf('  Number of patients: %d\n', n_epi);
    fprintf('  Mean PSD size: %d frequency points\n', length(mean_psd_epilepsy));
else
    mean_psd_epilepsy = [];
    sem_psd_epilepsy = [];
    mean_log_psd_epilepsy = [];
    sem_log_psd_epilepsy = [];
    n_epi = 0;
    fprintf('Epilepsy Group: No valid data\n');
end

%% ==========================
%  Save Results
%  ==========================
fprintf('\n=== Processing Summary ===\n');
fprintf('Total samples processed: %d\n', size(dataSummary, 1));
fprintf('  Non-epilepsy: %d\n', sum(labelSummary == 0));
fprintf('  Epilepsy: %d\n', sum(labelSummary == 1));

if isempty(dataSummary)
    error('No valid data processed. Please check file paths and data format.');
end

featureLabels = {'alpha_power','beta_power','alpha_slope','beta_slope'};

% Save with group-level PSD (including SEM and log-transformed data)
save('summary_psd_features.mat', 'dataSummary', 'labelSummary', 'featureLabels', ...
     'mean_psd_non_epilepsy', 'median_psd_non_epilepsy', 'std_psd_non_epilepsy', 'sem_psd_non_epilepsy', ...
     'mean_psd_epilepsy', 'median_psd_epilepsy', 'std_psd_epilepsy', 'sem_psd_epilepsy', ...
     'mean_log_psd_non_epilepsy', 'sem_log_psd_non_epilepsy', ...
     'mean_log_psd_epilepsy', 'sem_log_psd_epilepsy', 'f', 'n_non', 'n_epi');

fprintf('\n✅ Saved: summary_psd_features.mat\n');
fprintf('   - Individual features: dataSummary, labelSummary\n');
fprintf('   - Group mean PSD: mean_psd_non_epilepsy, mean_psd_epilepsy\n');
fprintf('   - Group SEM: sem_psd_non_epilepsy, sem_psd_epilepsy\n');
fprintf('   - Log-transformed mean PSD: mean_log_psd_non_epilepsy, mean_log_psd_epilepsy\n');
fprintf('   - Log-transformed SEM: sem_log_psd_non_epilepsy, sem_log_psd_epilepsy\n');
fprintf('   - Frequency vector: f\n');

%% ==========================
%  Visualization & Statistics
%  ==========================
groupNames = {'non_epilepsy','epilepsy'};
groupCats = categorical(labelSummary, [0 1], groupNames);
numFeatures = size(dataSummary, 2);

% Figure 1: Feature Comparison
figure('Name','PSD-based EEG Features','Position',[100 100 1200 700]);
colors = [0.2 0.4 0.8; 0.9 0.3 0.3]; % Blue, Red

for iFeature = 1:numFeatures
    subplot(2, 2, iFeature);
    hold on;
    
    % Bar plot of medians
    medians = grpstats(dataSummary(:, iFeature), groupCats, 'median');
    b = bar(1:length(groupNames), medians, 'FaceAlpha', 0.4, 'EdgeColor', 'none');
    
    % Scatter individual points with jitter
    for k = 1:length(groupNames)
        idx = groupCats == groupNames{k};
        groupData = dataSummary(idx, iFeature);
        xJitter = (rand(sum(idx), 1) - 0.5) * 0.15 + k;
        scatter(xJitter, groupData, 40, colors(k, :), 'filled', 'MarkerFaceAlpha', 0.6);
    end
    
    % Statistical test
    group1_data = dataSummary(groupCats == groupNames{1}, iFeature);
    group2_data = dataSummary(groupCats == groupNames{2}, iFeature);
    
    if length(group1_data) >= 3 && length(group2_data) >= 3
        pval = ranksum(group1_data, group2_data);
        
        % Significance markers
        if pval < 0.001
            sigStr = '***';
        elseif pval < 0.01
            sigStr = '**';
        elseif pval < 0.05
            sigStr = '*';
        else
            sigStr = 'ns';
        end
        
        title(sprintf('%s (p=%.4f) %s', featureLabels{iFeature}, pval, sigStr), ...
              'FontWeight', 'bold', 'Interpreter', 'none');
    else
        title(featureLabels{iFeature}, 'FontWeight', 'bold', 'Interpreter', 'none');
    end
    
    xticks(1:length(groupNames));
    xticklabels(groupNames);
    ylabel(featureLabels{iFeature}, 'Interpreter', 'none');
    grid on;
    legend(groupNames, 'Location', 'best');
    hold off;
end

sgtitle('Comparison of EEG PSD Features Between Groups', 'FontSize', 14, 'FontWeight', 'bold');
% === Limit frequency range to 1–40 Hz ===
freq_mask = f >= 1 & f <= 40;
f = f(freq_mask);

% Linear scale data
mean_psd_non_epilepsy = mean_psd_non_epilepsy(freq_mask);
mean_psd_epilepsy = mean_psd_epilepsy(freq_mask);
sem_psd_non_epilepsy = sem_psd_non_epilepsy(freq_mask);
sem_psd_epilepsy = sem_psd_epilepsy(freq_mask);
median_psd_non_epilepsy = median_psd_non_epilepsy(freq_mask);
median_psd_epilepsy = median_psd_epilepsy(freq_mask);

% Log scale data
mean_log_psd_non_epilepsy = mean_log_psd_non_epilepsy(freq_mask);
mean_log_psd_epilepsy = mean_log_psd_epilepsy(freq_mask);
sem_log_psd_non_epilepsy = sem_log_psd_non_epilepsy(freq_mask);
sem_log_psd_epilepsy = sem_log_psd_epilepsy(freq_mask);
median_log_psd_non_epilepsy = median_log_psd_non_epilepsy(freq_mask);
median_log_psd_epilepsy = median_log_psd_epilepsy(freq_mask);

%% Figure 2: Group-Level PSD with SEM (Linear Scale)
if ~isempty(mean_psd_non_epilepsy) && ~isempty(mean_psd_epilepsy)
    figure('Name', 'Group-Level PSD Comparison (Linear)', 'Position', [150 150 1400 600]);
    
    % Plot 1: Mean PSD with SEM (Linear)
    subplot(1, 2, 1);
    hold on;
    plot(f, mean_psd_non_epilepsy, 'LineWidth', 2, 'Color', colors(1,:), 'DisplayName', 'Non-Epilepsy (Mean)');
    plot(f, mean_psd_epilepsy, 'LineWidth', 2, 'Color', colors(2,:), 'DisplayName', 'Epilepsy (Mean)');
    
    % Add SEM bands
    fill([f; flipud(f)], [mean_psd_non_epilepsy + sem_psd_non_epilepsy; flipud(mean_psd_non_epilepsy - sem_psd_non_epilepsy)], ...
         colors(1,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill([f; flipud(f)], [mean_psd_epilepsy + sem_psd_epilepsy; flipud(mean_psd_epilepsy - sem_psd_epilepsy)], ...
         colors(2,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    hold off;
    xlabel('Frequency (Hz)');
    ylabel('Mean PSD (μV²/Hz)');
    title(sprintf('Group-Level Mean PSD with SEM (n=%d, %d)', n_non, n_epi), 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([1 40]);

    
    % Plot 2: Median PSD
    subplot(1, 2, 2);
    hold on;
    plot(f, median_psd_non_epilepsy, 'LineWidth', 2, 'Color', colors(1,:), 'DisplayName', 'Non-Epilepsy (Median)');
    plot(f, median_psd_epilepsy, 'LineWidth', 2, 'Color', colors(2,:), 'DisplayName', 'Epilepsy (Median)');
    hold off;
    xlabel('Frequency (Hz)');
    ylabel('Median PSD (μV²/Hz)');
    title('Group-Level Median PSD', 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([1 40]);

    
    sgtitle('Group-Level PSD: Non-Epilepsy vs Epilepsy (Linear Scale)', 'FontSize', 14, 'FontWeight', 'bold');
end

%% Figure 3: Group-Level Log-Transformed PSD with SEM
if ~isempty(mean_log_psd_non_epilepsy) && ~isempty(mean_log_psd_epilepsy)
    figure('Name', 'Group-Level PSD Comparison (Log Scale)', 'Position', [200 200 1400 600]);
    
    % Plot 1: Mean Log-PSD with SEM
    subplot(1, 2, 1);
    hold on;
    plot(f, mean_log_psd_non_epilepsy, 'LineWidth', 2, 'Color', colors(1,:), 'DisplayName', 'Non-Epilepsy (Mean)');
    plot(f, mean_log_psd_epilepsy, 'LineWidth', 2, 'Color', colors(2,:), 'DisplayName', 'Epilepsy (Mean)');
    
    % Add SEM bands for log-transformed data
    fill([f; flipud(f)], [mean_log_psd_non_epilepsy + sem_log_psd_non_epilepsy; flipud(mean_log_psd_non_epilepsy - sem_log_psd_non_epilepsy)], ...
         colors(1,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill([f; flipud(f)], [mean_log_psd_epilepsy + sem_log_psd_epilepsy; flipud(mean_log_psd_epilepsy - sem_log_psd_epilepsy)], ...
         colors(2,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    hold off;
    xlabel('Frequency (Hz)');
    ylabel('Mean Log₁₀(PSD) [log(μV²/Hz)]');
    title(sprintf('Log-Transformed Mean PSD with SEM (n=%d, %d)', n_non, n_epi), 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([1 40]);

    
    % Plot 2: Median Log-PSD
    subplot(1, 2, 2);
    hold on;
    plot(f, median_log_psd_non_epilepsy, 'LineWidth', 2, 'Color', colors(1,:), 'DisplayName', 'Non-Epilepsy (Median)');
    plot(f, median_log_psd_epilepsy, 'LineWidth', 2, 'Color', colors(2,:), 'DisplayName', 'Epilepsy (Median)');
    hold off;
    xlabel('Frequency (Hz)');
    ylabel('Median Log₁₀(PSD) [log(μV²/Hz)]');
    title('Log-Transformed Median PSD', 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([1 40]);

    
    sgtitle('Group-Level PSD: Non-Epilepsy vs Epilepsy (Log Scale)', 'FontSize', 14, 'FontWeight', 'bold');
end

%% ==========================
%  Statistical Summary Table
%  ==========================
fprintf('\n=== Statistical Summary ===\n');
for iFeature = 1:numFeatures
    fprintf('\n%s:\n', featureLabels{iFeature});
    
    g1 = dataSummary(groupCats == groupNames{1}, iFeature);
    g2 = dataSummary(groupCats == groupNames{2}, iFeature);
    
    fprintf('  %s: median=%.4e, mean=%.4e, std=%.4e (n=%d)\n', ...
            groupNames{1}, median(g1), mean(g1), std(g1), length(g1));
    fprintf('  %s: median=%.4e, mean=%.4e, std=%.4e (n=%d)\n', ...
            groupNames{2}, median(g2), mean(g2), std(g2), length(g2));
    
    if length(g1) >= 3 && length(g2) >= 3
        pval = ranksum(g1, g2);
        fprintf('  Wilcoxon rank-sum p-value = %.4f\n', pval);
    end
end

fprintf('\n✅ Analysis complete!\n');