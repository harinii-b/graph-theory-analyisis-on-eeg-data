%% run_eeg_feature_pipeline_select22.m
% EEG Feature Extraction Pipeline - strict output.bipolar_data check
% - For each patient pick ONE session that contains output.bipolar_data sized 22 x N
% - If none found, patient is recorded in omitted_patients.txt
% - Minimal guessing: we require output.bipolar_data to exist and be 22 x samples (channels x time)
% - Later we transpose to samples x channels for processing (samples x 22)

clear; clc; close all;

%% ========== GPU SETUP ==========
if gpuDeviceCount > 0
    g = gpuDevice;
    fprintf('Using GPU: %s (Total Memory: %.1f GB)\n', g.Name, g.TotalMemory/1024^3);
else
    warning('No compatible NVIDIA GPU detected. Will run CPU-only where needed.');
    g = [];
end

%% USER INPUT - CHANGE THIS PATH as needed
base_folder = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz';

fprintf('=== EEG Feature Extraction Pipeline (strict output.bipolar_data check) ===\n');
fprintf('Base folder: %s\n', base_folder);

%% Frequency bands
freq_bands = struct();
freq_bands.delta = [0.5, 4];
freq_bands.theta = [4, 8];
freq_bands.alpha = [8, 13];
freq_bands.beta  = [13, 30];
freq_bands.gamma = [30, 100];
band_names = fieldnames(freq_bands);
n_bands = length(band_names);

% %% Find patient subfolders (assumes each patient in a folder directly under base_folder)
% patient_dirs = dir(base_folder);
% patient_dirs = patient_dirs([patient_dirs.isdir] & ~ismember({patient_dirs.name}, {'.','..'}));
%% Find patient subfolders (in epilepsy and non_epilepsy subdirectories)
epilepsy_folder = fullfile(base_folder, 'epilepsy');
non_epilepsy_folder = fullfile(base_folder, 'non_epilepsy');

patient_dirs = [];

% Get patients from epilepsy folder
if exist(epilepsy_folder, 'dir')
    epilepsy_patients = dir(epilepsy_folder);
    epilepsy_patients = epilepsy_patients([epilepsy_patients.isdir] & ~ismember({epilepsy_patients.name}, {'.','..'}));
    % Add full path to each
    for i = 1:length(epilepsy_patients)
        epilepsy_patients(i).folder = epilepsy_folder;
    end
    patient_dirs = [patient_dirs; epilepsy_patients];
end

% Get patients from non_epilepsy folder
if exist(non_epilepsy_folder, 'dir')
    non_epilepsy_patients = dir(non_epilepsy_folder);
    non_epilepsy_patients = non_epilepsy_patients([non_epilepsy_patients.isdir] & ~ismember({non_epilepsy_patients.name}, {'.','..'}));
    % Add full path to each
    for i = 1:length(non_epilepsy_patients)
        non_epilepsy_patients(i).folder = non_epilepsy_folder;
    end
    patient_dirs = [patient_dirs; non_epilepsy_patients];
end

if isempty(patient_dirs)
    error('No patient folders found in epilepsy or non_epilepsy subdirectories');
end

fprintf('Found %d patients total (%d epilepsy, %d non-epilepsy)\n', ...
    length(patient_dirs), length(epilepsy_patients), length(non_epilepsy_patients));

omitted_list = {};
processed_count = 0;

% Ensure parallel pool (used for CPU-bound tasks)
if isempty(gcp('nocreate'))
    try
        parpool('local');
    catch
        warning('Could not start parpool - continuing without parallel workers.');
    end
end

