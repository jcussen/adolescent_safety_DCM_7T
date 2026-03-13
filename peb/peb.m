script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
dcm_dir = fullfile(repo_root, 'dcm');
if exist(dcm_dir, 'dir')
    addpath(dcm_dir);
end

spm_dir = getenv('SPM_DIR');
if ~isempty(spm_dir)
    addpath(spm_dir);
end

spm('Defaults', 'fMRI');
spm_jobman('initcfg');
clearvars -except dcm_dir repo_root script_dir spm_dir

paths = project_paths(dcm_dir);

version = '0723';
spec = 'pm_four_rois_striatum_main_effects';
gcm_file = sprintf('GCM_%s_%s.mat', version, spec);
gcm_path = fullfile(paths.output_root, version, gcm_file);
outDir = fullfile(paths.results_root, version, spec);

if ~exist(outDir, 'dir')
    mkdir(outDir);
    fprintf('Created %s\n', outDir);
end

GCM = load(gcm_path).GCM;
roi = {'hipp', 'postvmpfc', 'amygdala', 'striatum'};
thresh = 0.10;

%% ------------------------------------------------------------------------
% 1) Basic diagnostic: variance explained per subject
%% ------------------------------------------------------------------------

vals = cellfun(@(x) pickfield(x, 'diagnostics', @nan), spm_dcm_fmri_check(GCM)); %#ok<*NASGU>
writematrix(vals, fullfile(outDir, 'variance_explained.txt'));

%% ------------------------------------------------------------------------
% 2) PEB for A- and B-matrices
%% ------------------------------------------------------------------------

results = {};
results = run_peb(GCM, 'A', roi, thresh, results);
results = run_peb(GCM, 'B', roi, thresh, results);

writetable(cell2table(results, ...
           'VariableNames', {'matrix', 'condition', 'source', 'target', 'Ep', 'Pp', 'Cp'}), ...
           fullfile(outDir, 'connections.csv'));
fprintf('Saved connection table.\n');

%% ------------------------------------------------------------------------
% 3) Save a couple of useful figures
%% ------------------------------------------------------------------------

save_figs(outDir, {'posterior_probabilities','driving_input_BMC'});

%% ========================================================================
%                       ----  HELPER FUNCTIONS  ----
%% ========================================================================

function val = pickfield(s,f,def)
% Return s.(f)(1) when present; otherwise call the default function.
    if isfield(s,f) && ~isempty(s.(f))
        val = s.(f)(1);
    else
        val = def();
    end
end
% -------------------------------------------------------------------------
function results = run_peb(GCM,mat,roi,thr,results)
% Run a group PEB for one parameter class.
    M.X = ones(numel(GCM), 1);
    [PEB, ~] = spm_dcm_peb(GCM, M, {mat});
    [BMA, ~] = spm_dcm_peb_bmc(PEB);

    keep = find(full(BMA.Pp) >= thr);
    for p = keep(:)'
        [cond, src, tgt] = decode_label(BMA.Pnames{p}, mat, roi);
        Ep = full(BMA.Ep(p));
        Pp = full(BMA.Pp(p));
        Cp = full(BMA.Cp(p, p));
        fprintf('%s%s: %s -> %s   Ep=%.4f  Pp=%.3f  Cp=%.3f\n', mat, cond, src, tgt, Ep, Pp, Cp);
        results(end+1, :) = {mat, cond, src, tgt, Ep, Pp, Cp}; %#ok<AGROW>
    end
end
% -------------------------------------------------------------------------
function [cond,src,tgt] = decode_label(lbl,mat,roi)
% Translate labels like 'A(2,1)' or 'B(3,2,1)' into readable parts.
    if mat=="A"
        v = sscanf(lbl, 'A(%d,%d)');
        cond = '';
    else
        v = sscanf(lbl, 'B(%d,%d,%d)');
        cond = sprintf('%d', v(3));
    end
    src = roi{v(2)};
    tgt = roi{v(1)};
end
% -------------------------------------------------------------------------
function save_figs(outDir,names)
% Export requested open figures in numeric order.
    figs = findall(groot, 'Type', 'figure');
    [~, idx] = sort([figs.Number]);
    figs = figs(idx);

    for k = 1:numel(names)
        if k + 1 <= numel(figs)
            exportgraphics(figs(k + 1), fullfile(outDir, [names{k} '.png']), ...
                           'Resolution', 300, 'BackgroundColor', 'white');
        end
    end
end
close(gcf);
