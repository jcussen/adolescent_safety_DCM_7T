function first_level_dcm(subject_id, version)

%% SET UP
spm('Defaults', 'fMRI');
spm_jobman('initcfg');
spm_get_defaults('cmdline', true);
paths = project_paths(mfilename('fullpath'));

% Parameters
conditions = { ...
    'Task', ...
    'FirstStim_animals_pm', ...
    'FirstStim_weapons_pm', ...
    'SecondStim_animals_pm', ...
    'SecondStim_weapons_pm' ...
};
num_runs = 4;
TR = 0.8;
hpf_cutoff = 100;

subject_id_str = sprintf('%02d', subject_id);
sub_dir = fullfile(paths.fmriprep_root, ['sub-' subject_id_str], 'func');
output_dir = fullfile(paths.output_root, version);
sub_output_dir = fullfile(output_dir, subject_id_str);
mask_file = fullfile(paths.masks_root, 'MNI152_T1_2mm_brain_mask_new_bin_clean.nii');
onset_dir = paths.onsets_root;

%% 1) CREATE BATCH AND DIRECTORIES

clear matlabbatch;
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = {output_dir};
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name   = subject_id_str;

%% 2) SPECIFY

matlabbatch{2}.spm.stats.fmri_spec.dir            = {sub_output_dir};
matlabbatch{2}.spm.stats.fmri_spec.timing.units   = 'secs';
matlabbatch{2}.spm.stats.fmri_spec.timing.RT      = TR;
matlabbatch{2}.spm.stats.fmri_spec.timing.fmri_t  = 16;
matlabbatch{2}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
matlabbatch{2}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{2}.spm.stats.fmri_spec.volt           = 1;
matlabbatch{2}.spm.stats.fmri_spec.global         = 'None';
matlabbatch{2}.spm.stats.fmri_spec.mthresh        = 0.01;
matlabbatch{2}.spm.stats.fmri_spec.mask           = {[mask_file ',1']};
matlabbatch{2}.spm.stats.fmri_spec.cvi            = 'FAST';

all_scans = {};
num_volumes_per_run = [];
for run = 1:num_runs
    run_str = num2str(run);
    pattern = ['^sub-' subject_id_str '_task-safety_run-' run_str '_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold\.nii$'];
    files = spm_select('ExtFPList', sub_dir, pattern, Inf);
    if isempty(files)
        fprintf('Subject %s - run %d missing, skipping\n', subject_id_str, run);
        continue;
    end
    scans = cellstr(files);
    all_scans = [all_scans; scans]; %#ok<AGROW>
    num_volumes_per_run = [num_volumes_per_run; numel(scans)]; %#ok<AGROW>
end
num_scans_per_run = num_volumes_per_run';

matlabbatch{2}.spm.stats.fmri_spec.sess.scans = all_scans;
matlabbatch{2}.spm.stats.fmri_spec.sess.multi     = {''};
confounds_file = fullfile(sub_dir, sprintf('s_sub-%s_task-safety_concat-confounds.txt', subject_id_str));
M = readmatrix(confounds_file, 'Delimiter', '\t');
M_filled = fillmissing(M, 'next');
writematrix(M_filled, confounds_file, 'Delimiter', 'tab');

n_scans = numel(all_scans);
n_confounds = size(M_filled, 1);

fprintf('[sub-%s] scans = %d   confound rows = %d\n', ...
        subject_id_str, n_scans, n_confounds);

if n_confounds ~= n_scans
    error('[sub-%s] mismatch: %d confound rows but %d scans - aborting', ...
           subject_id_str, n_confounds, n_scans);
end

matlabbatch{2}.spm.stats.fmri_spec.sess.multi_reg = {confounds_file};
matlabbatch{2}.spm.stats.fmri_spec.sess.regress   = struct('name', {}, 'val', {});
matlabbatch{2}.spm.stats.fmri_spec.sess.hpf       = hpf_cutoff;