for p = 1:length(patient_dirs)
    patient_name = patient_dirs(p).name;
    patient_path = fullfile(patient_dirs(p).folder, patient_name);  % Use the stored folder path
    fprintf('\n--- Patient: %s ---\n', patient_name);
    
    % Rest of your code...

    % find processed mat files for this patient (pattern you used)
    mat_files = dir(fullfile(patient_path, '**', '*_processed_bipolar.mat'));
    if isempty(mat_files)
        fprintf(' No *_processed_bipolar.mat files for %s. Skipping.\n', patient_name);
        omitted_list{end+1,1} = patient_name; %#ok<SAGROW>
        continue;
    end

    % Strict check: prefer file where s.output.bipolar_data exists and is [22 x N]
    selected_file = '';
    selected_samples = 0;
    for k = 1:length(mat_files)
        try
            s = load(fullfile(mat_files(k).folder, mat_files(k).name));
            if isfield(s, 'output') && isfield(s.output, 'bipolar_data')
                bd = s.output.bipolar_data;
                if isnumeric(bd) && ismatrix(bd) && size(bd,1) == 22 && size(bd,2) >= 1
                    % pick the longest such file (most samples)
                    n_samples = size(bd,2);
                    if n_samples > selected_samples
                        selected_samples = n_samples;
                        selected_file = fullfile(mat_files(k).folder, mat_files(k).name);
                    end
                end
            end
        catch
            % ignore bad file
            continue;
        end
    end

    if isempty(selected_file)
        fprintf(' No sessions with output.bipolar_data sized 22 x N for %s. Will omit.\n', patient_name);
        omitted_list{end+1,1} = patient_name; %#ok<SAGROW>
        continue;
    end

    fprintf(' Selected session: %s (output.bipolar_data is 22 x %d)\n', selected_file, selected_samples);

    % Now process the selected file
    try
        tic;
        s = load(selected_file); % load into struct 's'
        if isfield(s, 'output')
            data_struct = s.output;
        else
            error('Selected file does not contain output struct (unexpected).');
        end

        % --- Strict: use bipolar_data from output (must be 22 x samples) ---
        if isfield(data_struct, 'bipolar_data') && isnumeric(data_struct.bipolar_data)
            bipolar_data = data_struct.bipolar_data; % channels x samples (22 x N)
        else
            error('output.bipolar_data missing or not numeric in %s', selected_file);
        end

        % --- sampling frequency ---
        if isfield(data_struct, 'fs') && ~isempty(data_struct.fs)
            fs = data_struct.fs;
        else
            fs = 250; % default fallback
        end

        % --- channel labels ---
        if isfield(data_struct, 'bipolar_labels') && ~isempty(data_struct.bipolar_labels)
            channel_labels = data_struct.bipolar_labels;
        else
            channel_labels = arrayfun(@(x) sprintf('Ch%d', x), 1:22, 'UniformOutput', false);
        end

        % bipolar_data is channels x samples (22 x N) per your screenshot. Transpose to samples x channels
        [r, c] = size(bipolar_data);
        if r == 22 && c >= 1
            eeg_data = bipolar_data'; % now samples x channels (N x 22)
            fprintf(' Transposed bipolar_data from [22 x %d] to [%d x 22].\n', c, size(eeg_data,1));
        else
            error('Unexpected bipolar_data shape: [%d x %d]', r, c);
        end

        [n_samples, n_channels] = size(eeg_data);
        fprintf(' Data ready: %d samples x %d channels, fs = %.1f Hz\n', n_samples, n_channels, fs);

        % Prepare output folder
        [file_path, file_name, ~] = fileparts(selected_file);
        output_dir = fullfile(file_path, [file_name, '_features']);
        if ~exist(output_dir, 'dir'), mkdir(output_dir); end

        %% Move to GPU where safe (use single to save memory)
        useGPU = ~isempty(g);
        if useGPU
            try
                eeg_data_gpu = gpuArray(single(eeg_data));
            catch
                warning('Failed to place data on GPU - using CPU for GPU operations.');
                useGPU = false;
            end
        end

        %% Initialize feature containers
        band_power = zeros(n_channels, n_bands);
        relative_power = zeros(n_channels, n_bands);
        peak_frequency = zeros(n_channels, n_bands);
        spectral_entropy = zeros(n_channels, n_bands);
        band_signals = cell(n_bands,1);

        %% 1. Filtering & Band signals
        fprintf('Extracting frequency bands and computing power features (CPU PSD for accuracy)...\n');
        for b = 1:n_bands
            band_name = band_names{b};
            freq_range = freq_bands.(band_name);
            fprintf(' Processing %s band (%.1f-%.1f Hz)...\n', band_name, freq_range(1), freq_range(2));

            [b_coeff, a_coeff] = butter(4, freq_range/(fs/2), 'bandpass');

            % perform filtfilt on CPU (expects samples x channels)
            filtered_signal = filtfilt(b_coeff, a_coeff, double(eeg_data)); % [samples x channels]
            band_signals{b} = filtered_signal;

            % compute PSD per channel using pwelch (CPU)
            window_length = min(2048, floor(n_samples/4));
            window = hanning(window_length);
            noverlap = floor(window_length/2);
            nfft = max(256, 2^nextpow2(window_length));

            for ch = 1:n_channels
                [pxx, f] = pwelch(double(eeg_data(:, ch)), window, noverlap, nfft, fs);
                band_idx = (f >= freq_range(1)) & (f <= freq_range(2));
                if any(band_idx)
                    band_power(ch, b) = trapz(f(band_idx), pxx(band_idx));
                    [~, peak_idx_local] = max(pxx(band_idx));
                    f_band = f(band_idx);
                    peak_frequency(ch, b) = f_band(peak_idx_local);
                    pxx_norm = pxx(band_idx) / sum(pxx(band_idx));
                    pxx_norm(pxx_norm == 0) = eps;
                    spectral_entropy(ch, b) = -sum(pxx_norm .* log2(pxx_norm));
                else
                    band_power(ch, b) = 0;
                    peak_frequency(ch, b) = NaN;
                    spectral_entropy(ch, b) = 0;
                end
            end
        end

        total_power = sum(band_power, 2);
        total_power(total_power==0) = eps;
        relative_power = band_power ./ total_power;

        %% 2. Additional spectral features (CPU)
        fprintf('Computing additional spectral features (CPU)...\n');
        alpha_peak_freq = zeros(n_channels, 1);
        individual_alpha_freq = zeros(n_channels,1);
        spectral_edge_freq = zeros(n_channels,1);
        mean_frequency = zeros(n_channels,1);
        spectral_centroid = zeros(n_channels,1);

        window_length = min(2048, floor(n_samples/4));
        window = hanning(window_length);
        noverlap = floor(window_length/2);
        nfft = max(256, 2^nextpow2(window_length));

        for ch = 1:n_channels
            [pxx, f] = pwelch(double(eeg_data(:, ch)), window, noverlap, nfft, fs);
            alpha_idx = (f >= 8) & (f <= 13);
            if any(alpha_idx)
                [~, peak_idx] = max(pxx(alpha_idx));
                f_alpha = f(alpha_idx);
                alpha_peak_freq(ch) = f_alpha(peak_idx);
                alpha_power = pxx(alpha_idx);
                if sum(alpha_power) > 0
                    individual_alpha_freq(ch) = sum(f_alpha .* alpha_power) / sum(alpha_power);
                end
            end
            cumulative_power = cumsum(pxx) / sum(pxx);
            edge_idx = find(cumulative_power >= 0.95, 1, 'first');
            if ~isempty(edge_idx)
                spectral_edge_freq(ch) = f(edge_idx);
            end
            mean_frequency(ch) = sum(f .* pxx) / sum(pxx);
            spectral_centroid(ch) = sum(f .* pxx) / sum(pxx);
        end

        %% 3. Functional Connectivity - PLV, PLI, Coherence
        fprintf('Computing functional connectivity measures...\n');
        coherence_matrix     = zeros(n_channels, n_channels, n_bands);
        plv_matrix           = zeros(n_channels, n_channels, n_bands);
        phase_lag_index      = zeros(n_channels, n_channels, n_bands);

        for b = 1:n_bands
            band_data = band_signals{b}; % CPU [samples x channels]

            % Use GPU for Hilbert/phase if available
            if useGPU
                try
                    band_data_gpu = gpuArray(single(band_data));
                    analytic_signal_gpu = hilbert(band_data_gpu);         % [samples x channels] on GPU
                    phases_gpu = angle(analytic_signal_gpu);             % [samples x channels] on GPU
                    S = size(phases_gpu,1); C = size(phases_gpu,2);
                    maxRowsForFull = 200000; % guard for memory
                    if S <= maxRowsForFull
                        phase_diff_gpu = phases_gpu(:, :, ones(1, C)) - permute(phases_gpu(:, :, ones(1, C)), [1 3 2]);
                        plv_gpu = abs(mean(exp(1i*phase_diff_gpu), 1)); % [1 x ch x ch]
                        plv_mat = squeeze(gather(plv_gpu));
                        plv_matrix(:, :, b) = plv_mat;

                        pli_gpu = abs(mean(sign(sin(phase_diff_gpu)), 1));
                        pli_mat = squeeze(gather(pli_gpu));
                        phase_lag_index(:,:,b) = pli_mat;
                    else
                        plv_tmp = zeros(n_channels, n_channels);
                        pli_tmp = zeros(n_channels, n_channels);
                        for i = 1:n_channels
                            phi_i = phases_gpu(:,i);
                            for j = i:n_channels
                                phi_j = phases_gpu(:,j);
                                diff_g = phi_i - phi_j; % samples x 1 on GPU
                                plv_val = abs(mean(exp(1i*diff_g)));
                                pli_val = abs(mean(sign(sin(diff_g))));
                                plv_tmp(i,j) = gather(plv_val);
                                plv_tmp(j,i) = plv_tmp(i,j);
                                pli_tmp(i,j) = gather(pli_val);
                                pli_tmp(j,i) = pli_tmp(i,j);
                            end
                        end
                        plv_matrix(:,:,b) = plv_tmp;
                        phase_lag_index(:,:,b) = pli_tmp;
                    end
                catch ME
                    warning('GPU PLV/PLI failed (will compute on CPU): %s', ME.message);
                    useGPU = false; % fallback
                end
            end

            if ~useGPU
                analytic_signal = hilbert(band_data);
                phases = angle(analytic_signal);
                phase_diff = phases(:, :, ones(1, n_channels)) - permute(phases(:, :, ones(1, n_channels)), [1 3 2]);
                plv_mat = squeeze(abs(mean(exp(1i*phase_diff), 1)));
                pli_mat = squeeze(abs(mean(sign(sin(phase_diff)), 1)));
                plv_matrix(:,:,b) = plv_mat;
                phase_lag_index(:,:,b) = pli_mat;
            end

            % Coherence using mscohere (CPU) - compute pairwise with parfor to speed up
            coh_mat = zeros(n_channels, n_channels);
            parfor i = 1:n_channels
                coh_row = zeros(1, n_channels);
                for j = i:n_channels
                    try
                        [cxy, ~] = mscohere(band_data(:, i), band_data(:, j), [], [], [], fs);
                        coh_val = mean(cxy);
                    catch
                        coh_val = 0;
                    end
                    coh_row(j) = coh_val;
                end
                coh_mat(i, :) = coh_row;
            end
            for i=1:n_channels
                for j=i+1:n_channels
                    coh_mat(j,i) = coh_mat(i,j);
                end
            end
            coherence_matrix(:,:,b) = coh_mat;
        end

        %% 4. Granger Causality (CPU, parfor)
        fprintf('Computing Granger causality (parallel CPU)...\n');
        granger_causality = zeros(n_channels, n_channels);
        max_lag = 10;
        parfor i = 1:n_channels
            gc_row = zeros(1, n_channels);
            for j = 1:n_channels
                if i ~= j
                    try
                        gc_row(j) = compute_granger_causality(eeg_data(:, i), eeg_data(:, j), max_lag);
                    catch
                        gc_row(j) = 0;
                    end
                end
            end
            granger_causality(i, :) = gc_row;
        end

        %% Save results
        fprintf('Saving extracted features...\n');
        features = struct();
        features.band_power = band_power;
        features.relative_power = relative_power;
        features.peak_frequency = peak_frequency;
        features.spectral_entropy = spectral_entropy;
        features.alpha_peak_freq = alpha_peak_freq;
        features.individual_alpha_freq = individual_alpha_freq;
        features.spectral_edge_freq = spectral_edge_freq;
        features.mean_frequency = mean_frequency;
        features.spectral_centroid = spectral_centroid;
        features.channel_labels = channel_labels;
        features.freq_bands = freq_bands;
        features.band_names = band_names;
        features.fs = fs;

        connectivity = struct();
        connectivity.coherence = coherence_matrix;
        connectivity.plv = plv_matrix;
        connectivity.phase_lag_index = phase_lag_index;
        connectivity.granger_causality = granger_causality;
        connectivity.channel_labels = channel_labels;
        connectivity.freq_bands = freq_bands;
        connectivity.band_names = band_names;

        save(fullfile(output_dir, 'extracted_features.mat'), 'features', '-v7.3');
        save(fullfile(output_dir, 'functional_connectivity.mat'), 'connectivity', '-v7.3');

        % call your helper save/plot functions (ensure they are on path)
        save_features_as_csv(features, connectivity, output_dir);
        create_visualizations(features, connectivity, output_dir);

        elapsed = toc;
        fprintf('✓ Processed %s in %.2f s. Output: %s\n', file_name, elapsed, output_dir);
        processed_count = processed_count + 1;

        % clear GPU explicitly if used
        if ~isempty(g)
            try
                reset(gpuDevice);
                g = gpuDevice; % re-query device for next iteration
            catch
                % ignore
            end
        end

        % clear large variables
        clear eeg_data eeg_data_gpu band_data band_data_gpu analytic_signal_gpu phases_gpu;

    catch ME
        fprintf('✗ Error processing %s: %s\n', patient_name, ME.message);
        omitted_list{end+1,1} = patient_name; %#ok<SAGROW>
        continue;
    end
