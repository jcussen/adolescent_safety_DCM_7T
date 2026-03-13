%% Description
% This function specifies the DCMs to estimate.

function dcm_spec(subject_id, version, spec)
%% SET UP
spm('Defaults', 'fMRI');
spm_jobman('initcfg');
spm_get_defaults('cmdline', true);
paths = project_paths(mfilename('fullpath'));

TR = 0.8;
TE = 0.0222;
nregions = 4;
include = [1 1 1 0 0];
nconditions = 3;
hipp = 1;
postvmpfc = 2;
amygdala = 3;
striatum = 4;

subject_id_str = sprintf('%02d', subject_id);
output_dir = fullfile(paths.output_root, version);
spm_dir = fullfile(output_dir, subject_id_str);

%% DEFINE MATRICES
a = zeros(nregions, nregions);
a(striatum, amygdala) = 1;
a(amygdala, striatum) = 1;

a(striatum, hipp) = 1;

a(striatum, postvmpfc) = 1;
a(postvmpfc, striatum) = 1;

a(amygdala, postvmpfc) = 1;
a(postvmpfc, amygdala) = 1;

a(amygdala, hipp) = 1;
a(hipp, amygdala) = 1;

a(postvmpfc, hipp) = 1;
a(hipp, postvmpfc) = 1;

c = zeros(nregions, nconditions);
c(amygdala, 1) = 1;
c(hipp, 1) = 1;
c(postvmpfc, 1) = 1;
c(striatum, 1) = 1;

d = zeros(nregions, nregions, 0);

b = zeros(nregions, nregions, nconditions);

for cond = 2:nconditions
    b(hipp, amygdala, cond) = 1;
    b(amygdala, hipp, cond) = 1;

    b(amygdala, postvmpfc, cond) = 1;
    b(postvmpfc, amygdala, cond) = 1;

    b(striatum, amygdala, cond) = 1;
    b(postvmpfc, hipp, cond) = 1;

    b(postvmpfc, striatum, cond) = 1;
    b(striatum, postvmpfc, cond) = 1;
end

%% LOAD VOIs
SPM = load(fullfile(spm_dir, 'SPM.mat')); 
SPM = SPM.SPM;

names = cellfun(@(c) c{1}, {SPM.Sess.U.name}, 'UniformOutput', false);
disp(names');

voi_files = { ...
    fullfile(spm_dir, ['VOI_hipp_', subject_id_str, '_1.mat']), ...
    fullfile(spm_dir, ['VOI_postvmpfc_', subject_id_str, '_1.mat']), ...
    fullfile(spm_dir, ['VOI_amygdala_', subject_id_str, '_1.mat']), ...
    fullfile(spm_dir, ['VOI_striatum_', subject_id_str, '_1.mat'])};

for r = 1:length(voi_files)
    XY = load(voi_files{r});
    xY_temp = XY.xY;
    xY_temp.xY = XY.Y;
    xY(r) = xY_temp;
end

%% SPECIFY DCM
s = struct();
s.name = subject_id_str;
s.u = include;
s.delays = repmat(TR / 2, 1, nregions);
s.TE = TE;
s.nonlinear = false;
s.two_state = false;
s.stochastic = false;
s.centre = true;
s.induced = 0;
s.a = a;
s.b = b;
s.c = c;
s.d = d;
DCM = spm_dcm_specify(SPM, xY, s);

save(fullfile(spm_dir, ['DCM_', spec, '_', subject_id_str, '.mat']), 'DCM');

%% SANITY CHECKS
whos DCM
size(DCM.U.u)
for i = 1:numel(DCM.U.name)
    fprintf('Input %2d : %s\n', i, DCM.U.name{i});
end

end
