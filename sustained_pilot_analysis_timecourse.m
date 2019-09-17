cfg.datadir = fullfile('/project/3018028.04/benehi/sustained/','data','pilot','bids');
SID = 'sub-03'
niftis = [dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','func','*task-sus*run-*Realign_bold.nii'))];
mask_varea = dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','label','*desc-varea_space-FUNCCROPPED_label.nii'));
mask_eccen = dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','label','*desc-eccen_space-FUNCCROPPED_label.nii'));

nifti_varea= nifti(fullfile(mask_varea.folder,mask_varea.name));
nifti_eccen= nifti(fullfile(mask_eccen.folder,mask_eccen.name));

ix_v1= nifti_varea.dat(:) == 1; % V1
ix_ec10 = nifti_eccen.dat(:) <10; % V1

ix = find(ix_v1 & ix_ec10);


%% Load Event Files
eventFiles = [dir(fullfile(cfg.datadir,SID,'ses-01','func','*task-sus*run-*events.tsv'))];
events = [];
for run = 1:length(eventFiles)
    t = readtable(fullfile(eventFiles(run).folder,eventFiles(run).name),'fileType','text','ReadVariableNames',1,'HeaderLines',0);
    events = [events;t];
end
if SID == "sub-01"
events.Properties.VariableNames{3} = 'condition';
% to be backwards compatible with sub-01;
events.message = repmat("stimOnset",size(events,1),1);
events.block = repmat(1:12,1,size(events,1)/12)';

end

stimOnsetIX = find(events.message == "stimOnset");
onsetIX = diff(events{stimOnsetIX,'block'}) == 1;
onsetIX = [1; stimOnsetIX(find([0; onsetIX]))];
events.trial = nan(size(events,1),1);
events.trial(onsetIX) = 1; % to mark the onset

%% SPM DEsignmatrix for later voxel selection
data_path = './local/';
runIxTop200 = [];

for run = 1:max(unique(events.run))
      fmri_spec = struct;
    fmri_spec.dir = cellstr(fullfile(data_path,'GLM',sprintf('%s_run-%i',SID, run)));
    fmri_spec.timing.units = 'secs';
    fmri_spec.timing.RT= 1.5;
    fmri_spec.sess.cond.name = 'Stimulus';
    fmri_spec.sess.cond.onset =  events{events.run== run & events.message=="stimOnset"&events.trial==1,'onset'}';
    fmri_spec.sess.cond.duration = repmat(16,size(fmri_spec.sess.cond.onset));
    fmri_spec.sess.scans = {fullfile(niftis(run).folder,niftis(run).name)};
    fmri_spec.cvi = 'AR(1)';
    
    if exist(fullfile(data_path,'GLM',sprintf('%s_run-%i',SID, run),'spmT_0001.nii'),'file')
        % rmdir('./local/GLM','s')
        warning('Old results found, will not recalculate')
        continue
    end
    matlabbatch = [];
    matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = cellstr(data_path);
    matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = fullfile('GLM',sprintf('%s_run-%i',SID, run));
    
    matlabbatch{2} = struct('spm',struct('stats',struct('fmri_spec',fmri_spec)));
    tmp = struct;
    tmp.stats.fmri_est.spmmat = cellstr(fullfile(data_path,'GLM',sprintf('%s_run-%i',SID, run),'SPM.mat'));
    matlabbatch{3} = struct('spm',tmp);
    
    % Contrasts
    %--------------------------------------------------------------------------
    matlabbatch{4}.spm.stats.con.spmmat = cellstr(fullfile(data_path,'GLM',sprintf('%s_run-%i',SID, run),'SPM.mat'));
    matlabbatch{4}.spm.stats.con.consess{1}.tcon.name = 'Stim > Rest';
    matlabbatch{4}.spm.stats.con.consess{1}.tcon.weights = [1 0];
    % Call script to set up design
    spm_jobman('run',matlabbatch);
end

for run = 1:max(unique(events.run))
    tmpT = nifti(fullfile(data_path,'GLM',sprintf('%s_run-%i',SID, run),'spmT_0001.nii'));
    
    [~,I] = sort(tmpT.dat(ix));
    runIxTop200{run} = ix(I(end-200:end));
end



%% ZScore, Highpassfilter & mean ROI
act = [];
tic
for run = 1:max(unique(events.run))
    fprintf('run %i \t toc: %f.2s\n',run,toc)
    
    nifti_bold = nifti(fullfile(niftis(run).folder,niftis(run).name));
    timecourse = double(nifti_bold.dat);
    timecourse = bold_ztransform(timecourse);
    timecourse = permute(timecourse,[4,1,2,3]);
    size_tc= size(timecourse);
    timecourse(:) = tvm_highPassFilter(timecourse(:,:),1.5,1/128);
    for tr = 1:size(nifti_bold.dat,4)
        
        tmp = timecourse(tr,:,:,:);
        if exist('runIxTop200','var')
            act(run,tr) = nanmean(tmp(runIxTop200{run}));
        else
            act(run,tr) = nanmean(tmp(ix));
        end
    end
end
%%  CUT ERP
if SID == "sub-01"
    TR = 3.408;
else
    TR = 1.5;
end

events_onset = events(events.trial == 1,:);
allDat = [];
for block = 1:height(events_onset)
    tmp = events_onset(block,:);
    ix_time = -3*TR:TR:20*TR;
    ix_tr = round(ix_time/TR + tmp.onset/TR);
    tmp.erb = nan(1,length(ix_tr));
    tmp.erb(ix_tr>0 & ix_tr<=size(act,2)) = act(tmp.run,max(1,ix_tr(1)):min(size(act,2),ix_tr(end)));
    
    allDat = [allDat;tmp];
end




%%
bslcorrect =@(x,times)bsxfun(@minus,x,mean(x(:,times>=-1.5 & times <=1.5),2));
allDat.erb_bsl = bslcorrect(allDat.erb,ix_time);
%% Contrast
figure
g = gramm('x',ix_time,'y',allDat.erb_bsl,'color',allDat.condition);
g.stat_summary('type','bootci','geom','errorbar','setylim',1,'dodge',0.5);
g.stat_summary('type','ci','geom','point','setylim',1);
g.stat_summary('type','ci','geom','line','setylim',1);
g.draw();
g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-condition_plot.pdf',SID));
%% Attention Contrast
figure
g = gramm('x',ix_time,'y',allDat.erb_bsl,'color',allDat.condition)
g.stat_summary('type','bootci','geom','errorbar','setylim',1,'dodge',0.5);
g.stat_summary('type','ci','geom','point','setylim',1,'dodge',0);
g.stat_summary('type','ci','geom','line','setylim',1,'dodge',0);
g.facet_wrap(allDat.attention);
% g.axe_property('Ylim',[-0.38 1.6])
g.draw();
g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-conditionAttention_plot.pdf',SID));
%%
figure
g = gramm('x',allDat.condition,'y',median(allDat.erb_bsl(:,ix_time >= 6 & ix_time<=21),2),'color',allDat.attention);
g.stat_summary('type','bootci','geom','errorbar','dodge',0.2);
g.stat_summary('geom','point','dodge',0.2);
g.geom_point('alpha',0.2,'dodge',0.05);
%g.axe_property('Xlim',[0.2 0.9]);
g.draw();

g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-meanConditionAttention_plot.pdf',SID));
%%
figure
g = gramm('x',(allDat.run-1)*12+allDat.block,'y',median(allDat.erb_bsl(:,ix_time >= 6 & ix_time<=21),2),'color',allDat.condition,'marker',allDat.attention,'linestyle',allDat.attention);
g.geom_point()
g.stat_glm()
g.draw();
g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-meanTime_plot.pdf',SID));
