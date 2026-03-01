function [processed_data, fs, channel_labels] = edf_to_mat(filename)
    % Main function to process EDF file into MAT format through multiple steps
    % Input: filename - path to the EDF file
    % Output: processed_data - the fully processed EEG data
    %         fs - sampling frequency
    %         channel_labels - names of the channels
    
    % Check GPU availability and initialize
    if gpuDeviceCount > 0
        gpu_device = gpuDevice();
        fprintf('Using GPU: %s\n', gpu_device.Name);
    else
        warning('No GPU detected. Using CPU processing.');
    end
    
    % Step 1: Load EEG data
    [data_numeric, fs, channel_labels] = load_eeg_data(filename);
    
    % Step 2: Remove flat and highly correlated channels
    [data_numeric, channel_labels] = remove_bad_channels(data_numeric, channel_labels);
    
    % Step 3: Bandpass filtering (1-40 Hz)
    filtered_data = apply_bandpass_filter(data_numeric, fs);
    
    % Step 4: Common Average Referencing (CAR)
    car_data = apply_car(filtered_data);
    
    % Step 5: Principal Component Analysis (PCA)
    pca_data = apply_pca(car_data, fs);
    
    % Step 6: ICA with Automated Artifact Removal
    ica_data = apply_ica_artifact_removal(pca_data, fs);
    
    % Step 7: Final Processing
    processed_data = final_processing(ica_data);
end

function [data_numeric, fs, channel_labels] = load_eeg_data(filename)
    % Step 1: Load EEG data from EDF file
    % Input: filename - path to the EDF file
    % Output: data_numeric - numeric matrix of EEG data (time x channels)
    %         fs - sampling frequency in Hz
    %         channel_labels - cell array of channel names
    
    % Read EDF header
    edfHeader = edfinfo(filename);
    
    % Read raw EDF data
    [data, ~] = edfread(filename);
    
    % Extract sampling rate
    fs = edfHeader.NumSamples(1) / seconds(edfHeader.DataRecordDuration);
    
    % Preallocate temporary storage
    numVariables = width(data);
    tempData = cell(1, numVariables);
    tempLabels = cell(1, numVariables);
    validChannelCount = 0;
    
    % First pass - identify valid channels and their sizes
    for i = 1:numVariables
        var_name = data.Properties.VariableNames{i};
        var_data = data{:, i};
        
        % Skip problematic variables
        if any(strcmp(var_name, {'IBI', 'BURSTS', 'SUPPR'}))
            continue;
        end
        
        % Process cell arrays
        if iscell(var_data)
            try
                numeric_data = cellfun(@(x) double(x), var_data, 'UniformOutput', false);
                numeric_data = cell2mat(numeric_data);
            catch
                continue;
            end
        elseif isnumeric(var_data)
            numeric_data = var_data;
        else
            continue;
        end
        
        % Store valid data in temporary storage
        validChannelCount = validChannelCount + 1;
        tempData{validChannelCount} = numeric_data;
        tempLabels{validChannelCount} = var_name;
    end
    
    % Trim unused cells
    tempData = tempData(1:validChannelCount);
    tempLabels = tempLabels(1:validChannelCount);
    
    % Check if we have any valid data
    if validChannelCount == 0
        error('No valid numeric EEG channels found in the file. Check the file format.');
    end
    
    % Check data dimensions
    numRows = size(tempData{1}, 1);
    
    % Identify which channels have the correct dimensions
    validIndices = ones(1, validChannelCount);
    for i = 1:validChannelCount
        if size(tempData{i}, 1) ~= numRows
            validIndices(i) = 0;
        end
    end
    
    % Find valid indices
    validIndices = logical(validIndices);
    finalChannelCount = sum(validIndices);
    
    % Preallocate final data matrix with the correct size
    if finalChannelCount > 0
        data_numeric = zeros(numRows, finalChannelCount);
        channel_labels = cell(1, finalChannelCount);
        
        % Fill the preallocated matrix
        validIdx = 1;
        for i = 1:validChannelCount
            if validIndices(i)
                data_numeric(:, validIdx) = tempData{i};
                channel_labels{validIdx} = tempLabels{i};
                validIdx = validIdx + 1;
            end
        end
    else
        error('No channels with consistent dimensions found in the file.');
    end
end

