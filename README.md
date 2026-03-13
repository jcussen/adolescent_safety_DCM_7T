# Adolescent Safety DCM 7T

## Project Overview
This repository contains the MATLAB/SPM code used for subject-level dynamic causal modelling (DCM) and group-level Parametric Empirical Bayes (PEB) analyses for the 7T adolescent safety-learning dataset.

The workflow is organised so that repository-relative paths are used by default. Data inputs are expected under `data/`, and group outputs are written to `results/`.

## Repository Layout
- `dcm/` - first-level GLM, VOI extraction, DCM specification, DCM loading/fitting, and shared path helpers.
- `peb/` - group-level PEB summary script.

## Expected Data Layout
```text
data/
  fmriprep/
    sub-01/
      func/
  masks/
    MNI152_T1_2mm_brain_mask_new_bin_clean.nii
    hipp_bin_clean.nii
    postvmpfc_bin_clean.nii
    amygdala_bin_clean.nii
    striatum_bin_clean.nii
  onsets/
    concatenated/
      sub-01_safety_Task.txt
      sub-01_safety_FirstStim_animals_pm.txt
      ...
  output/
results/
```

## Dependencies
- MATLAB with SPM on the MATLAB path.
- Preprocessed functional data in `data/fmriprep/sub-XX/func/`.
- Onset text files in `data/onsets/concatenated/`.
- ROI and brain masks in `data/masks/`.

If SPM is not already on the MATLAB path, set `SPM_DIR` before running `peb/peb.m`.

## Typical Workflow
1. Run `dcm/first_level_dcm.m` for each subject and analysis `version`.
2. Run `dcm/extract_vois.m` for each subject.
3. Run `dcm/dcm_spec.m` to build one DCM per subject and specification.
4. Run `dcm/dcm_load_fit.m` to assemble and fit the group cell array.
5. Run `peb/peb.m` for the group-level PEB summary outputs.

See the folder-specific READMEs in `dcm/` and `peb/` for the expected inputs and run details for each stage.