end

% Save omitted patients list
omitted_file = fullfile(base_folder, 'omitted_patients.txt');
fid = fopen(omitted_file, 'w');
if fid ~= -1
    if isempty(omitted_list)
        fprintf(fid, ''); fclose(fid);
        fprintf('No patients omitted. (omitted_patients.txt created empty)\n');
    else
        for i = 1:length(omitted_list)
            fprintf(fid, '%s\n', omitted_list{i});
        end
        fclose(fid);
        fprintf('Wrote omitted patients (%d) to: %s\n', length(omitted_list), omitted_file);
    end
else
    warning('Could not write omitted patients file to %s', omitted_file);
end

fprintf('\n=== Pipeline Complete ===\n');
fprintf('Processed %d patients total. Omitted: %d\n', processed_count, length(omitted_list));


%% ===== Helper functions =====
function gc_value = compute_granger_causality(x, y, max_lag)
    % Simple Granger causality implementation: F-test statistic
    n = length(x);
    if length(y) ~= n
        gc_value = 0; return;
    end
    Y = y(max_lag+1:end);

    X_unres = [];
    for lag = 1:max_lag
        X_unres = [X_unres, y(max_lag+1-lag:end-lag), x(max_lag+1-lag:end-lag)];
    end
    X_unres = [ones(length(Y), 1), X_unres];

    X_res = [];
    for lag = 1:max_lag
        X_res = [X_res, y(max_lag+1-lag:end-lag)];
    end
    X_res = [ones(length(Y), 1), X_res];

    try
        beta_unres = X_unres\Y;
        rss_unres = sum((Y - X_unres*beta_unres).^2);

        beta_res = X_res\Y;
        rss_res = sum((Y - X_res*beta_res).^2);

        f_stat = ((rss_res - rss_unres)/max_lag) / (rss_unres/(length(Y) - 2*max_lag -1));
        gc_value = f_stat;
    catch
        gc_value = 0;
    end