function [clean_data, clean_labels] = remove_bad_channels(data_numeric, channel_labels)
    % Step 2: Remove flat and highly correlated channels (GPU-accelerated)
    % Input: data_numeric - numeric matrix of EEG data (time x channels)
    %        channel_labels - cell array of channel names
    % Output: clean_data - data with bad channels removed
    %         clean_labels - updated channel labels
    
    % Move data to GPU if available
    if gpuDeviceCount > 0
        data_gpu = gpuArray(data_numeric);
    else
        data_gpu = data_numeric;
    end
    
    % Remove flat (zero-variance) channels using GPU
    channel_variance = var(data_gpu, 0, 1);
    flat_channels = find(gather(channel_variance) < 1e-6);
    if ~isempty(flat_channels)
        data_gpu(:, flat_channels) = [];
        channel_labels(flat_channels) = [];
    end
    
    % Update number of channels after removal
    num_channels = size(data_gpu, 2);
    
    % Compute correlation matrix on GPU
    corr_matrix = corrcoef(data_gpu);
    
    % Identify highly correlated channels (threshold: 0.95)
    upper_tri = triu(corr_matrix, 1);
    [~, high_corr_cols] = find(abs(gather(upper_tri)) > 0.95);
    high_corr_channels = unique(high_corr_cols);
    
    if ~isempty(high_corr_channels)
        data_gpu(:, high_corr_channels) = [];
        channel_labels(high_corr_channels) = [];
    end
    
    % Return data to CPU
    clean_data = gather(data_gpu);
    clean_labels = channel_labels;
end

function filtered_data = apply_bandpass_filter(data_numeric, fs)
    % Step 3: Apply bandpass filter (1-40 Hz) with GPU acceleration
    % Input: data_numeric - numeric matrix of EEG data (time x channels)
    %        fs - sampling frequency in Hz
    % Output: filtered_data - bandpass filtered data
    
    % Define filter parameters
    low_cutoff = 1;
    high_cutoff = 40;
    
    % Check if Nyquist criterion is met
    if fs > 2*high_cutoff
        % Create bandpass filter
        [b, a] = butter(4, [low_cutoff, high_cutoff] / (fs / 2), 'bandpass');
        
        % Move data to GPU if available
        if gpuDeviceCount > 0
            data_gpu = gpuArray(data_numeric);
            filtered_data_gpu = zeros(size(data_gpu), 'like', data_gpu);
            
            % Filter each channel separately on GPU
            for ch = 1:size(data_gpu, 2)
                filtered_data_gpu(:, ch) = filtfilt(b, a, data_gpu(:, ch));
            end
            
            % Return filtered data to CPU
            filtered_data = gather(filtered_data_gpu);
        else
            % CPU fallback
            filtered_data = zeros(size(data_numeric));
            for ch = 1:size(data_numeric, 2)
                filtered_data(:, ch) = filtfilt(b, a, data_numeric(:, ch));
            end
        end
    else
        error('Sampling rate (fs) is too low for the specified high cutoff frequency. Check EDF file.');
    end
end

function car_data = apply_car(filtered_data)
    % Step 4: Apply Common Average Reference (CAR) with GPU acceleration
    % Input: filtered_data - bandpass filtered EEG data (time x channels)
    % Output: car_data - data after common average referencing
    
    % Move data to GPU if available
    if gpuDeviceCount > 0
        filtered_data_gpu = gpuArray(filtered_data);
        
        % Calculate the common average reference on GPU
        car_reference = mean(filtered_data_gpu, 2);
        
        % Subtract the reference from each channel
        car_data_gpu = filtered_data_gpu - repmat(car_reference, 1, size(filtered_data_gpu, 2));
        
        % Return data to CPU
        car_data = gather(car_data_gpu);
    else
        % CPU fallback
        car_reference = mean(filtered_data, 2);
        car_data = filtered_data - repmat(car_reference, 1, size(filtered_data, 2));
    end
end

