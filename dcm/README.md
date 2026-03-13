# DCM Pipeline

This folder contains the subject-level MATLAB/SPM pipeline for the safety-learning DCM analysis. All scripts now resolve paths relative to the repository root via `project_paths.m`.

## Inputs
- fMRIPrep outputs in `data/fmriprep/sub-XX/func/`
- onset text files in `data/onsets/concatenated/`
- mask files in `data/masks/`

## Scripts
1. `first_level_dcm.m` specifies and estimates the first-level GLM, concatenates runs, and writes contrasts.
2. `extract_vois.m` extracts subject-specific VOIs from the task contrast and anatomical masks.
3. `dcm_spec.m` builds the four-region bilinear DCM for one subject.
4. `dcm_load_fit.m` loads all subject DCMs for a `version/spec` combination and fits the group cell array.

## Example Usage
```matlab
first_level_dcm(1, '0723');
extract_vois(1, '0723');
dcm_spec(1, '0723', 'pm_four_rois_striatum_main_effects');
dcm_load_fit('0723', 'pm_four_rois_striatum_main_effects');
```

## Outputs
- Subject-level SPM and VOI outputs: `data/output/<version>/<subject_id>/`
- Group GCM file: `data/output/<version>/GCM_<version>_<spec>.mat`
