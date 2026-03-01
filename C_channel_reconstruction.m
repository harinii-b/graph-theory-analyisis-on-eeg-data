
% % ==========================
% % EEG Bipolar Montage Creator (Recursive)
% % ==========================
% clear; clc; close all;
% 
% % Main directory
% 
% % Define montage tables (same as yours)
% tcp_ar = { ...
%     'Fp1-F7', 'EEGFP1_REF', 'EEGF7_REF'; ...
%     'F7-T3',  'EEGF7_REF',  'EEGT3_REF'; ...
%     'T3-T5',  'EEGT3_REF',  'EEGT5_REF'; ...
%     'T5-O1',  'EEGT5_REF',  'EEGO1_REF'; ...
%     'Fp2-F8', 'EEGFP2_REF', 'EEGF8_REF'; ... 
%     'F8-T4',  'EEGF8_REF',  'EEGT4_REF'; ...
%     'T4-T6',  'EEGT4_REF',  'EEGT6_REF'; ...
%     'T6-O2',  'EEGT6_REF',  'EEGO2_REF'; ...
%     'A1-T3',  'EEGA1_REF',  'EEGT3_REF'; ...
%     'T3-C3',  'EEGT3_REF',  'EEGC3_REF'; ...
%     'C3-CZ',  'EEGC3_REF',  'EEGCZ_REF'; ...
%     'CZ-C4',  'EEGCZ_REF',  'EEGC4_REF'; ...
%     'C4-T4',  'EEGC4_REF',  'EEGT4_REF'; ...
%     'T4-A2',  'EEGT4_REF',  'EEGA2_REF'; ...
%     'Fp1-F3', 'EEGFP1_REF', 'EEGF3_REF'; ...
%     'F3-C3',  'EEGF3_REF',  'EEGC3_REF'; ...
%     'C3-P3',  'EEGC3_REF',  'EEGP3_REF'; ...
%     'P3-O1',  'EEGP3_REF',  'EEGO1_REF'; ...
%     'Fp2-F4', 'EEGFP2_REF', 'EEGF4_REF'; ...
%     'F4-C4',  'EEGF4_REF',  'EEGC4_REF'; ...
%     'C4-P4',  'EEGC4_REF',  'EEGP4_REF'; ...
%     'P4-O2',  'EEGP4_REF',  'EEGO2_REF' ...
% };
% tcp_le = { ...
%     'Fp1-F7', 'EEGFP1_LE', 'EEGF7_LE'; ...
%     'F7-T3',  'EEGF7_LE',  'EEGT3_LE'; ...
%     'T3-T5',  'EEGT3_LE',  'EEGT5_LE'; ...
%     'T5-O1',  'EEGT5_LE',  'EEGO1_LE'; ...
%     'Fp2-F8', 'EEGFP2_LE', 'EEGF8_LE'; ...
%     'F8-T4',  'EEGF8_LE',  'EEGT4_LE'; ...
%     'T4-T6',  'EEGT4_LE',  'EEGT6_LE'; ...
%     'T6-O2',  'EEGT6_LE',  'EEGO2_LE'; ...
%     'A1-T3',  'EEGA1_LE',  'EEGT3_LE'; ...
%     'T3-C3',  'EEGT3_LE',  'EEGC3_LE'; ...
%     'C3-CZ',  'EEGC3_LE',  'EEGCZ_LE'; ...
%     'CZ-C4',  'EEGCZ_LE',  'EEGC4_LE'; ...
%     'C4-T4',  'EEGC4_LE',  'EEGT4_LE'; ...
%     'T4-A2',  'EEGT4_LE',  'EEGA2_LE'; ...
%     'Fp1-F3', 'EEGFP1_LE', 'EEGF3_LE'; ...
%     'F3-C3',  'EEGF3_LE',  'EEGC3_LE'; ...
%     'C3-P3',  'EEGC3_LE',  'EEGP3_LE'; ...
%     'P3-O1',  'EEGP3_LE',  'EEGO1_LE'; ...
%     'Fp2-F4', 'EEGFP2_LE', 'EEGF4_LE'; ...
%     'F4-C4',  'EEGF4_LE',  'EEGC4_LE'; ...
%     'C4-P4',  'EEGC4_LE',  'EEGP4_LE'; ...
%     'P4-O2',  'EEGP4_LE',  'EEGO2_LE' ...
% };
% tcp_ar_a = tcp_ar;
% tcp_le_a = tcp_le;
% 
% % Map montage names to arrays
% montage_map = containers.Map();
% montage_map('tcp_ar') = tcp_ar;
% montage_map('tcp_le') = tcp_le;
% montage_map('tcp_ar_a') = tcp_ar_a;
% montage_map('tcp_le_a') = tcp_le_a;
% 
% % Recursively find all *_processed.mat files under main_dir
% mat_files = dir(fullfile(main_dir, '**', '*_processed.mat'));
% 
% for i = 1:length(mat_files)
%     file_path = fullfile(mat_files(i).folder, mat_files(i).name);
% 
%     % Determine montage key from folder name or file path
%     if contains(file_path, 'tcp_ar_a')
%         montage_key = 'tcp_ar_a';
%     elseif contains(file_path, 'tcp_le_a')
%         montage_key = 'tcp_le_a';
%     elseif contains(file_path, 'tcp_ar')
%         montage_key = 'tcp_ar';
%     elseif contains(file_path, 'tcp_le')
%         montage_key = 'tcp_le';
%     else
%         fprintf('⚠️ Skipping file (unknown montage): %s\n', file_path);
%         continue;
%     end
% 
%     montage_table = montage_map(montage_key);
% 
%     % Load the data
%     data = load(file_path);
% 
%     % Get the actual EEG signal data
%     if isfield(data, 'processed_data')
%         unipolar_data = data.processed_data';  % Transpose to [channels × samples]
%     elseif isfield(data, 'signals')
%         unipolar_data = data.signals';
%     elseif isfield(data, 'eeg')
%         unipolar_data = data.eeg';
%     elseif isfield(data, 'EEG')
%         unipolar_data = data.EEG';
%     else
%         fprintf('⚠️ No EEG signal field found in: %s\n', mat_files(i).name);
%         continue;
%     end
% 
%     % Get channel labels
%     if isfield(data, 'channel_labels')
%         unipolar_labels = data.channel_labels;
%     else
%         fprintf('⚠️ No channel_labels found in: %s\n', mat_files(i).name);
%         continue;
%     end
% 
%     n_channels = size(montage_table,1);
%     bipolar_data = zeros(n_channels, size(unipolar_data,2));
%     bipolar_labels = cell(n_channels,1);
% 
%     % Compute bipolar montage
%     for k = 1:n_channels
%         ch1 = montage_table{k,2};
%         ch2 = montage_table{k,3};
%         idx1 = find(strcmp(unipolar_labels, ch1));
%         idx2 = find(strcmp(unipolar_labels, ch2));
% 
%         if ~isempty(idx1) && ~isempty(idx2)
%             bipolar_data(k,:) = unipolar_data(idx1,:) - unipolar_data(idx2,:);
%         else
%             bipolar_data(k,:) = NaN;
%         end
%         bipolar_labels{k} = montage_table{k,1};
%     end
% 
%     % Save output
%     output.bipolar_data = bipolar_data;
%     output.bipolar_labels = bipolar_labels;
%     output.fs = data.fs;  % Preserve sampling frequency if available
% 
%     save(fullfile(mat_files(i).folder, [mat_files(i).name(1:end-4) '_bipolar.mat']), 'output');
%     fprintf('✅ Saved bipolar file: %s\n', mat_files(i).name);
% end
% 
% fprintf('\n🎯 All bipolar conversions completed!\n');