function pca_data = apply_pca(car_data, fs)
    % Step 5: Apply Principal Component Analysis (PCA) with GPU acceleration
    % Input: car_data - EEG data after CAR (time x channels)
    %        fs - sampling frequency in Hz
    % Output: pca_data - structure containing PCA results needed for ICA
    
    % Move data to GPU if available
    if gpuDeviceCount > 0
        car_data_gpu = gpuArray(car_data);
        
        % Standardize data before PCA on GPU
        standardized_data_gpu = (car_data_gpu - mean(car_data_gpu)) ./ std(car_data_gpu);
        standardized_data = gather(standardized_data_gpu);
    else
        % CPU fallback
        standardized_data = zscore(car_data);
    end
    
    data_rank = rank(standardized_data);
    
    % Handle low rank data
    if data_rank < 5
        % Check for extreme scaling issues
        channel_ranges = max(car_data) - min(car_data);
        
        % Try simple high-pass filter to remove baseline drift which might cause correlation
        if any(channel_ranges < 1e-6)
            [b, a] = butter(2, 1/(fs/2), 'high');
            
            if gpuDeviceCount > 0
                car_data_gpu = gpuArray(car_data);
                car_data_filtered_gpu = zeros(size(car_data_gpu), 'like', car_data_gpu);
                for ch = 1:size(car_data_gpu, 2)
                    car_data_filtered_gpu(:, ch) = filtfilt(b, a, car_data_gpu(:, ch));
                end
                car_data_filtered = gather(car_data_filtered_gpu);
                standardized_data = zscore(car_data_filtered);
            else
                car_data_filtered = zeros(size(car_data));
                for ch = 1:size(car_data, 2)
                    car_data_filtered(:, ch) = filtfilt(b, a, car_data(:, ch));
                end
                standardized_data = zscore(car_data_filtered);
            end
            
            % Check rank again
            data_rank_after = rank(standardized_data);
            
            if data_rank_after > data_rank
                car_data = car_data_filtered;
                data_rank = data_rank_after;
            end
        end
    end

    % Perform PCA (PCA computation stays on CPU as it's already optimized)
    [coeff, score, ~, ~, explained] = pca(standardized_data);

    % Use minimum of (data_rank-1) or 20 components
    num_pca_components = min(data_rank-1, 20);

    % Ensure we have at least 4 components for ICA
    num_pca_components = max(num_pca_components, 4);

    % Prepare data for ICA
    reduced_data = score(:, 1:num_pca_components);  % Timepoints x Components
    
    % Create a structure containing all required outputs for ICA
    pca_data = struct();
    pca_data.reduced_data = reduced_data;
    pca_data.coeff = coeff;
    pca_data.num_pca_components = num_pca_components;
    pca_data.orig_data = car_data;
    pca_data.mean_data = mean(car_data);
    pca_data.std_data = std(car_data);
end

function ica_data = apply_ica_artifact_removal(pca_data, fs)
    % Step 6: Apply ICA with Automated Artifact Removal (GPU-accelerated)
    % Input: pca_data - structure with PCA results
    %        fs - sampling frequency in Hz
    % Output: ica_data - Structure containing cleaned data and artifact info
    
    % Extract needed variables from PCA data structure
    reduced_data = pca_data.reduced_data;
    coeff = pca_data.coeff;
    num_pca_components = pca_data.num_pca_components;
    car_data = pca_data.orig_data;
    mean_car = pca_data.mean_data;
    std_car = pca_data.std_data;
    
    % Initialize output structure
    ica_data = struct();
    ica_data.original_data = car_data;
    
    % Try different ICA approaches with proper error handling
    try
        % Sample data if it's too large
        max_samples = 50000;
        if size(reduced_data, 1) > max_samples
            sample_indices = randsample(size(reduced_data, 1), max_samples);
            training_data = reduced_data(sample_indices, :);
        else
            training_data = reduced_data;
        end
        
        % Initialize variables for ICA
        icasig = [];
        A = [];
        W = [];
        is_artifact = [];
        artifact_types = {};
        
        % First try RICA
        try
            ricaObj = rica(training_data, num_pca_components);
            icasig = transform(ricaObj, reduced_data)';
            W = ricaObj.TransformWeights;
            A = pinv(W);
        catch
            % Alternative approach using fastica if available
            try
                [icasig, A, W] = fastica(reduced_data', 'numOfIC', num_pca_components, 'verbose', 'off');
            catch
                % Fallback to custom ICA implementation with GPU acceleration
                if gpuDeviceCount > 0
                    whitened_data_gpu = gpuArray(reduced_data);
                    n_components = num_pca_components;
                    
                    % Initialize unmixing matrix with random values on GPU
                    rng(42); % For reproducibility
                    W_gpu = gpuArray(randn(n_components, n_components));
                    
                    % Orthogonalize W on GPU
                    [U, ~, V] = svd(W_gpu);
                    W_gpu = U * V';
                    
                    % Container for ICA components on GPU
                    icasig_gpu = zeros(n_components, size(whitened_data_gpu, 1), 'like', whitened_data_gpu);
                    
                    % Extract components one by one
                    for comp = 1:n_components
                        w_gpu = W_gpu(comp, :)';
                        % Fixed-point iteration on GPU
                        for iter = 1:10
                            % Update rule for finding non-Gaussian projection
                            proj = whitened_data_gpu * w_gpu;
                            w_new_gpu = mean(whitened_data_gpu .* (proj.^3), 1)' - 3*w_gpu;
                            
                            % Orthogonalize against previous components
                            if comp > 1
                                w_new_gpu = w_new_gpu - W_gpu(1:comp-1, :)' * (W_gpu(1:comp-1, :) * w_new_gpu);
                            end
                            
                            % Normalize
                            w_gpu = w_new_gpu / norm(w_new_gpu);
                        end
                        
                        W_gpu(comp, :) = w_gpu';
                        icasig_gpu(comp, :) = w_gpu' * whitened_data_gpu';
                    end
                    
                    % Transfer results back to CPU
                    W = gather(W_gpu);
                    icasig = gather(icasig_gpu);
                    A = pinv(W);
                else
                    % CPU fallback
                    whitened_data = reduced_data;
                    n_components = num_pca_components;
                    
                    % Initialize unmixing matrix with random values
                    rng(42); % For reproducibility
                    W = randn(n_components, n_components);
                    W = orth(W);
                    
                    % Container for ICA components
                    icasig = zeros(n_components, size(whitened_data, 1));
                    
                    % Extract components one by one
                    for comp = 1:n_components
                        w = W(comp, :)';
                        % Fixed-point iteration
                        for iter = 1:10
                            % Update rule for finding non-Gaussian projection
                            w_new = mean(bsxfun(@times, whitened_data, (whitened_data * w).^3), 1)' - 3*w;
                            
                            % Orthogonalize against previous components
                            if comp > 1
                                w_new = w_new - W(1:comp-1, :)' * (W(1:comp-1, :) * w_new);
                            end
                            
                            % Normalize
                            w = w_new / norm(w_new);
                        end
                        
                        W(comp, :) = w';
                        icasig(comp, :) = w' * whitened_data';
                    end
                    
                    A = pinv(W);
                end
            end
        end
        
        num_ica_components = size(icasig, 1);
        
        % Automated artifact detection (GPU-accelerated where possible)
        is_artifact = false(1, num_ica_components);
        component_kurtosis = zeros(1, num_ica_components);
        artifact_types = cell(1, num_ica_components);
        
        % Move ICA signals to GPU for faster processing
        if gpuDeviceCount > 0
            icasig_gpu = gpuArray(icasig);
        else
            icasig_gpu = icasig;
        end
        
        for i = 1:num_ica_components
            % Get current component (on GPU if available)
            current_component = icasig_gpu(i, :);
            
            % Calculate power spectrum
            window_size = min(2048, floor(size(icasig, 2)/10));
            window_size = max(16, window_size);
            noverlap = floor(window_size/2);
            nfft = max(256, 2^nextpow2(window_size));
            
            % Move to CPU for pwelch (as it doesn't support GPU arrays directly)
            [pxx, f] = pwelch(gather(current_component), window_size, noverlap, nfft, fs);
            
            % Calculate kurtosis for all components on GPU
            try
                if gpuDeviceCount > 0
                    x_gpu = current_component - mean(current_component);
                    component_kurtosis(i) = gather(mean(x_gpu.^4) / (mean(x_gpu.^2)^2)) - 3;
                else
                    component_kurtosis(i) = kurtosis(icasig(i, :));
                end
            catch
                % Simple kurtosis calculation if built-in function not available
                x = gather(current_component);
                x = x - mean(x);
                component_kurtosis(i) = mean(x.^4) / (mean(x.^2)^2) - 3;
            end
            
            % 1. Eye blink detection
            low_freq_idx = f <= 5;
            low_freq_power = sum(pxx(low_freq_idx));
            total_power = sum(pxx);
            low_freq_ratio = low_freq_power / total_power;
            
            if low_freq_ratio > 0.6 && component_kurtosis(i) > 8
                is_artifact(i) = true;
                artifact_types{i} = 'Eye blink';
            end
            
            % 2. Muscle artifact detection
            high_freq_idx = f >= 20;
            high_freq_power = sum(pxx(high_freq_idx));
            high_freq_ratio = high_freq_power / total_power;
            
            if high_freq_ratio > 0.4
                is_artifact(i) = true;
                artifact_types{i} = 'Muscle';
            end
            
            % 3. Heart artifact detection
            heart_freq_idx = (f >= 0.8) & (f <= 2.5);
            heart_freq_power = sum(pxx(heart_freq_idx));
            
            try
                % Find peaks in the 0.8-2.5Hz range
                [peaks, ~] = findpeaks(pxx(heart_freq_idx), 'SortStr', 'descend');
                if ~isempty(peaks) && peaks(1) > 8*mean(pxx) && heart_freq_power / total_power > 0.3
                    % Check for rhythmic pattern using autocorrelation
                    current_seg = gather(current_component(1:min(fs*10, length(current_component))));
                    acf = xcorr(current_seg, 'coeff');
                    mid_point = ceil(length(acf)/2);
                    acf = acf(mid_point:end); % Take only positive lags
                    
                    % Find peaks in autocorrelation
                    [peaks_acf, ~] = findpeaks(acf(2:end)); % Skip zero lag
                    
                    if ~isempty(peaks_acf) && max(peaks_acf) > 0.5
                        is_artifact(i) = true;
                        artifact_types{i} = 'Heart';
                    end
                end
            catch
                % Simple alternative check
                if heart_freq_power / total_power > 0.5
                    is_artifact(i) = true;
                    artifact_types{i} = 'Heart';
                end
            end
            
            % 4. Line noise detection
            try
                line_freq_idx_50 = (f >= 49) & (f <= 51);
                line_freq_idx_60 = (f >= 59) & (f <= 61);
                
                if any(line_freq_idx_50) && any(line_freq_idx_60)
                    line_freq_power_50 = max(pxx(line_freq_idx_50));
                    line_freq_power_60 = max(pxx(line_freq_idx_60));
                    
                    surrounding_idx_50 = ((f >= 45) & (f < 49)) | ((f > 51) & (f <= 55));
                    surrounding_idx_60 = ((f >= 55) & (f < 59)) | ((f > 61) & (f <= 65));
                    
                    if any(surrounding_idx_50) && any(surrounding_idx_60)
                        surrounding_power_50 = mean(pxx(surrounding_idx_50));
                        surrounding_power_60 = mean(pxx(surrounding_idx_60));
                        
                        if (line_freq_power_50 > 10*surrounding_power_50) || (line_freq_power_60 > 10*surrounding_power_60)
                            is_artifact(i) = true;
                            artifact_types{i} = 'Line noise';
                        end
                    end
                end
            catch
                % Skip this detection if there's an error
            end
        end
        
        % Get bad components
        bad_components = find(is_artifact);
        
        % Safety check - don't remove too many components (max 30%)
        if length(bad_components) > ceil(num_ica_components * 0.3)
            % Keep only the components with highest kurtosis
            [~, sorted_idx] = sort(component_kurtosis(bad_components), 'descend');
            bad_components = bad_components(sorted_idx(1:ceil(num_ica_components * 0.3)));
            is_artifact = false(1, num_ica_components);
            is_artifact(bad_components) = true;
            
            % Update artifact types
            temp_types = artifact_types;
            artifact_types = cell(1, num_ica_components);
            for i = 1:length(bad_components)
                artifact_types{bad_components(i)} = temp_types{bad_components(i)};
            end
        end
        
        if isempty(bad_components)
            % Find the component with highest kurtosis, often associated with eye blinks
            [max_kurt, max_idx] = max(component_kurtosis);
            
            % Only mark as artifact if kurtosis is very high
            if max_kurt > 15
                bad_components = max_idx;
                is_artifact(max_idx) = true;
                artifact_types{max_idx} = 'Suspected eye blink (high kurtosis)';
            end
        end
        
        % Remove artifacts by zeroing out the selected components (GPU-accelerated)
        if gpuDeviceCount > 0
            icasig_clean_gpu = icasig_gpu;
            if ~isempty(bad_components)
                icasig_clean_gpu(bad_components, :) = 0;
            end
            icasig_clean = gather(icasig_clean_gpu);
        else
            icasig_clean = icasig;
            if ~isempty(bad_components)
                icasig_clean(bad_components, :) = 0;
            end
        end
        
        % Back-project the ICA components to the channel space (GPU-accelerated)
        if gpuDeviceCount > 0
            W_gpu = gpuArray(W);
            coeff_gpu = gpuArray(coeff);
            mean_car_gpu = gpuArray(mean_car);
            std_car_gpu = gpuArray(std_car);
            
            % Reconstruct data from ICA components
            reduced_data_clean_gpu = icasig_clean_gpu' * W_gpu;  % Use mixing matrix to get back to PCA space
            
            % Back to original data space from PCA
            reconstructed_data_gpu = reduced_data_clean_gpu * coeff_gpu(:, 1:num_pca_components)';
            
            % Un-standardize the data (reverse the zscore operation)
            cleaned_data_gpu = reconstructed_data_gpu .* std_car_gpu + mean_car_gpu;
            
            % Return to CPU
            cleaned_data = gather(cleaned_data_gpu);
        else
            % CPU fallback
            % Reconstruct data from ICA components
            reduced_data_clean = icasig_clean' * W;  % Use mixing matrix to get back to PCA space
            
            % Back to original data space from PCA
            reconstructed_data = reduced_data_clean * coeff(:, 1:num_pca_components)';
            
            % Un-standardize the data (reverse the zscore operation)
            cleaned_data = bsxfun(@plus, bsxfun(@times, reconstructed_data, std_car), mean_car);
        end
        
        % Store results in output structure
        ica_data.cleaned_data = cleaned_data;
        ica_data.W = W;
        ica_data.A = A;
        ica_data.icasig = icasig;
        ica_data.icasig_clean = icasig_clean;
        ica_data.artifact_components = bad_components;
        ica_data.artifact_types = artifact_types;
        ica_data.pca = struct('coeff', coeff, 'score', reduced_data, 'explained', []);
        ica_data.preprocessing_info = struct('reference', 'CAR', 'filter', struct('highpass', 1, 'lowpass', 40));
        ica_data.fs = fs;
        
    catch
        % If ICA fails, return the original data
        ica_data.cleaned_data = car_data;
        ica_data.W = [];
        ica_data.A = [];
        ica_data.icasig = [];
        ica_data.icasig_clean = [];
        ica_data.artifact_components = [];
        ica_data.artifact_types = {};
        ica_data.pca = struct('coeff', [], 'score', [], 'explained', []);
        ica_data.preprocessing_info = struct('reference', 'CAR', 'filter', struct('highpass', 1, 'lowpass', 40));
        ica_data.fs = fs;
    end
end

function processed_data = final_processing(ica_data)
    % Step 7: Final processing and data extraction
    % Input: ica_data - Structure containing ICA results and cleaned data
    % Output: processed_data - Final cleaned EEG data
    
    % If ICA was successful, use the cleaned data
    if isfield(ica_data, 'cleaned_data') && ~isempty(ica_data.cleaned_data)
        processed_data = ica_data.cleaned_data;
    else
        % Otherwise use the original data
        processed_data = ica_data.original_data;
    end
end

% % Example Usage
% filename = 'C:\Capstone\aaaaaanr\s001_2003\02_tcp_le\aaaaaanr_s001_t001.edf';
% filename= 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset\00_half_2\aaaaabju\s001_2003\02_tcp_le\aaaaabju_s001_t000.edf';
% [processed_data, fs, channel_labels] = edf_to_mat(filename);
% 
% % Save the results to a .mat file
% [filepath, name, ~] = fileparts(filename);
% output_filename = fullfile(filepath, [name '_processed.mat']);
% save(output_filename, 'processed_data', 'fs', 'channel_labels', '-v7.3');

% Base dataset directory
base_folder = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset\01_no_epilepsy_to_run';  % Replace with your actual base directory
% Recursively find all .edf files

% Recursively find all .edf files
edf_files = dir(fullfile(base_folder, '**', '*.edf'));
% Loop through each .edf file
for k = 1:length(edf_files)
    try
        % Full path to the .edf file
        filename = fullfile(edf_files(k).folder, edf_files(k).name);

        % Run your processing function
        [processed_data, fs, channel_labels] = edf_to_mat(filename);

        % Create the output filename in the same folder
        [~, name, ~] = fileparts(filename);
        output_filename = fullfile(edf_files(k).folder, [name '_processed.mat']);

        % Save the result
        save(output_filename, 'processed_data', 'fs', 'channel_labels', '-v7.3');

        fprintf('Successfully processed and saved: %s\n', output_filename);

    catch ME
        fprintf('Error processing %s: %s\n', filename, ME.message);
    end
end