end
function save_features_as_csv(features, connectivity, output_dir)
band_names = features.band_names;
channel_labels = features.channel_labels;

% Band power
band_power_table = array2table(features.band_power, 'RowNames', channel_labels, 'VariableNames', band_names);
writetable(band_power_table, fullfile(output_dir, 'band_power.csv'), 'WriteRowNames', true);

% Relative power
rel_power_table = array2table(features.relative_power, 'RowNames', channel_labels, 'VariableNames', band_names);
writetable(rel_power_table, fullfile(output_dir, 'relative_power.csv'), 'WriteRowNames', true);

% Additional spectral features
additional_features = table(features.alpha_peak_freq, features.individual_alpha_freq, ...
    features.spectral_edge_freq, features.mean_frequency, features.spectral_centroid, ...
    'RowNames', channel_labels, ...
    'VariableNames', {'AlphaPeakFreq', 'IndividualAlphaFreq', 'SpectralEdgeFreq', 'MeanFreq', 'SpectralCentroid'});
writetable(additional_features, fullfile(output_dir, 'additional_features.csv'), 'WriteRowNames', true);

% Connectivity metrics per band
for b = 1:length(band_names)
    band_name = band_names{b};
    % Coherence
    coh_table = array2table(connectivity.coherence(:, :, b), 'RowNames', channel_labels, 'VariableNames', channel_labels);
    writetable(coh_table, fullfile(output_dir, sprintf('coherence_%s.csv', band_name)), 'WriteRowNames', true);
    % PLV
    plv_table = array2table(connectivity.plv(:, :, b), 'RowNames', channel_labels, 'VariableNames', channel_labels);
    writetable(plv_table, fullfile(output_dir, sprintf('plv_%s.csv', band_name)), 'WriteRowNames', true);
    % PLI
    pli_table = array2table(connectivity.phase_lag_index(:, :, b), 'RowNames', channel_labels, 'VariableNames', channel_labels);
    writetable(pli_table, fullfile(output_dir, sprintf('pli_%s.csv', band_name)), 'WriteRowNames', true);
