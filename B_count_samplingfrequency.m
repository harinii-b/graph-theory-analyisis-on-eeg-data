%% Find EEG files with sampling rate != 250 or 256 Hz
clear; clc;

%% Set your base folder
base_folder = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_250hz';

fprintf('=== Searching for files with fs != 250Hz ===\n');
fprintf('Base folder: %s\n\n', base_folder);

%% Find all *_processed.mat files
mat_files = dir(fullfile(base_folder, '**', '*_processed.mat'));
fprintf('Found %d total *_processed.mat files\n\n', length(mat_files));

if isempty(mat_files)
    fprintf('No .mat files found in the specified folder.\n');
    return;
end

%% Initialize results
bad_fs_files = {};
file_info = [];

%% Check each file
fprintf('Checking files...\n');
for i = 1:length(mat_files)
    filepath = fullfile(mat_files(i).folder, mat_files(i).name);

    try
        % Load only the variables we need (faster)
        vars = whos('-file', filepath);
        var_names = {vars.name};

        % Try to load 'fs' variable
        if ismember('fs', var_names)
            data = load(filepath, 'fs');
            fs = data.fs;
        elseif ismember('sample_rate', var_names)
            data = load(filepath, 'sample_rate');
            fs = data.sample_rate;
        elseif ismember('sampling_rate', var_names)
            data = load(filepath, 'sampling_rate');
            fs = data.sampling_rate;
        else
            % If no fs variable, load entire file
            data = load(filepath);
            if isfield(data, 'fs')
                fs = data.fs;
            elseif isfield(data, 'sample_rate')
                fs = data.sample_rate;
            elseif isfield(data, 'sampling_rate')
                fs = data.sampling_rate;
            else
                fprintf('⚠ Cannot find sampling rate in: %s\n', mat_files(i).name);
                continue;
            end
        end

        % Check if NOT 250 
        if fs ~= 250 
            bad_fs_files{end+1} = filepath;
            file_info = [file_info; struct('filename', mat_files(i).name, ...
                                           'folder', mat_files(i).folder, ...
                                           'fullpath', filepath, ...
                                           'fs', fs)];
            fprintf('✗ [fs = %.1f Hz] %s\n', fs, filepath);
        end

    catch ME
        fprintf('⚠ Error reading: %s\n   %s\n', mat_files(i).name, ME.message);
    end

    % Progress indicator
    if mod(i, 50) == 0
        fprintf('Progress: %d/%d files checked...\n', i, length(mat_files));
    end
end

%% Display results
fprintf('\n=== RESULTS ===\n');
fprintf('Total files checked: %d\n', length(mat_files));
fprintf('Files with fs != 250Hz: %d\n', length(bad_fs_files));

if ~isempty(file_info)
    fprintf('\n=== FULL FILE PATHS (fs != 250 or 256 Hz) ===\n');
    for i = 1:length(file_info)
        fprintf('%d. [fs = %.1f Hz]\n', i, file_info(i).fs);
        fprintf('   %s\n\n', file_info(i).fullpath);
    end

    % Save results to CSV
    output_file = fullfile(base_folder, 'bad_fs_files.csv');
    T = struct2table(file_info);
    writetable(T, output_file);
    fprintf('✓ Results saved to: %s\n', output_file);

    % Save just the paths to a text file for easy copying
    paths_file = fullfile(base_folder, 'bad_fs_file_paths.txt');
    fid = fopen(paths_file, 'w');
    fprintf(fid, 'Files with fs != 250 or 256 Hz\n');
    fprintf(fid, 'Generated: %s\n\n', datetime('now'));
    for i = 1:length(file_info)
        fprintf(fid, '%s\n', file_info(i).fullpath);
    end
    fclose(fid);
    fprintf('✓ File paths saved to: %s\n', paths_file);

    % Create summary by sampling rate
    fprintf('\n=== Summary by Sampling Rate ===\n');
    unique_fs = unique([file_info.fs]);
    for fs_val = unique_fs
        count = sum([file_info.fs] == fs_val);
        fprintf('  %d files with fs = %.1f Hz\n', count, fs_val);
    end
else
    fprintf('\n✓ All files have fs = 250 Hz!\n');
end