% clear; clc; close all;
% 
% % Main directory
% main_dir = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz';
% 
% % Define montage tables
% tcp_ar = { ...
%     'Fp1-F7', 'EEGFP1_REF', 'EEGF7_REF'; ...
%     'F7-T3',  'EEGF7_REF',  'EEGT3_REF'; ...
%     'T3-T5',  'EEGT3_REF',  'EEGT5_REF'; ...
%     'T5-O1',  'EEGT5_REF',  'EEGO1_REF'; ...
%     'Fp2-F8', 'EEGFP2_REF', 'EEGF8_REF'; ... 
%     'F8-T4',  'EEGF8_REF',  'EEGT4_REF'; ...
%     'T4-T6',  'EEGT4_REF',  'EEGT6_REF'; ...
%     'T6-O2',  'EEGT6_REF',  'EEGO2_REF'; ...
%     'A1-T3',  'EEGA1_REF',  'EEGT3_REF'; ...
%     'T3-C3',  'EEGT3_REF',  'EEGC3_REF'; ...
%     'C3-CZ',  'EEGC3_REF',  'EEGCZ_REF'; ...
%     'CZ-C4',  'EEGCZ_REF',  'EEGC4_REF'; ...
%     'C4-T4',  'EEGC4_REF',  'EEGT4_REF'; ...
%     'T4-A2',  'EEGT4_REF',  'EEGA2_REF'; ...
%     'Fp1-F3', 'EEGFP1_REF', 'EEGF3_REF'; ...
%     'F3-C3',  'EEGF3_REF',  'EEGC3_REF'; ...
%     'C3-P3',  'EEGC3_REF',  'EEGP3_REF'; ...
%     'P3-O1',  'EEGP3_REF',  'EEGO1_REF'; ...
%     'Fp2-F4', 'EEGFP2_REF', 'EEGF4_REF'; ...
%     'F4-C4',  'EEGF4_REF',  'EEGC4_REF'; ...
%     'C4-P4',  'EEGC4_REF',  'EEGP4_REF'; ...
%     'P4-O2',  'EEGP4_REF',  'EEGO2_REF' ...
% };
% tcp_le = { ...
%     'Fp1-F7', 'EEGFP1_LE', 'EEGF7_LE'; ...
%     'F7-T3',  'EEGF7_LE',  'EEGT3_LE'; ...
%     'T3-T5',  'EEGT3_LE',  'EEGT5_LE'; ...
%     'T5-O1',  'EEGT5_LE',  'EEGO1_LE'; ...
%     'Fp2-F8', 'EEGFP2_LE', 'EEGF8_LE'; ...
%     'F8-T4',  'EEGF8_LE',  'EEGT4_LE'; ...
%     'T4-T6',  'EEGT4_LE',  'EEGT6_LE'; ...
%     'T6-O2',  'EEGT6_LE',  'EEGO2_LE'; ...
%     'A1-T3',  'EEGA1_LE',  'EEGT3_LE'; ...
%     'T3-C3',  'EEGT3_LE',  'EEGC3_LE'; ...
%     'C3-CZ',  'EEGC3_LE',  'EEGCZ_LE'; ...
%     'CZ-C4',  'EEGCZ_LE',  'EEGC4_LE'; ...
%     'C4-T4',  'EEGC4_LE',  'EEGT4_LE'; ...
%     'T4-A2',  'EEGT4_LE',  'EEGA2_LE'; ...
%     'Fp1-F3', 'EEGFP1_LE', 'EEGF3_LE'; ...
%     'F3-C3',  'EEGF3_LE',  'EEGC3_LE'; ...
%     'C3-P3',  'EEGC3_LE',  'EEGP3_LE'; ...
%     'P3-O1',  'EEGP3_LE',  'EEGO1_LE'; ...
%     'Fp2-F4', 'EEGFP2_LE', 'EEGF4_LE'; ...
%     'F4-C4',  'EEGF4_LE',  'EEGC4_LE'; ...
%     'C4-P4',  'EEGC4_LE',  'EEGP4_LE'; ...
%     'P4-O2',  'EEGP4_LE',  'EEGO2_LE' ...
% };
% tcp_ar_a = tcp_ar;
% tcp_le_a = tcp_le;
% 
% % Map montage names to arrays
% montage_map = containers.Map();
% montage_map('tcp_ar') = tcp_ar;
% montage_map('tcp_le') = tcp_le;
% montage_map('tcp_ar_a') = tcp_ar_a;
% montage_map('tcp_le_a') = tcp_le_a;
% 
% % Recursively find all *_processed.mat files under main_dir
% mat_files = dir(fullfile(main_dir, '**', '*_processed.mat'));
% 
% % Structure to store all patient data
% patient_data = struct();
% 
% % Open log file for detailed tracking
% log_file = fopen(fullfile(main_dir, 'bipolar_conversion_log.txt'), 'w');
% fprintf(log_file, '========================================\n');
% fprintf(log_file, 'BIPOLAR CONVERSION LOG\n');
% fprintf(log_file, 'Generated: %s\n', datestr(now));
% fprintf(log_file, '========================================\n\n');
% 
% for i = 1:length(mat_files)
%     file_path = fullfile(mat_files(i).folder, mat_files(i).name);
% 
%     % Extract patient ID from path (adjust pattern as needed)
%     path_parts = strsplit(mat_files(i).folder, filesep);
%     patient_id = 'Unknown';
%     session_id = mat_files(i).name;
% 
%     % Try to find patient ID in path (looking for common patterns)
%     for p = 1:length(path_parts)
%         if contains(path_parts{p}, 'chb') || contains(path_parts{p}, 'patient', 'IgnoreCase', true)
%             patient_id = path_parts{p};
%             break;
%         end
%     end
% 
%     % Determine montage key from folder name or file path
%     if contains(file_path, 'tcp_ar_a')
%         montage_key = 'tcp_ar_a';
%     elseif contains(file_path, 'tcp_le_a')
%         montage_key = 'tcp_le_a';
%     elseif contains(file_path, 'tcp_ar')
%         montage_key = 'tcp_ar';
%     elseif contains(file_path, 'tcp_le')
%         montage_key = 'tcp_le';
%     else
%         fprintf('⚠️ Skipping file (unknown montage): %s\n', file_path);
%         fprintf(log_file, '⚠️ SKIPPED - Unknown montage: %s\n\n', file_path);
%         continue;
%     end
% 
%     montage_table = montage_map(montage_key);
% 
%     % Load the data
%     data = load(file_path);
% 
%     % Get the actual EEG signal data
%     if isfield(data, 'processed_data')
%         unipolar_data = data.processed_data';
%     elseif isfield(data, 'signals')
%         unipolar_data = data.signals';
%     elseif isfield(data, 'eeg')
%         unipolar_data = data.eeg';
%     elseif isfield(data, 'EEG')
%         unipolar_data = data.EEG';
%     else
%         fprintf('⚠️ No EEG signal field found in: %s\n', mat_files(i).name);
%         fprintf(log_file, '⚠️ ERROR - No EEG field: %s\n\n', file_path);
%         continue;
%     end
% 
%     % Get channel labels
%     if isfield(data, 'channel_labels')
%         unipolar_labels = data.channel_labels;
%     else
%         fprintf('⚠️ No channel_labels found in: %s\n', mat_files(i).name);
%         fprintf(log_file, '⚠️ ERROR - No channel labels: %s\n\n', file_path);
%         continue;
%     end
% 
%     % Initialize tracking for this session
%     n_channels = size(montage_table,1);
%     bipolar_data = zeros(n_channels, size(unipolar_data,2));
%     bipolar_labels = cell(n_channels,1);
%     skipped_channels = {};
%     missing_unipolar = {};
% 
%     % Write session header to log
%     fprintf(log_file, '\n========================================\n');
%     fprintf(log_file, 'PATIENT: %s\n', patient_id);
%     fprintf(log_file, 'SESSION: %s\n', session_id);
%     fprintf(log_file, 'MONTAGE: %s\n', montage_key);
%     fprintf(log_file, 'FILE: %s\n', file_path);
%     fprintf(log_file, '========================================\n\n');
% 
%     fprintf(log_file, 'Available Unipolar Channels:\n');
%     for u = 1:length(unipolar_labels)
%         fprintf(log_file, '  %d. %s\n', u, unipolar_labels{u});
%     end
%     fprintf(log_file, '\n');
% 
%     fprintf(log_file, 'Bipolar Channel Construction:\n');
%     fprintf(log_file, '%-20s %-20s %-20s %s\n', 'Bipolar', 'Channel 1', 'Channel 2', 'Status');
%     fprintf(log_file, '%s\n', repmat('-', 1, 80));
% 
%     % Compute bipolar montage
%     for k = 1:n_channels
%         ch1 = montage_table{k,2};
%         ch2 = montage_table{k,3};
%         idx1 = find(strcmp(unipolar_labels, ch1));
%         idx2 = find(strcmp(unipolar_labels, ch2));
% 
%         if ~isempty(idx1) && ~isempty(idx2)
%             bipolar_data(k,:) = unipolar_data(idx1,:) - unipolar_data(idx2,:);
%             status = '✓ OK';
%         else
%             bipolar_data(k,:) = NaN;
%             status = '✗ SKIPPED';
%             skipped_channels{end+1} = montage_table{k,1};
% 
%             if isempty(idx1)
%                 missing_unipolar{end+1} = ch1;
%             end
%             if isempty(idx2)
%                 missing_unipolar{end+1} = ch2;
%             end
%         end
%         bipolar_labels{k} = montage_table{k,1};
% 
%         fprintf(log_file, '%-20s %-20s %-20s %s\n', ...
%             montage_table{k,1}, ch1, ch2, status);
%     end
% 
%     % Summary for this session
%     fprintf(log_file, '\n');
%     fprintf(log_file, 'SUMMARY:\n');
%     fprintf(log_file, '  Total bipolar channels: %d\n', n_channels);
%     fprintf(log_file, '  Successfully created: %d\n', n_channels - length(skipped_channels));
%     fprintf(log_file, '  Skipped: %d\n', length(skipped_channels));
% 
%     if ~isempty(skipped_channels)
%         fprintf(log_file, '\n  Skipped Bipolar Channels:\n');
%         for s = 1:length(skipped_channels)
%             fprintf(log_file, '    - %s\n', skipped_channels{s});
%         end
%     end
% 
%     if ~isempty(missing_unipolar)
%         unique_missing = unique(missing_unipolar);
%         fprintf(log_file, '\n  Missing Unipolar Channels:\n');
%         for m = 1:length(unique_missing)
%             fprintf(log_file, '    - %s\n', unique_missing{m});
%         end
%     end
% 
%     fprintf(log_file, '\n');
% 
%     % Store in patient structure
%     if ~isfield(patient_data, patient_id)
%         patient_data.(patient_id) = struct();
%     end
% 
%     session_field = matlab.lang.makeValidName(session_id);
%     patient_data.(patient_id).(session_field) = struct(...
%         'montage', montage_key, ...
%         'bipolar_channels', {bipolar_labels}, ...
%         'skipped_channels', {skipped_channels}, ...
%         'missing_unipolar', {unique(missing_unipolar)}, ...
%         'file_path', file_path);
% 
%     % Save output
%     output.bipolar_data = bipolar_data;
%     output.bipolar_labels = bipolar_labels;
%     output.skipped_channels = skipped_channels;
%     output.montage_type = montage_key;
%     if isfield(data, 'fs')
%         output.fs = data.fs;
%     end
% 
%     save(fullfile(mat_files(i).folder, [mat_files(i).name(1:end-4) '_bipolar.mat']), 'output');
%     fprintf('✅ Saved bipolar file: %s\n', mat_files(i).name);
% end
% 
% fclose(log_file);
% 
% % Generate patient-wise summary
% summary_file = fopen(fullfile(main_dir, 'patient_summary.txt'), 'w');
% fprintf(summary_file, '========================================\n');
% fprintf(summary_file, 'PATIENT-WISE SUMMARY\n');
% fprintf(summary_file, 'Generated: %s\n', datestr(now));
% fprintf(summary_file, '========================================\n\n');
% 
% patients = fieldnames(patient_data);
% for p = 1:length(patients)
%     patient_id = patients{p};
%     sessions = fieldnames(patient_data.(patient_id));
% 
%     fprintf(summary_file, '\n╔══════════════════════════════════════════════════════════════════════════════╗\n');
%     fprintf(summary_file, '║ PATIENT: %-68s║\n', patient_id);
%     fprintf(summary_file, '║ Total Sessions: %-61d║\n', length(sessions));
%     fprintf(summary_file, '╚══════════════════════════════════════════════════════════════════════════════╝\n\n');
% 
%     for s = 1:length(sessions)
%         session = sessions{s};
%         sess_data = patient_data.(patient_id).(session);
% 
%         fprintf(summary_file, '  Session %d: %s\n', s, session);
%         fprintf(summary_file, '  Montage: %s\n', sess_data.montage);
%         fprintf(summary_file, '  Bipolar channels: %d\n', length(sess_data.bipolar_channels));
%         fprintf(summary_file, '  Skipped channels: %d\n', length(sess_data.skipped_channels));
% 
%         if ~isempty(sess_data.skipped_channels)
%             fprintf(summary_file, '    → ');
%             fprintf(summary_file, '%s, ', sess_data.skipped_channels{:});
%             fprintf(summary_file, '\n');
%         end
% 
%         if ~isempty(sess_data.missing_unipolar)
%             fprintf(summary_file, '  Missing unipolar: ');
%             fprintf(summary_file, '%s, ', sess_data.missing_unipolar{:});
%             fprintf(summary_file, '\n');
%         end
% 
%         fprintf(summary_file, '\n');
%     end
% end
% 
% fclose(summary_file);
% 
% % Save patient data structure
% save(fullfile(main_dir, 'patient_session_data.mat'), 'patient_data');
% 
% fprintf('\n🎯 All bipolar conversions completed!\n');
% fprintf('📊 Log file: %s\n', fullfile(main_dir, 'bipolar_conversion_log.txt'));
% fprintf('📋 Summary file: %s\n', fullfile(main_dir, 'patient_summary.txt'));
% fprintf('💾 Data structure: %s\n', fullfile(main_dir, 'patient_session_data.mat'));