end

% Granger causality
gc_table = array2table(connectivity.granger_causality, 'RowNames', channel_labels, 'VariableNames', channel_labels);
writetable(gc_table, fullfile(output_dir, 'granger_causality.csv'), 'WriteRowNames', true);
end

function create_visualizations(features, connectivity, output_dir)
band_names = features.band_names;
n_bands = length(band_names);

% Spectral features figure
figure('Position', [100, 100, 1200, 800], 'Visible', 'off');

subplot(2, 3, 1);
imagesc(features.band_power'); colorbar;
title('Absolute Band Power'); xlabel('Channels'); ylabel('Frequency Bands');
set(gca, 'YTick', 1:n_bands, 'YTickLabel', band_names);

subplot(2, 3, 2);
imagesc(features.relative_power'); colorbar;
title('Relative Band Power'); xlabel('Channels'); ylabel('Frequency Bands');
set(gca, 'YTick', 1:n_bands, 'YTickLabel', band_names);

subplot(2, 3, 3);
plot(features.alpha_peak_freq, 'o-');
title('Alpha Peak Frequency'); xlabel('Channels'); ylabel('Frequency (Hz)');

subplot(2, 3, 4);
plot(features.spectral_entropy', 'LineWidth', 1.5);
title('Spectral Entropy by Band'); xlabel('Channels'); ylabel('Entropy');
legend(band_names, 'Location', 'best');

subplot(2, 3, 5);
plot(features.mean_frequency, 's-');
title('Mean Frequency'); xlabel('Channels'); ylabel('Frequency (Hz)');

subplot(2, 3, 6);
plot(features.spectral_centroid, '^-');
title('Spectral Centroid'); xlabel('Channels'); ylabel('Frequency (Hz)');

saveas(gcf, fullfile(output_dir, 'spectral_features.png'));
close(gcf);

% Connectivity matrices figure
figure('Position', [200, 200, 1500, 1000], 'Visible', 'off');
n_channels = size(connectivity.coherence, 1);

for b = 1:min(n_bands, 5)
    subplot(3, n_bands, b);
    imagesc(connectivity.coherence(:, :, b)); colorbar;
    title(sprintf('Coherence - %s', band_names{b}));

    subplot(3, n_bands, b + n_bands);
    imagesc(connectivity.plv(:, :, b)); colorbar;
    title(sprintf('PLV - %s', band_names{b}));

    subplot(3, n_bands, b + 2*n_bands);
    imagesc(connectivity.phase_lag_index(:, :, b)); colorbar;
    title(sprintf('PLI - %s', band_names{b}));
end
saveas(gcf, fullfile(output_dir, 'connectivity_matrices.png'));
close(gcf);

% Granger causality figure
figure('Position', [300, 300, 600, 500], 'Visible', 'off');
imagesc(connectivity.granger_causality); colorbar;
title('Granger Causality Matrix');
xlabel('Target Channel'); ylabel('Source Channel');
saveas(gcf, fullfile(output_dir, 'granger_causality.png'));
close(gcf);
end