for c = 1:numel(conditions)
    X = load(fullfile(onset_dir, sprintf('sub-%s_safety_%s.txt', subject_id_str, conditions{c})));
    matlabbatch{2}.spm.stats.fmri_spec.sess.cond(c).name     = conditions{c};
    matlabbatch{2}.spm.stats.fmri_spec.sess.cond(c).onset    = X(:, 1)';
    matlabbatch{2}.spm.stats.fmri_spec.sess.cond(c).duration = X(:, 2)';
    matlabbatch{2}.spm.stats.fmri_spec.sess.cond(c).tmod     = 0;
    matlabbatch{2}.spm.stats.fmri_spec.sess.cond(c).orth     = 0;

    if size(X, 2) >= 3 && ~strcmp(conditions{c}, 'Task')
        matlabbatch{2}.spm.stats.fmri_spec.sess.cond(c).pmod = ...
            struct('name', 'PM', 'param', X(:, 3)', 'poly', 1);
    else
        matlabbatch{2}.spm.stats.fmri_spec.sess.cond(c).pmod = struct([]);
    end
end

%% 3) ESTIMATE

matlabbatch{3}.spm.stats.fmri_est.spmmat = { fullfile(sub_output_dir,'SPM.mat') };
matlabbatch{3}.spm.stats.fmri_est.method.Classical = 1;

%% 4) CONTRASTS

matlabbatch{4}.spm.stats.con.spmmat = { fullfile(sub_output_dir,'SPM.mat') };

E = [ ...
    1 0 0 0 0 0 0 0 0;   % Task
    0 1 1 0 0 0 0 0 0;   % FirstStim_animals
    0 0 0 1 1 0 0 0 0;   % FirstStim_weapons
    0 0 0 0 0 1 1 0 0;   % SecondStim_animals
    0 0 0 0 0 0 0 1 1];  % SecondStim_weapons

matlabbatch{4}.spm.stats.con.consess{1}.fcon.name    = 'Effects of interest';
matlabbatch{4}.spm.stats.con.consess{1}.fcon.weights = E;
matlabbatch{4}.spm.stats.con.consess{1}.fcon.sessrep = 'none';

matlabbatch{4}.spm.stats.con.consess{2}.tcon.name     = 'Task'; 
matlabbatch{4}.spm.stats.con.consess{2}.tcon.weights = [1 0 0 0 0 0 0 0 0];
matlabbatch{4}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

matlabbatch{4}.spm.stats.con.consess{3}.tcon.name     = 'FirstStim_animals_pm'; 
matlabbatch{4}.spm.stats.con.consess{3}.tcon.weights = [0 0 1 0 0 0 0 0 0];
matlabbatch{4}.spm.stats.con.consess{3}.tcon.sessrep = 'none';

matlabbatch{4}.spm.stats.con.consess{4}.tcon.name     = 'FirstStim_weapons_pm'; 
matlabbatch{4}.spm.stats.con.consess{4}.tcon.weights = [0 0 0 0 1 0 0 0 0];
matlabbatch{4}.spm.stats.con.consess{4}.tcon.sessrep = 'none';

matlabbatch{4}.spm.stats.con.consess{5}.tcon.name     = 'SecondStim_animals_pm'; 
matlabbatch{4}.spm.stats.con.consess{5}.tcon.weights = [0 0 0 0 0 0 1 0 0];
matlabbatch{4}.spm.stats.con.consess{5}.tcon.sessrep = 'none';

matlabbatch{4}.spm.stats.con.consess{6}.tcon.name     = 'SecondStim_weapons_pm'; 
matlabbatch{4}.spm.stats.con.consess{6}.tcon.weights = [0 0 0 0 0 0 0 0 1];
matlabbatch{4}.spm.stats.con.consess{6}.tcon.sessrep = 'none';
matlabbatch{4}.spm.stats.con.delete = 0;

%% RUN

spm_jobman('run', matlabbatch(1:2)); % Run directory creation and model specification
SPM = spm_fmri_concatenate(fullfile(sub_output_dir, 'SPM.mat'), num_scans_per_run);
save(fullfile(sub_output_dir, 'SPM.mat'), 'SPM');
spm_jobman('run', matlabbatch(3:end)); % Run model estimation and contrasts
end