% clear; clc; close all;
% 
% % Main directory
% main_dir = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\test';
% 
% % Define montage tables
% tcp_ar = { ...
%     'Fp1-F7', 'EEGFP1_REF', 'EEGF7_REF'; ...
%     'F7-T3',  'EEGF7_REF',  'EEGT3_REF'; ...
%     'T3-T5',  'EEGT3_REF',  'EEGT5_REF'; ...
%     'T5-O1',  'EEGT5_REF',  'EEGO1_REF'; ...
%     'Fp2-F8', 'EEGFP2_REF', 'EEGF8_REF'; ... 
%     'F8-T4',  'EEGF8_REF',  'EEGT4_REF'; ...
%     'T4-T6',  'EEGT4_REF',  'EEGT6_REF'; ...
%     'T6-O2',  'EEGT6_REF',  'EEGO2_REF'; ...
%     'A1-T3',  'EEGA1_REF',  'EEGT3_REF'; ...
%     'T3-C3',  'EEGT3_REF',  'EEGC3_REF'; ...
%     'C3-CZ',  'EEGC3_REF',  'EEGCZ_REF'; ...
%     'CZ-C4',  'EEGCZ_REF',  'EEGC4_REF'; ...
%     'C4-T4',  'EEGC4_REF',  'EEGT4_REF'; ...
%     'T4-A2',  'EEGT4_REF',  'EEGA2_REF'; ...
%     'Fp1-F3', 'EEGFP1_REF', 'EEGF3_REF'; ...
%     'F3-C3',  'EEGF3_REF',  'EEGC3_REF'; ...
%     'C3-P3',  'EEGC3_REF',  'EEGP3_REF'; ...
%     'P3-O1',  'EEGP3_REF',  'EEGO1_REF'; ...
%     'Fp2-F4', 'EEGFP2_REF', 'EEGF4_REF'; ...
%     'F4-C4',  'EEGF4_REF',  'EEGC4_REF'; ...
%     'C4-P4',  'EEGC4_REF',  'EEGP4_REF'; ...
%     'P4-O2',  'EEGP4_REF',  'EEGO2_REF' ...
% };
% tcp_le = { ...
%     'Fp1-F7', 'EEGFP1_LE', 'EEGF7_LE'; ...
%     'F7-T3',  'EEGF7_LE',  'EEGT3_LE'; ...
%     'T3-T5',  'EEGT3_LE',  'EEGT5_LE'; ...
%     'T5-O1',  'EEGT5_LE',  'EEGO1_LE'; ...
%     'Fp2-F8', 'EEGFP2_LE', 'EEGF8_LE'; ...
%     'F8-T4',  'EEGF8_LE',  'EEGT4_LE'; ...
%     'T4-T6',  'EEGT4_LE',  'EEGT6_LE'; ...
%     'T6-O2',  'EEGT6_LE',  'EEGO2_LE'; ...
%     'A1-T3',  'EEGA1_LE',  'EEGT3_LE'; ...
%     'T3-C3',  'EEGT3_LE',  'EEGC3_LE'; ...
%     'C3-CZ',  'EEGC3_LE',  'EEGCZ_LE'; ...
%     'CZ-C4',  'EEGCZ_LE',  'EEGC4_LE'; ...
%     'C4-T4',  'EEGC4_LE',  'EEGT4_LE'; ...
%     'T4-A2',  'EEGT4_LE',  'EEGA2_LE'; ...
%     'Fp1-F3', 'EEGFP1_LE', 'EEGF3_LE'; ...
%     'F3-C3',  'EEGF3_LE',  'EEGC3_LE'; ...
%     'C3-P3',  'EEGC3_LE',  'EEGP3_LE'; ...
%     'P3-O1',  'EEGP3_LE',  'EEGO1_LE'; ...
%     'Fp2-F4', 'EEGFP2_LE', 'EEGF4_LE'; ...
%     'F4-C4',  'EEGF4_LE',  'EEGC4_LE'; ...
%     'C4-P4',  'EEGC4_LE',  'EEGP4_LE'; ...
%     'P4-O2',  'EEGP4_LE',  'EEGO2_LE' ...
% };
% tcp_ar_a = tcp_ar;
% tcp_le_a = tcp_le;
% 
% % Map montage names to arrays
% montage_map = containers.Map();
% montage_map('tcp_ar') = tcp_ar;
% montage_map('tcp_le') = tcp_le;
% montage_map('tcp_ar_a') = tcp_ar_a;
% montage_map('tcp_le_a') = tcp_le_a;
% 
% % Recursively find all *_processed.mat files under main_dir
% mat_files = dir(fullfile(main_dir, '**', '*_processed.mat'));
% 
% % Count montage types in dataset
% montage_counts = struct('tcp_ar', 0, 'tcp_le', 0, 'tcp_ar_a', 0, 'tcp_le_a', 0, 'unknown', 0);
% 
% fprintf('\n========================================\n');
% fprintf('DATASET MONTAGE DISTRIBUTION\n');
% fprintf('========================================\n');
% for i = 1:length(mat_files)
%     file_path = fullfile(mat_files(i).folder, mat_files(i).name);
%     if contains(file_path, 'tcp_ar_a')
%         montage_counts.tcp_ar_a = montage_counts.tcp_ar_a + 1;
%     elseif contains(file_path, 'tcp_le_a')
%         montage_counts.tcp_le_a = montage_counts.tcp_le_a + 1;
%     elseif contains(file_path, 'tcp_ar')
%         montage_counts.tcp_ar = montage_counts.tcp_ar + 1;
%     elseif contains(file_path, 'tcp_le')
%         montage_counts.tcp_le = montage_counts.tcp_le + 1;
%     else
%         montage_counts.unknown = montage_counts.unknown + 1;
%     end
% end
% 
% fprintf('TCP_AR:   %d files\n', montage_counts.tcp_ar);
% fprintf('TCP_LE:   %d files\n', montage_counts.tcp_le);
% fprintf('TCP_AR_A: %d files\n', montage_counts.tcp_ar_a);
% fprintf('TCP_LE_A: %d files\n', montage_counts.tcp_le_a);
% fprintf('UNKNOWN:  %d files\n', montage_counts.unknown);
% fprintf('TOTAL:    %d files\n', length(mat_files));
% fprintf('========================================\n\n');
% 
% % Structure to store all patient data
% patient_data = struct();
% 
% % Open log file for detailed tracking
% log_file = fopen(fullfile(main_dir, 'bipolar_conversion_log.txt'), 'w');
% fprintf(log_file, '========================================\n');
% fprintf(log_file, 'BIPOLAR CONVERSION LOG\n');
% fprintf(log_file, 'Generated: %s\n', datestr(now));
% fprintf(log_file, '========================================\n\n');
% 
% for i = 1:length(mat_files)
%     file_path = fullfile(mat_files(i).folder, mat_files(i).name);
% 
%     % Extract patient ID from path (adjust pattern as needed)
%     path_parts = strsplit(mat_files(i).folder, filesep);
%     patient_id = 'Unknown';
%     session_id = mat_files(i).name;
% 
%     % Try to find patient ID in path (looking for common patterns)
%     for p = 1:length(path_parts)
%         if contains(path_parts{p}, 'chb') || contains(path_parts{p}, 'patient', 'IgnoreCase', true)
%             patient_id = path_parts{p};
%             break;
%         end
%     end
% 
%     % Determine montage key from folder name or file path
%     if contains(file_path, 'tcp_ar_a')
%         montage_key = 'tcp_ar_a';
%     elseif contains(file_path, 'tcp_le_a')
%         montage_key = 'tcp_le_a';
%     elseif contains(file_path, 'tcp_ar')
%         montage_key = 'tcp_ar';
%     elseif contains(file_path, 'tcp_le')
%         montage_key = 'tcp_le';
%     else
%         fprintf('⚠️ Skipping file (unknown montage): %s\n', file_path);
%         fprintf(log_file, '⚠️ SKIPPED - Unknown montage: %s\n\n', file_path);
%         continue;
%     end
% 
%     montage_table = montage_map(montage_key);
% 
%     % Load the data
%     data = load(file_path);
% 
%     % Get the actual EEG signal data
%     if isfield(data, 'processed_data')
%         unipolar_data = data.processed_data';
%     elseif isfield(data, 'signals')
%         unipolar_data = data.signals';
%     elseif isfield(data, 'eeg')
%         unipolar_data = data.eeg';
%     elseif isfield(data, 'EEG')
%         unipolar_data = data.EEG';
%     else
%         fprintf('⚠️ No EEG signal field found in: %s\n', mat_files(i).name);
%         fprintf(log_file, '⚠️ ERROR - No EEG field: %s\n\n', file_path);
%         continue;
%     end
% 
%     % Get channel labels
%     if isfield(data, 'channel_labels')
%         unipolar_labels = data.channel_labels;
%     else
%         fprintf('⚠️ No channel_labels found in: %s\n', mat_files(i).name);
%         fprintf(log_file, '⚠️ ERROR - No channel labels: %s\n\n', file_path);
%         continue;
%     end
% 
%     % Initialize tracking for this session
%     n_channels = size(montage_table,1);
%     bipolar_data = zeros(n_channels, size(unipolar_data,2));
%     bipolar_labels = cell(n_channels,1);
%     skipped_channels = {};
%     missing_unipolar = {};
% 
%     % Write session header to log
%     fprintf(log_file, '\n========================================\n');
%     fprintf(log_file, 'PATIENT: %s\n', patient_id);
%     fprintf(log_file, 'SESSION: %s\n', session_id);
%     fprintf(log_file, 'MONTAGE: %s\n', montage_key);
%     fprintf(log_file, 'FILE: %s\n', file_path);
%     fprintf(log_file, '========================================\n\n');
% 
%     fprintf(log_file, 'Available Unipolar Channels:\n');
%     for u = 1:length(unipolar_labels)
%         fprintf(log_file, '  %d. %s\n', u, unipolar_labels{u});
%     end
%     fprintf(log_file, '\n');
% 
%     fprintf(log_file, 'Bipolar Channel Construction:\n');
%     fprintf(log_file, '%-20s %-20s %-20s %s\n', 'Bipolar', 'Channel 1', 'Channel 2', 'Status');
%     fprintf(log_file, '%s\n', repmat('-', 1, 80));
% 
%     % Compute bipolar montage
%     for k = 1:n_channels
%         ch1 = montage_table{k,2};
%         ch2 = montage_table{k,3};
%         idx1 = find(strcmp(unipolar_labels, ch1));
%         idx2 = find(strcmp(unipolar_labels, ch2));
% 
%         if ~isempty(idx1) && ~isempty(idx2)
%             bipolar_data(k,:) = unipolar_data(idx1,:) - unipolar_data(idx2,:);
%             status = '✓ OK';
%         else
%             bipolar_data(k,:) = NaN;
%             status = '✗ SKIPPED';
%             skipped_channels{end+1} = montage_table{k,1};
% 
%             if isempty(idx1)
%                 missing_unipolar{end+1} = ch1;
%             end
%             if isempty(idx2)
%                 missing_unipolar{end+1} = ch2;
%             end
%         end
%         bipolar_labels{k} = montage_table{k,1};
% 
%         fprintf(log_file, '%-20s %-20s %-20s %s\n', ...
%             montage_table{k,1}, ch1, ch2, status);
%     end
% 
%     % Summary for this session
%     fprintf(log_file, '\n');
%     fprintf(log_file, 'SUMMARY:\n');
%     fprintf(log_file, '  Total bipolar channels: %d\n', n_channels);
%     fprintf(log_file, '  Successfully created: %d\n', n_channels - length(skipped_channels));
%     fprintf(log_file, '  Skipped: %d\n', length(skipped_channels));
% 
%     if ~isempty(skipped_channels)
%         fprintf(log_file, '\n  Skipped Bipolar Channels:\n');
%         for s = 1:length(skipped_channels)
%             fprintf(log_file, '    - %s\n', skipped_channels{s});
%         end
%     end
% 
%     if ~isempty(missing_unipolar)
%         unique_missing = unique(missing_unipolar);
%         fprintf(log_file, '\n  Missing Unipolar Channels:\n');
%         for m = 1:length(unique_missing)
%             fprintf(log_file, '    - %s\n', unique_missing{m});
%         end
%     end
% 
%     fprintf(log_file, '\n');
% 
%     % Store in patient structure
%     if ~isfield(patient_data, patient_id)
%         patient_data.(patient_id) = struct();
%     end
% 
%     session_field = matlab.lang.makeValidName(session_id);
%     patient_data.(patient_id).(session_field) = struct(...
%         'montage', montage_key, ...
%         'bipolar_channels', {bipolar_labels}, ...
%         'skipped_channels', {skipped_channels}, ...
%         'missing_unipolar', {unique(missing_unipolar)}, ...
%         'file_path', file_path);
% 
%     % Save output
%     output.bipolar_data = bipolar_data;
%     output.bipolar_labels = bipolar_labels;
%     output.skipped_channels = skipped_channels;
%     output.montage_type = montage_key;
%     if isfield(data, 'fs')
%         output.fs = data.fs;
%     end
% 
%     save(fullfile(mat_files(i).folder, [mat_files(i).name(1:end-4) '_bipolar.mat']), 'output');
%     fprintf('✅ Saved bipolar file: %s\n', mat_files(i).name);
% end
% 
% fclose(log_file);
% 
% % Generate patient-wise summary
% summary_file = fopen(fullfile(main_dir, 'patient_summary.txt'), 'w');
% fprintf(summary_file, '========================================\n');
% fprintf(summary_file, 'PATIENT-WISE SUMMARY\n');
% fprintf(summary_file, 'Generated: %s\n', datestr(now));
% fprintf(summary_file, '========================================\n\n');
% 
% patients = fieldnames(patient_data);
% for p = 1:length(patients)
%     patient_id = patients{p};
%     sessions = fieldnames(patient_data.(patient_id));
% 
%     fprintf(summary_file, '\n╔══════════════════════════════════════════════════════════════════════════════╗\n');
%     fprintf(summary_file, '║ PATIENT: %-68s║\n', patient_id);
%     fprintf(summary_file, '║ Total Sessions: %-61d║\n', length(sessions));
%     fprintf(summary_file, '╚══════════════════════════════════════════════════════════════════════════════╝\n\n');
% 
%     for s = 1:length(sessions)
%         session = sessions{s};
%         sess_data = patient_data.(patient_id).(session);
% 
%         fprintf(summary_file, '  Session %d: %s\n', s, session);
%         fprintf(summary_file, '  Montage: %s\n', sess_data.montage);
%         fprintf(summary_file, '  Bipolar channels: %d\n', length(sess_data.bipolar_channels));
%         fprintf(summary_file, '  Skipped channels: %d\n', length(sess_data.skipped_channels));
% 
%         if ~isempty(sess_data.skipped_channels)
%             fprintf(summary_file, '    → ');
%             fprintf(summary_file, '%s, ', sess_data.skipped_channels{:});
%             fprintf(summary_file, '\n');
%         end
% 
%         if ~isempty(sess_data.missing_unipolar)
%             fprintf(summary_file, '  Missing unipolar: ');
%             fprintf(summary_file, '%s, ', sess_data.missing_unipolar{:});
%             fprintf(summary_file, '\n');
%         end
% 
%         fprintf(summary_file, '\n');
%     end
% end
% 
% fclose(summary_file);
% 
% % Save patient data structure
% save(fullfile(main_dir, 'patient_session_data.mat'), 'patient_data');
% 
% % ========================================
% % GENERATE STATISTICS AND PLOTS
% % ========================================
% 
% % Collect statistics
% total_sessions = 0;
% total_patients = length(patients);
% channels_per_session = [];
% channels_per_patient = [];
% sessions_per_patient = [];
% montage_distribution = struct('tcp_ar', 0, 'tcp_le', 0, 'tcp_ar_a', 0, 'tcp_le_a', 0);
% 
% for p = 1:length(patients)
%     patient_id = patients{p};
%     sessions = fieldnames(patient_data.(patient_id));
%     total_sessions = total_sessions + length(sessions);
%     sessions_per_patient(end+1) = length(sessions);
% 
%     patient_channel_count = 0;
%     for s = 1:length(sessions)
%         session = sessions{s};
%         sess_data = patient_data.(patient_id).(session);
% 
%         % Count successfully created channels (non-NaN)
%         num_channels = length(sess_data.bipolar_channels) - length(sess_data.skipped_channels);
%         channels_per_session(end+1) = num_channels;
%         patient_channel_count = patient_channel_count + num_channels;
% 
%         % Count montage distribution
%         if strcmp(sess_data.montage, 'tcp_ar')
%             montage_distribution.tcp_ar = montage_distribution.tcp_ar + 1;
%         elseif strcmp(sess_data.montage, 'tcp_le')
%             montage_distribution.tcp_le = montage_distribution.tcp_le + 1;
%         elseif strcmp(sess_data.montage, 'tcp_ar_a')
%             montage_distribution.tcp_ar_a = montage_distribution.tcp_ar_a + 1;
%         elseif strcmp(sess_data.montage, 'tcp_le_a')
%             montage_distribution.tcp_le_a = montage_distribution.tcp_le_a + 1;
%         end
%     end
%     channels_per_patient(end+1) = patient_channel_count;
% end
% 
% % Print statistics
% fprintf('\n========================================\n');
% fprintf('PROCESSING STATISTICS\n');
% fprintf('========================================\n');
% fprintf('Total Patients: %d\n', total_patients);
% fprintf('Total Sessions: %d\n', total_sessions);
% fprintf('Avg Sessions per Patient: %.2f\n', mean(sessions_per_patient));
% fprintf('Avg Channels per Session: %.2f\n', mean(channels_per_session));
% fprintf('Total Bipolar Channels Created: %d\n', sum(channels_per_session));
% fprintf('========================================\n\n');
% 
% % Create visualizations
% figure('Position', [100, 100, 1400, 800]);
% 
% % Plot 1: Montage Distribution (Initial Dataset)
% subplot(2, 3, 1);
% montage_names = {'TCP\_AR', 'TCP\_LE', 'TCP\_AR\_A', 'TCP\_LE\_A'};
% montage_values = [montage_counts.tcp_ar, montage_counts.tcp_le, ...
%                   montage_counts.tcp_ar_a, montage_counts.tcp_le_a];
% bar(montage_values, 'FaceColor', [0.2 0.6 0.8]);
% set(gca, 'XTickLabel', montage_names, 'XTick', 1:4);
% xtickangle(45);
% ylabel('Number of Files');
% title('Initial Dataset: Montage Distribution');
% grid on;
% % Add value labels on bars
% for i = 1:length(montage_values)
%     text(i, montage_values(i), sprintf('%d', montage_values(i)), ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
% end
% 
% % Plot 2: Processed Montage Distribution
% subplot(2, 3, 2);
% processed_values = [montage_distribution.tcp_ar, montage_distribution.tcp_le, ...
%                     montage_distribution.tcp_ar_a, montage_distribution.tcp_le_a];
% bar(processed_values, 'FaceColor', [0.8 0.4 0.2]);
% set(gca, 'XTickLabel', montage_names, 'XTick', 1:4);
% xtickangle(45);
% ylabel('Number of Sessions');
% title('Processed Sessions: Montage Distribution');
% grid on;
% for i = 1:length(processed_values)
%     text(i, processed_values(i), sprintf('%d', processed_values(i)), ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
% end
% 
% % Plot 3: Channels Created per Session
% subplot(2, 3, 3);
% histogram(channels_per_session, 'BinWidth', 1, 'FaceColor', [0.3 0.7 0.3]);
% xlabel('Number of Channels');
% ylabel('Number of Sessions');
% title('Channels Created per Session');
% grid on;
% xlim([min(channels_per_session)-1, max(channels_per_session)+1]);
% 
% % Plot 4: Channels per Patient
% subplot(2, 3, 4);
% bar(channels_per_patient, 'FaceColor', [0.9 0.5 0.2]);
% xlabel('Patient Index');
% ylabel('Total Channels Created');
% title(sprintf('Total Channels per Patient (N=%d)', total_patients));
% grid on;
% 
% % Plot 5: Sessions per Patient
% subplot(2, 3, 5);
% bar(sessions_per_patient, 'FaceColor', [0.6 0.3 0.8]);
% xlabel('Patient Index');
% ylabel('Number of Sessions');
% title('Sessions per Patient');
% grid on;
% 
% % Plot 6: Channels vs Sessions (Scatter)
% subplot(2, 3, 6);
% scatter(1:length(channels_per_session), channels_per_session, 50, 'filled', ...
%     'MarkerFaceColor', [0.2 0.4 0.8]);
% xlabel('Session Index');
% ylabel('Channels Created');
% title('Channels Created vs Session Index');
% grid on;
% hold on;
% plot([1 length(channels_per_session)], [mean(channels_per_session) mean(channels_per_session)], ...
%     'r--', 'LineWidth', 2);
% legend('Sessions', sprintf('Mean = %.1f', mean(channels_per_session)), 'Location', 'best');
% 
% % Save the figure
% sgtitle('Bipolar Montage Conversion Statistics', 'FontSize', 14, 'FontWeight', 'bold');
% saveas(gcf, fullfile(main_dir, 'bipolar_statistics.png'));
% saveas(gcf, fullfile(main_dir, 'bipolar_statistics.fig'));
% 
% fprintf('\n🎯 All bipolar conversions completed!\n');
% fprintf('📊 Log file: %s\n', fullfile(main_dir, 'bipolar_conversion_log.txt'));
% fprintf('📋 Summary file: %s\n', fullfile(main_dir, 'patient_summary.txt'));
% fprintf('💾 Data structure: %s\n', fullfile(main_dir, 'patient_session_data.mat'));
% fprintf('📈 Statistics plot: %s\n', fullfile(main_dir, 'bipolar_statistics.png'));

clear; clc; close all;

% Main directory
main_dir = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz';

% Define montage tables
tcp_ar = { ...
    'Fp1-F7', 'EEGFP1_REF', 'EEGF7_REF'; ...
    'F7-T3',  'EEGF7_REF',  'EEGT3_REF'; ...
    'T3-T5',  'EEGT3_REF',  'EEGT5_REF'; ...
    'T5-O1',  'EEGT5_REF',  'EEGO1_REF'; ...
    'Fp2-F8', 'EEGFP2_REF', 'EEGF8_REF'; ... 
    'F8-T4',  'EEGF8_REF',  'EEGT4_REF'; ...
    'T4-T6',  'EEGT4_REF',  'EEGT6_REF'; ...
    'T6-O2',  'EEGT6_REF',  'EEGO2_REF'; ...
    'A1-T3',  'EEGA1_REF',  'EEGT3_REF'; ...
    'T3-C3',  'EEGT3_REF',  'EEGC3_REF'; ...
    'C3-CZ',  'EEGC3_REF',  'EEGCZ_REF'; ...
    'CZ-C4',  'EEGCZ_REF',  'EEGC4_REF'; ...
    'C4-T4',  'EEGC4_REF',  'EEGT4_REF'; ...
    'T4-A2',  'EEGT4_REF',  'EEGA2_REF'; ...
    'Fp1-F3', 'EEGFP1_REF', 'EEGF3_REF'; ...
    'F3-C3',  'EEGF3_REF',  'EEGC3_REF'; ...
    'C3-P3',  'EEGC3_REF',  'EEGP3_REF'; ...
    'P3-O1',  'EEGP3_REF',  'EEGO1_REF'; ...
    'Fp2-F4', 'EEGFP2_REF', 'EEGF4_REF'; ...
    'F4-C4',  'EEGF4_REF',  'EEGC4_REF'; ...
    'C4-P4',  'EEGC4_REF',  'EEGP4_REF'; ...
    'P4-O2',  'EEGP4_REF',  'EEGO2_REF' ...
};
tcp_le = { ...
    'Fp1-F7', 'EEGFP1_LE', 'EEGF7_LE'; ...
    'F7-T3',  'EEGF7_LE',  'EEGT3_LE'; ...
    'T3-T5',  'EEGT3_LE',  'EEGT5_LE'; ...
    'T5-O1',  'EEGT5_LE',  'EEGO1_LE'; ...
    'Fp2-F8', 'EEGFP2_LE', 'EEGF8_LE'; ...
    'F8-T4',  'EEGF8_LE',  'EEGT4_LE'; ...
    'T4-T6',  'EEGT4_LE',  'EEGT6_LE'; ...
    'T6-O2',  'EEGT6_LE',  'EEGO2_LE'; ...
    'A1-T3',  'EEGA1_LE',  'EEGT3_LE'; ...
    'T3-C3',  'EEGT3_LE',  'EEGC3_LE'; ...
    'C3-CZ',  'EEGC3_LE',  'EEGCZ_LE'; ...
    'CZ-C4',  'EEGCZ_LE',  'EEGC4_LE'; ...
    'C4-T4',  'EEGC4_LE',  'EEGT4_LE'; ...
    'T4-A2',  'EEGT4_LE',  'EEGA2_LE'; ...
    'Fp1-F3', 'EEGFP1_LE', 'EEGF3_LE'; ...
    'F3-C3',  'EEGF3_LE',  'EEGC3_LE'; ...
    'C3-P3',  'EEGC3_LE',  'EEGP3_LE'; ...
    'P3-O1',  'EEGP3_LE',  'EEGO1_LE'; ...
    'Fp2-F4', 'EEGFP2_LE', 'EEGF4_LE'; ...
    'F4-C4',  'EEGF4_LE',  'EEGC4_LE'; ...
    'C4-P4',  'EEGC4_LE',  'EEGP4_LE'; ...
    'P4-O2',  'EEGP4_LE',  'EEGO2_LE' ...
};
tcp_ar_a = tcp_ar;
tcp_le_a = tcp_le;

% Map montage names to arrays
montage_map = containers.Map();
montage_map('tcp_ar') = tcp_ar;
montage_map('tcp_le') = tcp_le;
montage_map('tcp_ar_a') = tcp_ar_a;
montage_map('tcp_le_a') = tcp_le_a;

% Recursively find all *_processed.mat files under main_dir
mat_files = dir(fullfile(main_dir, '**', '*_processed.mat'));

% Count montage types in dataset
montage_counts = struct('tcp_ar', 0, 'tcp_le', 0, 'tcp_ar_a', 0, 'tcp_le_a', 0, 'unknown', 0);

fprintf('\n========================================\n');
fprintf('DATASET MONTAGE DISTRIBUTION\n');
fprintf('========================================\n');
for i = 1:length(mat_files)
    file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    if contains(file_path, 'tcp_ar_a')
        montage_counts.tcp_ar_a = montage_counts.tcp_ar_a + 1;
    elseif contains(file_path, 'tcp_le_a')
        montage_counts.tcp_le_a = montage_counts.tcp_le_a + 1;
    elseif contains(file_path, 'tcp_ar')
        montage_counts.tcp_ar = montage_counts.tcp_ar + 1;
    elseif contains(file_path, 'tcp_le')
        montage_counts.tcp_le = montage_counts.tcp_le + 1;
    else
        montage_counts.unknown = montage_counts.unknown + 1;
    end
end

fprintf('TCP_AR:   %d files\n', montage_counts.tcp_ar);
fprintf('TCP_LE:   %d files\n', montage_counts.tcp_le);
fprintf('TCP_AR_A: %d files\n', montage_counts.tcp_ar_a);
fprintf('TCP_LE_A: %d files\n', montage_counts.tcp_le_a);
fprintf('UNKNOWN:  %d files\n', montage_counts.unknown);
fprintf('TOTAL:    %d files\n', length(mat_files));
fprintf('========================================\n\n');

% Structure to store all patient data
patient_data = struct();

% Open log file for detailed tracking
log_file = fopen(fullfile(main_dir, 'bipolar_conversion_log.txt'), 'w');
fprintf(log_file, '========================================\n');
fprintf(log_file, 'BIPOLAR CONVERSION LOG\n');
fprintf(log_file, 'Generated: %s\n', datestr(now));
fprintf(log_file, '========================================\n\n');

for i = 1:length(mat_files)
    file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    
    % Extract patient ID from path
    % Path structure: .../patient_id/session_folder/montage_folder/file.mat
    % Example: .../aaaaaklt/s001_2010/02_tcp_le/aaaaaklt_s001_t001_processed.mat
    path_parts = strsplit(mat_files(i).folder, filesep);
    patient_id = 'Unknown';
    session_id = mat_files(i).name;
    
    % Find patient ID (should be 3 levels up from the file)
    % The structure is: patient_id/session/montage/file
    if length(path_parts) >= 3
        patient_id = path_parts{end-2};  % 3 levels up from montage folder
    else
        % Fallback: look for common patterns
        for p = 1:length(path_parts)
            if contains(path_parts{p}, 'chb') || contains(path_parts{p}, 'aaaa') || ...
               contains(path_parts{p}, 'patient', 'IgnoreCase', true)
                patient_id = path_parts{p};
                break;
            end
        end
    end

    % Determine montage key from folder name or file path
    if contains(file_path, 'tcp_ar_a')
        montage_key = 'tcp_ar_a';
    elseif contains(file_path, 'tcp_le_a')
        montage_key = 'tcp_le_a';
    elseif contains(file_path, 'tcp_ar')
        montage_key = 'tcp_ar';
    elseif contains(file_path, 'tcp_le')
        montage_key = 'tcp_le';
    else
        fprintf('⚠️ Skipping file (unknown montage): %s\n', file_path);
        fprintf(log_file, '⚠️ SKIPPED - Unknown montage: %s\n\n', file_path);
        continue;
    end

    montage_table = montage_map(montage_key);

    % Load the data
    data = load(file_path);
    
    % Get the actual EEG signal data
    if isfield(data, 'processed_data')
        unipolar_data = data.processed_data';
    elseif isfield(data, 'signals')
        unipolar_data = data.signals';
    elseif isfield(data, 'eeg')
        unipolar_data = data.eeg';
    elseif isfield(data, 'EEG')
        unipolar_data = data.EEG';
    else
        fprintf('⚠️ No EEG signal field found in: %s\n', mat_files(i).name);
        fprintf(log_file, '⚠️ ERROR - No EEG field: %s\n\n', file_path);
        continue;
    end
    
    % Get channel labels
    if isfield(data, 'channel_labels')
        unipolar_labels = data.channel_labels;
    else
        fprintf('⚠️ No channel_labels found in: %s\n', mat_files(i).name);
        fprintf(log_file, '⚠️ ERROR - No channel labels: %s\n\n', file_path);
        continue;
    end

    % Initialize tracking for this session
    n_channels = size(montage_table,1);
    bipolar_data = zeros(n_channels, size(unipolar_data,2));
    bipolar_labels = cell(n_channels,1);
    skipped_channels = {};
    missing_unipolar = {};
    valid_count = 0;
    valid_bipolar_data = [];
    valid_bipolar_labels = {};
    
    % Write session header to log
    fprintf(log_file, '\n========================================\n');
    fprintf(log_file, 'PATIENT: %s\n', patient_id);
    fprintf(log_file, 'SESSION: %s\n', session_id);
    fprintf(log_file, 'MONTAGE: %s\n', montage_key);
    fprintf(log_file, 'FILE: %s\n', file_path);
    fprintf(log_file, '========================================\n\n');
    
    fprintf(log_file, 'Available Unipolar Channels:\n');
    for u = 1:length(unipolar_labels)
        fprintf(log_file, '  %d. %s\n', u, unipolar_labels{u});
    end
    fprintf(log_file, '\n');
    
    fprintf(log_file, 'Bipolar Channel Construction:\n');
    fprintf(log_file, '%-20s %-20s %-20s %s\n', 'Bipolar', 'Channel 1', 'Channel 2', 'Status');
    fprintf(log_file, '%s\n', repmat('-', 1, 80));

    % Compute bipolar montage
    for k = 1:n_channels
    ch1 = montage_table{k,2};
    ch2 = montage_table{k,3};
    idx1 = find(strcmp(unipolar_labels, ch1));
    idx2 = find(strcmp(unipolar_labels, ch2));

    if ~isempty(idx1) && ~isempty(idx2)
        valid_count = valid_count + 1;
        valid_bipolar_data(valid_count,:) = unipolar_data(idx1,:) - unipolar_data(idx2,:);
        valid_bipolar_labels{valid_count} = montage_table{k,1};
        status = '✓ OK';
    else
        status = '✗ SKIPPED';
        skipped_channels{end+1} = montage_table{k,1};
        
        if isempty(idx1)
            missing_unipolar{end+1} = ch1;
        end
        if isempty(idx2)
            missing_unipolar{end+1} = ch2;
        end
    end
    
    fprintf(log_file, '%-20s %-20s %-20s %s\n', ...
        montage_table{k,1}, ch1, ch2, status);
    end
    % Use only valid channels
bipolar_data = valid_bipolar_data;
bipolar_labels = valid_bipolar_labels;
    
    % Summary for this session
    fprintf(log_file, '\n');
    fprintf(log_file, 'SUMMARY:\n');
    fprintf(log_file, '  Total bipolar channels: %d\n', n_channels);
    fprintf(log_file, '  Successfully created: %d\n', n_channels - length(skipped_channels));
    fprintf(log_file, '  Skipped: %d\n', length(skipped_channels));
    
    if ~isempty(skipped_channels)
        fprintf(log_file, '\n  Skipped Bipolar Channels:\n');
        for s = 1:length(skipped_channels)
            fprintf(log_file, '    - %s\n', skipped_channels{s});
        end
    end
    
    if ~isempty(missing_unipolar)
        unique_missing = unique(missing_unipolar);
        fprintf(log_file, '\n  Missing Unipolar Channels:\n');
        for m = 1:length(unique_missing)
            fprintf(log_file, '    - %s\n', unique_missing{m});
        end
    end
    
    fprintf(log_file, '\n');

    % Store in patient structure
    if ~isfield(patient_data, patient_id)
        patient_data.(patient_id) = struct();
    end
    
    session_field = matlab.lang.makeValidName(session_id);
    patient_data.(patient_id).(session_field) = struct(...
        'montage', montage_key, ...
        'bipolar_channels', {bipolar_labels}, ...
        'skipped_channels', {skipped_channels}, ...
        'missing_unipolar', {unique(missing_unipolar)}, ...
        'file_path', file_path);

    % Save output
    output.bipolar_data = bipolar_data;
    output.bipolar_labels = bipolar_labels;
    output.skipped_channels = skipped_channels;
    output.montage_type = montage_key;
    if isfield(data, 'fs')
        output.fs = data.fs;
    end

    save(fullfile(mat_files(i).folder, [mat_files(i).name(1:end-4) '_bipolar.mat']), 'output');
    fprintf('✅ Saved bipolar file: %s\n', mat_files(i).name);
end

fclose(log_file);

% Generate patient-wise summary
summary_file = fopen(fullfile(main_dir, 'patient_summary.txt'), 'w');
fprintf(summary_file, '========================================\n');
fprintf(summary_file, 'PATIENT-WISE SUMMARY\n');
fprintf(summary_file, 'Generated: %s\n', datestr(now));
fprintf(summary_file, '========================================\n\n');

patients = fieldnames(patient_data);
for p = 1:length(patients)
    patient_id = patients{p};
    sessions = fieldnames(patient_data.(patient_id));
    
    fprintf(summary_file, '\n╔══════════════════════════════════════════════════════════════════════════════╗\n');
    fprintf(summary_file, '║ PATIENT: %-68s║\n', patient_id);
    fprintf(summary_file, '║ Total Sessions: %-61d║\n', length(sessions));
    fprintf(summary_file, '╚══════════════════════════════════════════════════════════════════════════════╝\n\n');
    
    for s = 1:length(sessions)
        session = sessions{s};
        sess_data = patient_data.(patient_id).(session);
        
        fprintf(summary_file, '  Session %d: %s\n', s, session);
        fprintf(summary_file, '  Montage: %s\n', sess_data.montage);
        fprintf(summary_file, '  Bipolar channels: %d\n', length(sess_data.bipolar_channels));
        fprintf(summary_file, '  Skipped channels: %d\n', length(sess_data.skipped_channels));
        
        if ~isempty(sess_data.skipped_channels)
            fprintf(summary_file, '    → ');
            fprintf(summary_file, '%s, ', sess_data.skipped_channels{:});
            fprintf(summary_file, '\n');
        end
        
        if ~isempty(sess_data.missing_unipolar)
            fprintf(summary_file, '  Missing unipolar: ');
            fprintf(summary_file, '%s, ', sess_data.missing_unipolar{:});
            fprintf(summary_file, '\n');
        end
        
        fprintf(summary_file, '\n');
    end
end

fclose(summary_file);

% Save patient data structure
save(fullfile(main_dir, 'patient_session_data.mat'), 'patient_data');

% ========================================
% GENERATE STATISTICS AND PLOTS
% ========================================

% Collect statistics
total_sessions = 0;
total_patients = length(patients);
channels_per_session = [];
mode_channels_per_patient = [];
sessions_per_patient = [];
patient_names = {};
montage_distribution = struct('tcp_ar', 0, 'tcp_le', 0, 'tcp_ar_a', 0, 'tcp_le_a', 0);

for p = 1:length(patients)
    patient_id = patients{p};
    sessions = fieldnames(patient_data.(patient_id));
    total_sessions = total_sessions + length(sessions);
    sessions_per_patient(end+1) = length(sessions);
    patient_names{end+1} = patient_id;
    
    patient_session_channels = [];
    for s = 1:length(sessions)
        session = sessions{s};
        sess_data = patient_data.(patient_id).(session);
        
        % Count successfully created channels (non-NaN)
        num_channels = length(sess_data.bipolar_channels) - length(sess_data.skipped_channels);
        channels_per_session(end+1) = num_channels;
        patient_session_channels(end+1) = num_channels;
        
        % Count montage distribution
        if strcmp(sess_data.montage, 'tcp_ar')
            montage_distribution.tcp_ar = montage_distribution.tcp_ar + 1;
        elseif strcmp(sess_data.montage, 'tcp_le')
            montage_distribution.tcp_le = montage_distribution.tcp_le + 1;
        elseif strcmp(sess_data.montage, 'tcp_ar_a')
            montage_distribution.tcp_ar_a = montage_distribution.tcp_ar_a + 1;
        elseif strcmp(sess_data.montage, 'tcp_le_a')
            montage_distribution.tcp_le_a = montage_distribution.tcp_le_a + 1;
        end
    end
    
    % Calculate mode of channels for this patient
    mode_channels_per_patient(end+1) = mode(patient_session_channels);
end

% Print statistics
fprintf('\n========================================\n');
fprintf('PROCESSING STATISTICS\n');
fprintf('========================================\n');
fprintf('Total Patients: %d\n', total_patients);
fprintf('Total Sessions: %d\n', total_sessions);
fprintf('Mode Sessions per Patient: %.2f\n', mode(sessions_per_patient));
fprintf('Mode Channels per Session: %.2f\n', mode(channels_per_session));
fprintf('Total Bipolar Channels Created: %d\n', sum(channels_per_session));
fprintf('========================================\n\n');

% Create visualizations
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Montage Distribution (Initial Dataset)
subplot(2, 2, 1);
montage_names = {'TCP\_AR', 'TCP\_LE', 'TCP\_AR\_A', 'TCP\_LE\_A'};
montage_values = [montage_counts.tcp_ar, montage_counts.tcp_le, ...
                  montage_counts.tcp_ar_a, montage_counts.tcp_le_a];
bar(montage_values, 'FaceColor', [0.2 0.6 0.8]);
set(gca, 'XTickLabel', montage_names, 'XTick', 1:4);
xtickangle(45);
ylabel('Number of Files');
title('Initial Dataset: Montage Distribution');
grid on;
% Add value labels on bars
for i = 1:length(montage_values)
    text(i, montage_values(i), sprintf('%d', montage_values(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
end

% Plot 2: Processed Montage Distribution
subplot(2, 2, 2);
processed_values = [montage_distribution.tcp_ar, montage_distribution.tcp_le, ...
                    montage_distribution.tcp_ar_a, montage_distribution.tcp_le_a];
bar(processed_values, 'FaceColor', [0.8 0.4 0.2]);
set(gca, 'XTickLabel', montage_names, 'XTick', 1:4);
xtickangle(45);
ylabel('Number of Sessions');
title('Processed Sessions: Montage Distribution');
grid on;
for i = 1:length(processed_values)
    text(i, processed_values(i), sprintf('%d', processed_values(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
end

% Plot 3: Mode Channels per Patient
subplot(2, 2, 3);
bar(mode_channels_per_patient, 'FaceColor', [0.3 0.7 0.3]);
xlabel('Patient Index');
ylabel('Mode Number of Channels');
title(sprintf('Mode Channels per Patient (N=%d patients)', total_patients));
grid on;
ylim([0 max(mode_channels_per_patient)+2]);

% Plot 4: Channels Created vs Sessions
subplot(2, 2, 4);
scatter(1:length(channels_per_session), channels_per_session, 50, 'filled', ...
    'MarkerFaceColor', [0.2 0.4 0.8]);
xlabel('Session Index');
ylabel('Channels Created');
title(sprintf('Channels Created per Session (N=%d sessions)', total_sessions));
grid on;
hold on;
plot([1 length(channels_per_session)], [mean(channels_per_session) mean(channels_per_session)], ...
    'r--', 'LineWidth', 2);
legend('Sessions', sprintf('Mean = %.1f', mean(channels_per_session)), 'Location', 'best');

% Save the figure
sgtitle('Bipolar Montage Conversion Statistics', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, fullfile(main_dir, 'bipolar_statistics.png'));
saveas(gcf, fullfile(main_dir, 'bipolar_statistics.fig'));

fprintf('\n🎯 All bipolar conversions completed!\n');
fprintf('📊 Log file: %s\n', fullfile(main_dir, 'bipolar_conversion_log.txt'));
fprintf('📋 Summary file: %s\n', fullfile(main_dir, 'patient_summary.txt'));
fprintf('💾 Data structure: %s\n', fullfile(main_dir, 'patient_session_data.mat'));
fprintf('📈 Statistics plot: %s\n', fullfile(main_dir, 'bipolar_statistics.png'));

% ========================================
% GENERATE PATIENT vs CHANNEL COUNT TABLE
% ========================================

% Load patient data if not already in workspace
if ~exist('patient_data', 'var')
    load(fullfile(main_dir, 'patient_session_data.mat'));
    patients = fieldnames(patient_data);
end

% Initialize table data structure
channel_counts = [19, 20, 21, 22];
table_data = cell(length(patients), length(channel_counts));

% Fill table with session names
for p = 1:length(patients)
    patient_id = patients{p};
    sessions = fieldnames(patient_data.(patient_id));
    
    for s = 1:length(sessions)
        session = sessions{s};
        sess_data = patient_data.(patient_id).(session);
        
        % Count successfully created channels
        num_channels = length(sess_data.bipolar_channels) - length(sess_data.skipped_channels);
        
        % Find which column this belongs to
        col_idx = find(channel_counts == num_channels);
        
        if ~isempty(col_idx)
            % Add session name to the appropriate cell
            if isempty(table_data{p, col_idx})
                table_data{p, col_idx} = session;
            else
                % Multiple sessions with same channel count - append
                table_data{p, col_idx} = sprintf('%s, %s', table_data{p, col_idx}, session);
            end
        end
    end
end

% Create a proper MATLAB table
col_names = arrayfun(@(x) sprintf('Ch_%d', x), channel_counts, 'UniformOutput', false);
patient_channel_table = cell2table(table_data, 'VariableNames', col_names, 'RowNames', patients);

% Display the table
fprintf('\n========================================\n');
fprintf('PATIENT vs CHANNEL COUNT TABLE\n');
fprintf('========================================\n\n');
disp(patient_channel_table);

% Save table to CSV
writetable(patient_channel_table, fullfile(main_dir, 'patient_channel_table.csv'), 'WriteRowNames', true);

% Save table to TXT with better formatting
txt_file = fopen(fullfile(main_dir, 'patient_channel_table.txt'), 'w');
fprintf(txt_file, '========================================\n');
fprintf(txt_file, 'PATIENT vs CHANNEL COUNT TABLE\n');
fprintf(txt_file, 'Sessions listed by number of channels created\n');
fprintf(txt_file, '========================================\n\n');

% Header
fprintf(txt_file, '%-20s', 'Patient');
for i = 1:length(channel_counts)
    fprintf(txt_file, ' | %-30s', sprintf('%d Channels', channel_counts(i)));
end
fprintf(txt_file, '\n');
fprintf(txt_file, '%s\n', repmat('-', 1, 20 + length(channel_counts) * 34));

% Data rows
for p = 1:length(patients)
    fprintf(txt_file, '%-20s', patients{p});
    for c = 1:length(channel_counts)
        if isempty(table_data{p, c})
            fprintf(txt_file, ' | %-30s', '-');
        else
            % Truncate if too long
            session_str = table_data{p, c};
            if length(session_str) > 30
                session_str = [session_str(1:27) '...'];
            end
            fprintf(txt_file, ' | %-30s', session_str);
        end
    end
    fprintf(txt_file, '\n');
end

fclose(txt_file);

% Create a summary count table
summary_counts = zeros(length(patients), length(channel_counts));
for p = 1:length(patients)
    for c = 1:length(channel_counts)
        if ~isempty(table_data{p, c})
            % Count number of sessions (separated by commas)
            summary_counts(p, c) = length(strfind(table_data{p, c}, ',')) + 1;
        end
    end
end

summary_table = array2table(summary_counts, 'VariableNames', col_names, 'RowNames', patients);

fprintf('\n========================================\n');
fprintf('SESSION COUNT SUMMARY\n');
fprintf('(Number of sessions per channel count)\n');
fprintf('========================================\n\n');
disp(summary_table);

% Save summary
writetable(summary_table, fullfile(main_dir, 'patient_channel_summary.csv'), 'WriteRowNames', true);

fprintf('\n✅ Tables saved:\n');
fprintf('   📄 %s\n', fullfile(main_dir, 'patient_channel_table.csv'));
fprintf('   📄 %s\n', fullfile(main_dir, 'patient_channel_table.txt'));
fprintf('   📄 %s\n', fullfile(main_dir, 'patient_channel_summary.csv'));

% ========================================
% COUNT PATIENTS WITH 22 CHANNELS BY GROUP
% ========================================

% Load patient data if not already in workspace
if ~exist('patient_data', 'var')
    load(fullfile(main_dir, 'patient_session_data.mat'));
    patients = fieldnames(patient_data);
end

% Initialize counters and lists
epilepsy_22ch = {};
non_epilepsy_22ch = {};
epilepsy_all = {};
non_epilepsy_all = {};

% Analyze each patient
for p = 1:length(patients)
    patient_id = patients{p};
    sessions = fieldnames(patient_data.(patient_id));
    
    % Determine group from file path (check first session)
    first_session = sessions{1};
    file_path = patient_data.(patient_id).(first_session).file_path;
    
    % Check if patient is in epilepsy or non_epilepsy group
    is_epilepsy = contains(file_path, 'epilepsy', 'IgnoreCase', true) && ...
                  ~contains(file_path, 'non_epilepsy', 'IgnoreCase', true) && ...
                  ~contains(file_path, 'nonepilepsy', 'IgnoreCase', true);
    
    % Check if patient has any session with 22 channels
    has_22_channels = false;
    
    for s = 1:length(sessions)
        session = sessions{s};
        sess_data = patient_data.(patient_id).(session);
        
        % Count successfully created channels
        num_channels = length(sess_data.bipolar_channels) - length(sess_data.skipped_channels);
        
        if num_channels == 22
            has_22_channels = true;
            break;
        end
    end
    
    % Categorize patient
    if is_epilepsy
        epilepsy_all{end+1} = patient_id;
        if has_22_channels
            epilepsy_22ch{end+1} = patient_id;
        end
    else
        non_epilepsy_all{end+1} = patient_id;
        if has_22_channels
            non_epilepsy_22ch{end+1} = patient_id;
        end
    end
end

% Print results
fprintf('\n========================================\n');
fprintf('PATIENTS WITH 22 CHANNELS BY GROUP\n');
fprintf('========================================\n\n');

fprintf('EPILEPSY GROUP:\n');
fprintf('  Total patients: %d\n', length(epilepsy_all));
fprintf('  Patients with 22-channel sessions: %d\n', length(epilepsy_22ch));
fprintf('  Percentage: %.1f%%\n\n', (length(epilepsy_22ch)/length(epilepsy_all))*100);

if ~isempty(epilepsy_22ch)
    fprintf('  Patients with 22 channels:\n');
    for i = 1:length(epilepsy_22ch)
        fprintf('    %d. %s\n', i, epilepsy_22ch{i});
    end
    fprintf('\n');
end

fprintf('NON-EPILEPSY GROUP:\n');
fprintf('  Total patients: %d\n', length(non_epilepsy_all));
fprintf('  Patients with 22-channel sessions: %d\n', length(non_epilepsy_22ch));
fprintf('  Percentage: %.1f%%\n\n', (length(non_epilepsy_22ch)/length(non_epilepsy_all))*100);

if ~isempty(non_epilepsy_22ch)
    fprintf('  Patients with 22 channels:\n');
    for i = 1:length(non_epilepsy_22ch)
        fprintf('    %d. %s\n', i, non_epilepsy_22ch{i});
    end
    fprintf('\n');
end

fprintf('========================================\n');
fprintf('SUMMARY:\n');
fprintf('  Total patients: %d\n', length(patients));
fprintf('  Epilepsy: %d (%.1f%%)\n', length(epilepsy_all), (length(epilepsy_all)/length(patients))*100);
fprintf('  Non-Epilepsy: %d (%.1f%%)\n', length(non_epilepsy_all), (length(non_epilepsy_all)/length(patients))*100);
fprintf('  Patients with 22 channels: %d (%.1f%%)\n', ...
    length(epilepsy_22ch) + length(non_epilepsy_22ch), ...
    ((length(epilepsy_22ch) + length(non_epilepsy_22ch))/length(patients))*100);
fprintf('========================================\n\n');

% Create visualization
figure('Position', [100, 100, 900, 600]);

% Subplot 1: Bar chart comparison
subplot(1, 2, 1);
categories = categorical({'Epilepsy', 'Non-Epilepsy'});
categories = reordercats(categories, {'Epilepsy', 'Non-Epilepsy'});
y_data = [length(epilepsy_22ch), length(non_epilepsy_22ch); ...
          length(epilepsy_all)-length(epilepsy_22ch), length(non_epilepsy_all)-length(non_epilepsy_22ch)];
bar(categories, y_data, 'stacked');
ylabel('Number of Patients');
title('Patients with/without 22-Channel Sessions');
legend('With 22 channels', 'Without 22 channels', 'Location', 'northwest');
grid on;

% Add value labels on bars
for i = 1:2
    text(i, y_data(1,i)/2, sprintf('%d', y_data(1,i)), ...
        'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 12);
    text(i, y_data(1,i) + y_data(2,i)/2, sprintf('%d', y_data(2,i)), ...
        'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 12);
end

% Subplot 2: Pie charts
subplot(1, 2, 2);

% Create pie chart data
pie_labels = {'Epilepsy (22ch)', 'Epilepsy (other)', 'Non-Epilepsy (22ch)', 'Non-Epilepsy (other)'};
pie_data = [length(epilepsy_22ch), length(epilepsy_all)-length(epilepsy_22ch), ...
            length(non_epilepsy_22ch), length(non_epilepsy_all)-length(non_epilepsy_22ch)];
colors = [0.8 0.2 0.2; 1 0.6 0.6; 0.2 0.6 0.8; 0.6 0.8 1];
pie(pie_data);
colormap(colors);
title('Patient Distribution by Group and Channel Count');
legend(pie_labels, 'Location', 'southoutside');

sgtitle('22-Channel Analysis by Epilepsy Group', 'FontSize', 14, 'FontWeight', 'bold');

% Save figure
saveas(gcf, fullfile(main_dir, 'epilepsy_22ch_analysis.png'));
saveas(gcf, fullfile(main_dir, 'epilepsy_22ch_analysis.fig'));

% Save data to file
summary_file = fopen(fullfile(main_dir, '22ch_group_analysis.txt'), 'w');
fprintf(summary_file, '========================================\n');
fprintf(summary_file, 'PATIENTS WITH 22 CHANNELS BY GROUP\n');
fprintf(summary_file, 'Generated: %s\n', datestr(now));
fprintf(summary_file, '========================================\n\n');

fprintf(summary_file, 'EPILEPSY GROUP:\n');
fprintf(summary_file, '  Total patients: %d\n', length(epilepsy_all));
fprintf(summary_file, '  Patients with 22-channel sessions: %d (%.1f%%)\n\n', ...
    length(epilepsy_22ch), (length(epilepsy_22ch)/length(epilepsy_all))*100);

fprintf(summary_file, '  List of patients with 22 channels:\n');
for i = 1:length(epilepsy_22ch)
    fprintf(summary_file, '    %d. %s\n', i, epilepsy_22ch{i});
end

fprintf(summary_file, '\n\nNON-EPILEPSY GROUP:\n');
fprintf(summary_file, '  Total patients: %d\n', length(non_epilepsy_all));
fprintf(summary_file, '  Patients with 22-channel sessions: %d (%.1f%%)\n\n', ...
    length(non_epilepsy_22ch), (length(non_epilepsy_22ch)/length(non_epilepsy_all))*100);

fprintf(summary_file, '  List of patients with 22 channels:\n');
for i = 1:length(non_epilepsy_22ch)
    fprintf(summary_file, '    %d. %s\n', i, non_epilepsy_22ch{i});
end

fclose(summary_file);

fprintf('✅ Analysis saved:\n');
fprintf('   📄 %s\n', fullfile(main_dir, '22ch_group_analysis.txt'));
fprintf('   📈 %s\n', fullfile(main_dir, 'epilepsy_22ch_analysis.png'));