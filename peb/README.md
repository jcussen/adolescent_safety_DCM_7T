# PEB Pipeline

This folder contains the group-level PEB summary script for the fitted DCMs produced in `dcm/`.

## Inputs
- A fitted GCM file written by `dcm/dcm_load_fit.m`
- SPM on the MATLAB path, or `SPM_DIR` set in the environment

## Script
1. `peb.m` loads one `GCM_<version>_<spec>.mat`, computes variance explained, runs PEB for the A and B matrices, and exports summary tables and figures.

## Configuration
Edit the `version` and `spec` values near the top of `peb.m` before running. By default the script expects:

- GCM input: `data/output/<version>/GCM_<version>_<spec>.mat`
- Results output: `results/<version>/<spec>/`

## Example Usage
```matlab
run('peb/peb.m')
```

## Outputs
- `variance_explained.txt`
- `connections.csv`
- exported figure PNGs in `results/<version>/<spec>/`
