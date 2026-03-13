%% Description
% Extract subject-level VOIs from the task contrast.

function extract_vois(subject_id, version)

%% SET UP
spm('Defaults', 'fMRI');
spm_jobman('initcfg');
spm_get_defaults('cmdline', true);
paths = project_paths(mfilename('fullpath'));

contrast_num = 2;
p_threshold = 0.05;

masks_dir = paths.masks_root;
output_dir = fullfile(paths.output_root, version);
masks = struct( ...
    'hipp', fullfile(masks_dir, 'hipp_bin_clean.nii'), ...
    'postvmpfc', fullfile(masks_dir, 'postvmpfc_bin_clean.nii'), ...
    'amygdala', fullfile(masks_dir, 'amygdala_bin_clean.nii'), ...
    'striatum', fullfile(masks_dir, 'striatum_bin_clean.nii') ...
);
roi_names = fieldnames(masks);

%% MAIN LOOP
disp(['Processing subject ', num2str(subject_id), '...']);
subject_id_str = sprintf('%02d', subject_id);
spm_dir = fullfile(output_dir, subject_id_str);

clear matlabbatch;

for r = 1:numel(roi_names)
    matlabbatch{r}.spm.util.voi.spmmat(1) = {fullfile(spm_dir, 'SPM.mat')};
    matlabbatch{r}.spm.util.voi.adjust = 1;
    matlabbatch{r}.spm.util.voi.session = 1;
    matlabbatch{r}.spm.util.voi.name = [roi_names{r}, '_', subject_id_str];
    matlabbatch{r}.spm.util.voi.roi{1}.spm.spmmat = {''};
    matlabbatch{r}.spm.util.voi.roi{1}.spm.contrast = contrast_num;
    matlabbatch{r}.spm.util.voi.roi{1}.spm.conjunction = 1;
    matlabbatch{r}.spm.util.voi.roi{1}.spm.threshdesc = 'none';
    matlabbatch{r}.spm.util.voi.roi{1}.spm.thresh = p_threshold;
    matlabbatch{r}.spm.util.voi.roi{1}.spm.extent = 0;
    matlabbatch{r}.spm.util.voi.roi{1}.spm.mask = struct('contrast', {}, 'thresh', {}, 'mtype', {});
    matlabbatch{r}.spm.util.voi.roi{2}.mask.image = {[masks.(roi_names{r}) ',1']};
    matlabbatch{r}.spm.util.voi.roi{2}.mask.threshold = 0.5;
    matlabbatch{r}.spm.util.voi.expression = 'i1 & i2';
end

spm_jobman('run', matlabbatch);

%% COUNT VOXELS
for r = 1:numel(roi_names)
    voi_nii = fullfile(spm_dir, ['VOI_', roi_names{r}, '_', subject_id_str, '_mask.nii']);
    if exist(voi_nii, 'file')
        nvox = nnz(spm_read_vols(spm_vol(voi_nii)));
        fprintf('Subject %s  ROI %-10s : %d voxels in final mask\n', ...
                subject_id_str, roi_names{r}, nvox);
    else
        fprintf(2, 'WARNING: VOI file %s not found - skipping voxel count\n', voi_nii);
    end
end