% %% Delete sessions with sampling rates other than 250 or 256 Hz (NO CONFIRMATION)
% clear; clc;
% 
% %% Set your base folder
% base_folder = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_final';
% 
% fprintf('=== Finding sessions with fs != 250 or 256 Hz ===\n');
% fprintf('Base folder: %s\n\n', base_folder);
% 
% %% Find all *_processed.mat files
% mat_files = dir(fullfile(base_folder, '**', '*_processed.mat'));
% fprintf('Found %d *_processed.mat files\n\n', length(mat_files));
% 
% if isempty(mat_files)
%     fprintf('No *_processed.mat files found in the specified folder.\n');
%     return;
% end
% 
% %% Check each file and identify sessions to delete
% session_info = struct();
% 
% fprintf('Checking files...\n');
% for i = 1:length(mat_files)
%     filepath = fullfile(mat_files(i).folder, mat_files(i).name);
% 
%     try
%         % Load only the variables we need (faster)
%         vars = whos('-file', filepath);
%         var_names = {vars.name};
% 
%         % Try to load 'fs' variable
%         if ismember('fs', var_names)
%             data = load(filepath, 'fs');
%             fs = data.fs;
%         elseif ismember('sample_rate', var_names)
%             data = load(filepath, 'sample_rate');
%             fs = data.sample_rate;
%         elseif ismember('sampling_rate', var_names)
%             data = load(filepath, 'sampling_rate');
%             fs = data.sampling_rate;
%         else
%             % If no fs variable, load entire file
%             data = load(filepath);
%             if isfield(data, 'fs')
%                 fs = data.fs;
%             elseif isfield(data, 'sample_rate')
%                 fs = data.sample_rate;
%             elseif isfield(data, 'sampling_rate')
%                 fs = data.sampling_rate;
%             else
%                 fprintf('⚠ Cannot find sampling rate in: %s\n', mat_files(i).name);
%                 continue;
%             end
%         end
% 
%         % Check if NOT 250 or 256 Hz
%         if fs ~= 250 && fs ~= 256
%             % Extract session folder (assuming structure: .../s###_####/...)
%             folder_parts = strsplit(mat_files(i).folder, filesep);
% 
%             % Find the session folder (looks like s###_####)
%             session_folder = '';
%             session_full_path = '';
%             for j = length(folder_parts):-1:1
%                 if ~isempty(regexp(folder_parts{j}, '^s\d+_\d+$', 'once'))
%                     session_folder = folder_parts{j};
%                     session_full_path = fullfile(strjoin(folder_parts(1:j), filesep));
%                     break;
%                 end
%             end
% 
%             if ~isempty(session_full_path)
%                 if ~isfield(session_info, session_folder) || isempty(session_info.(session_folder))
%                     session_info.(session_folder) = struct('path', session_full_path, ...
%                                                            'files', {{}}, ...
%                                                            'fs_values', []);
%                 end
%                 session_info.(session_folder).files{end+1} = mat_files(i).name;
%                 session_info.(session_folder).fs_values(end+1) = fs;
% 
%                 fprintf('✗ [fs = %.1f Hz] %s\n', fs, filepath);
%             end
%         end
% 
%     catch ME
%         fprintf('⚠ Error reading: %s\n   %s\n', mat_files(i).name, ME.message);
%     end
% 
%     % Progress indicator
%     if mod(i, 50) == 0
%         fprintf('Progress: %d/%d files checked...\n', i, length(mat_files));
%     end
% end
% 
% %% Display sessions to delete
% session_names = fieldnames(session_info);
% fprintf('\n=== SESSIONS TO DELETE ===\n');
% fprintf('Found %d sessions with fs != 250 or 256 Hz\n\n', length(session_names));
% 
% if isempty(session_names)
%     fprintf('✓ All sessions have fs = 250 or 256 Hz. Nothing to delete.\n');
%     return;
% end
% 
% for i = 1:length(session_names)
%     session = session_names{i};
%     info = session_info.(session);
%     unique_fs = unique(info.fs_values);
% 
%     fprintf('%d. Session: %s\n', i, session);
%     fprintf('   Path: %s\n', info.path);
%     fprintf('   Files with bad fs: %d\n', length(info.files));
%     fprintf('   Sampling rates found: ');
%     fprintf('%.1f ', unique_fs);
%     fprintf('Hz\n');
% end
% 
% %% Save log BEFORE deletion
% log_file = fullfile(base_folder, 'deleted_sessions_log.txt');
% fid = fopen(log_file, 'w');
% fprintf(fid, 'Deleted Sessions Log - %s\n\n', datetime('now'));
% fprintf(fid, 'Total sessions to delete: %d\n\n', length(session_names));
% for i = 1:length(session_names)
%     session = session_names{i};
%     info = session_info.(session);
%     fprintf(fid, 'Session: %s\n', session);
%     fprintf(fid, 'Path: %s\n', info.path);
%     fprintf(fid, 'Files with bad fs: %d\n', length(info.files));
%     fprintf(fid, 'Sampling rates: ');
%     fprintf(fid, '%.1f ', unique(info.fs_values));
%     fprintf(fid, 'Hz\n');
%     for j = 1:length(info.files)
%         fprintf(fid, '  - %s\n', info.files{j});
%     end
%     fprintf(fid, '\n');
% end
% fclose(fid);
% fprintf('\n✓ Log saved to: %s\n', log_file);
% 
% %% Delete sessions immediately
% fprintf('\n=== DELETING SESSIONS ===\n');
% deleted_count = 0;
% failed_count = 0;
% 
% for i = 1:length(session_names)
%     session = session_names{i};
%     session_path = session_info.(session).path;
% 
%     try
%         if exist(session_path, 'dir')
%             rmdir(session_path, 's');  % 's' flag removes folder and all contents
%             fprintf('✓ Deleted: %s\n', session_path);
%             deleted_count = deleted_count + 1;
%         else
%             fprintf('⚠ Not found (already deleted?): %s\n', session_path);
%         end
%     catch ME
%         fprintf('✗ Failed to delete %s: %s\n', session_path, ME.message);
%         failed_count = failed_count + 1;
%     end
% end
% 
% %% Summary
% fprintf('\n=== DELETION COMPLETE ===\n');
% fprintf('Successfully deleted: %d session(s)\n', deleted_count);
% fprintf('Failed to delete: %d session(s)\n', failed_count);
% fprintf('Log file: %s\n', log_file);



% %% Analyze sessions per patient by sampling rate
% clear; clc;
% 
% %% Set your base folder
% base_folder = 'C:\Users\student\Documents\CAPSTONE_DONT_DELETE_PW25_SBN_03\dataset_final';
% 
% fprintf('=== Analyzing Sessions per Patient by Sampling Rate ===\n');
% fprintf('Base folder: %s\n\n', base_folder);
% 
% %% Find all *_processed.mat files
% mat_files = dir(fullfile(base_folder, '**', '*_processed.mat'));
% fprintf('Found %d total *_processed.mat files\n\n', length(mat_files));
% 
% if isempty(mat_files)
%     fprintf('No .mat files found in the specified folder.\n');
%     return;
% end
% 
% %% Initialize patient data structure
% patient_data = struct();
% 
% %% Check each file and organize by patient and session
% fprintf('Processing files...\n');
% for i = 1:length(mat_files)
%     filepath = fullfile(mat_files(i).folder, mat_files(i).name);
% 
%     try
%         % Load fs variable
%         vars = whos('-file', filepath);
%         var_names = {vars.name};
% 
%         if ismember('fs', var_names)
%             data = load(filepath, 'fs');
%             fs = data.fs;
%         elseif ismember('sample_rate', var_names)
%             data = load(filepath, 'sample_rate');
%             fs = data.sample_rate;
%         elseif ismember('sampling_rate', var_names)
%             data = load(filepath, 'sampling_rate');
%             fs = data.sampling_rate;
%         else
%             data = load(filepath);
%             if isfield(data, 'fs')
%                 fs = data.fs;
%             elseif isfield(data, 'sample_rate')
%                 fs = data.sample_rate;
%             elseif isfield(data, 'sampling_rate')
%                 fs = data.sampling_rate;
%             else
%                 continue;
%             end
%         end
% 
%         % Extract patient and session from folder structure
%         folder_parts = strsplit(mat_files(i).folder, filesep);
% 
%         % Find session folder (pattern: s###_####)
%         session_name = '';
%         patient_name = '';
%         for j = length(folder_parts):-1:1
%             if ~isempty(regexp(folder_parts{j}, '^s\d+_\d+$', 'once'))
%                 session_name = folder_parts{j};
%                 % Patient name is typically one level up
%                 if j > 1
%                     patient_name = folder_parts{j-1};
%                 end
%                 break;
%             end
%         end
% 
%         if isempty(session_name) || isempty(patient_name)
%             continue;
%         end
% 
%         % Initialize patient if not exists
%         if ~isfield(patient_data, patient_name)
%             patient_data.(patient_name) = struct('sessions_250', {{}}, 'sessions_256', {{}}, 'sessions_other', struct());
%         end
% 
%         % Categorize session by sampling rate
%         if fs == 250
%             if ~ismember(session_name, patient_data.(patient_name).sessions_250)
%                 patient_data.(patient_name).sessions_250{end+1} = session_name;
%             end
%         elseif fs == 256
%             if ~ismember(session_name, patient_data.(patient_name).sessions_256)
%                 patient_data.(patient_name).sessions_256{end+1} = session_name;
%             end
%         else
%             % Store other sampling rates
%             if ~isfield(patient_data.(patient_name).sessions_other, ['fs_' num2str(fs)])
%                 patient_data.(patient_name).sessions_other.(['fs_' num2str(fs)]) = {};
%             end
%             if ~ismember(session_name, patient_data.(patient_name).sessions_other.(['fs_' num2str(fs)]))
%                 patient_data.(patient_name).sessions_other.(['fs_' num2str(fs)]){end+1} = session_name;
%             end
%         end
% 
%     catch ME
%         fprintf('⚠ Error processing: %s\n', mat_files(i).name);
%     end
% 
%     % Progress indicator
%     if mod(i, 100) == 0
%         fprintf('Progress: %d/%d files processed...\n', i, length(mat_files));
%     end
% end
% 
% %% Display results per patient
% fprintf('\n=== RESULTS PER PATIENT ===\n\n');
% 
% patient_names = fieldnames(patient_data);
% patient_names = sort(patient_names);  % Sort alphabetically
% 
% total_patients = length(patient_names);
% total_sessions_250 = 0;
% total_sessions_256 = 0;
% total_sessions_other = 0;
% 
% for p = 1:length(patient_names)
%     patient = patient_names{p};
%     data = patient_data.(patient);
% 
%     num_250 = length(data.sessions_250);
%     num_256 = length(data.sessions_256);
% 
%     % Count other sampling rates
%     num_other = 0;
%     other_fs_names = {};
%     if ~isempty(fieldnames(data.sessions_other))
%         other_fields = fieldnames(data.sessions_other);
%         for f = 1:length(other_fields)
%             num_other = num_other + length(data.sessions_other.(other_fields{f}));
%             other_fs_names{end+1} = other_fields{f};
%         end
%     end
% 
%     total_sessions_250 = total_sessions_250 + num_250;
%     total_sessions_256 = total_sessions_256 + num_256;
%     total_sessions_other = total_sessions_other + num_other;
% 
%     fprintf('========================================\n');
%     fprintf('PATIENT: %s\n', patient);
%     fprintf('========================================\n');
%     fprintf('Total sessions: %d\n', num_250 + num_256 + num_other);
%     fprintf('  • 250 Hz sessions: %d\n', num_250);
%     fprintf('  • 256 Hz sessions: %d\n', num_256);
%     if num_other > 0
%         fprintf('  • Other sampling rates: %d\n', num_other);
%     end
%     fprintf('\n');
% 
%     % List 250 Hz sessions
%     if num_250 > 0
%         fprintf('250 Hz Sessions:\n');
%         for s = 1:length(data.sessions_250)
%             fprintf('  %d. %s\n', s, data.sessions_250{s});
%         end
%         fprintf('\n');
%     end
% 
%     % List 256 Hz sessions
%     if num_256 > 0
%         fprintf('256 Hz Sessions:\n');
%         for s = 1:length(data.sessions_256)
%             fprintf('  %d. %s\n', s, data.sessions_256{s});
%         end
%         fprintf('\n');
%     end
% 
%     % List other sampling rate sessions
%     if num_other > 0
%         fprintf('Other Sampling Rate Sessions:\n');
%         other_fields = fieldnames(data.sessions_other);
%         for f = 1:length(other_fields)
%             fs_label = strrep(other_fields{f}, 'fs_', '');
%             fprintf('  [%s Hz]:\n', fs_label);
%             sessions = data.sessions_other.(other_fields{f});
%             for s = 1:length(sessions)
%                 fprintf('    %d. %s\n', s, sessions{s});
%             end
%         end
%         fprintf('\n');
%     end
% end
% 
% %% Summary
% fprintf('\n========================================\n');
% fprintf('OVERALL SUMMARY\n');
% fprintf('========================================\n');
% fprintf('Total patients: %d\n', total_patients);
% fprintf('Total sessions with 250 Hz: %d\n', total_sessions_250);
% fprintf('Total sessions with 256 Hz: %d\n', total_sessions_256);
% fprintf('Total sessions with other fs: %d\n', total_sessions_other);
% fprintf('Grand total sessions: %d\n', total_sessions_250 + total_sessions_256 + total_sessions_other);
% 
% %% Save to file
% output_file = fullfile(base_folder, 'patient_session_summary.txt');
% fid = fopen(output_file, 'w');
% fprintf(fid, '=== Patient Session Summary by Sampling Rate ===\n');
% fprintf(fid, 'Generated: %s\n\n', datetime('now'));
% 
% for p = 1:length(patient_names)
%     patient = patient_names{p};
%     data = patient_data.(patient);
% 
%     num_250 = length(data.sessions_250);
%     num_256 = length(data.sessions_256);
% 
%     num_other = 0;
%     if ~isempty(fieldnames(data.sessions_other))
%         other_fields = fieldnames(data.sessions_other);
%         for f = 1:length(other_fields)
%             num_other = num_other + length(data.sessions_other.(other_fields{f}));
%         end
%     end
% 
%     fprintf(fid, '========================================\n');
%     fprintf(fid, 'PATIENT: %s\n', patient);
%     fprintf(fid, '========================================\n');
%     fprintf(fid, 'Total sessions: %d\n', num_250 + num_256 + num_other);
%     fprintf(fid, '  • 250 Hz sessions: %d\n', num_250);
%     fprintf(fid, '  • 256 Hz sessions: %d\n', num_256);
%     if num_other > 0
%         fprintf(fid, '  • Other sampling rates: %d\n', num_other);
%     end
%     fprintf(fid, '\n');
% 
%     if num_250 > 0
%         fprintf(fid, '250 Hz Sessions:\n');
%         for s = 1:length(data.sessions_250)
%             fprintf(fid, '  %d. %s\n', s, data.sessions_250{s});
%         end
%         fprintf(fid, '\n');
%     end
% 
%     if num_256 > 0
%         fprintf(fid, '256 Hz Sessions:\n');
%         for s = 1:length(data.sessions_256)
%             fprintf(fid, '  %d. %s\n', s, data.sessions_256{s});
%         end
%         fprintf(fid, '\n');
%     end
% 
%     if num_other > 0
%         fprintf(fid, 'Other Sampling Rate Sessions:\n');
%         other_fields = fieldnames(data.sessions_other);
%         for f = 1:length(other_fields)
%             fs_label = strrep(other_fields{f}, 'fs_', '');
%             fprintf(fid, '  [%s Hz]:\n', fs_label);
%             sessions = data.sessions_other.(other_fields{f});
%             for s = 1:length(sessions)
%                 fprintf(fid, '    %d. %s\n', s, sessions{s});
%             end
%         end
%         fprintf(fid, '\n');
%     end
% end
% 
% fprintf(fid, '\n========================================\n');
% fprintf(fid, 'OVERALL SUMMARY\n');
% fprintf(fid, '========================================\n');
% fprintf(fid, 'Total patients: %d\n', total_patients);
% fprintf(fid, 'Total sessions with 250 Hz: %d\n', total_sessions_250);
% fprintf(fid, 'Total sessions with 256 Hz: %d\n', total_sessions_256);
% fprintf(fid, 'Total sessions with other fs: %d\n', total_sessions_other);
% fprintf(fid, 'Grand total sessions: %d\n', total_sessions_250 + total_sessions_256 + total_sessions_other);
% 
% fclose(fid);
% fprintf('\n✓ Summary saved to: %s\n', output_file);