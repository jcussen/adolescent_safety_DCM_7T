%% Description
% This function estimates/fits the DCMs for all participants.

function dcm_load_fit(version, spec)
%% SET UP
spm('Defaults', 'fMRI');
spm_jobman('initcfg');
spm_get_defaults('cmdline', true);
paths = project_paths(mfilename('fullpath'));

output_dir = fullfile(paths.output_root, version);

subject_ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 23, 24, 25, 26, 28, 29, 30, 31, 32, 33, 34];
num_subjects = numel(subject_ids);

filelist = struct('folder', {}, 'name', {});

%% LOAD DCMs
for i = 1:num_subjects
    subject_id = subject_ids(i);
    subject_id_str = sprintf('%02d', subject_id);
    sub_dir = fullfile(output_dir, subject_id_str);

    DCM_full = fullfile(sub_dir, ['DCM_', spec, '_', subject_id_str, '.mat']);
    cur_filelist = dir(DCM_full);
    filelist = [filelist, cur_filelist]; %#ok<AGROW>
end

%% FIT DCMs
GCM = fullfile({filelist.folder}, {filelist.name})';
GCM = spm_dcm_load(GCM);
GCM = spm_dcm_peb_fit(GCM);
save(fullfile(output_dir, ['GCM_', version, '_', spec, '.mat']), 'GCM', '-v7.3');

end
