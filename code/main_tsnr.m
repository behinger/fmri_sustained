
try
    be_setupfmri % init paths and stuff
end


cfg = [];
cfg.rootdir= '/home/predatt/benehi/projects/sustained/';

cfg.datadir = fullfile('/project/3018028.04/benehi/sustained/','data','pilot','bids');

cfg.subjectlist = {'sub-01'};

cfg.loopfun = @(cfg)['cd ' cfg.scriptdir ';export subjectlist="'  strjoin(cfg.subjectlist),'"; export datadir="' cfg.datadir '";'];
cfg.gridpipe_long_4cpu = sprintf('| qsub -l "nodes=1:ppn=4,walltime=12:00:00,mem=12gb" -o %s',fullfile(cfg.datadir,'logfiles'));
cfg.gridpipe_long = sprintf('| qsub -l "nodes=1:walltime=22:00:00,mem=4GB,procs=1" -o %s',fullfile(cfg.datadir,'logfiles'));
cfg.gridpipe_short = sprintf('| qsub -l "nodes=1:walltime=5:00:00,mem=4GB,procs=1" -o %s',fullfile(cfg.datadir,'logfiles'));

error



%% Copy the files to /derivates/tsnr/sub/ses/func and add _desc-raw_ to the filename

niftis = [dir(fullfile(cfg.datadir,cfg.subjectlist{1},'ses-01','func','*task-resting*.nii.gz'))];
for curNifti = 1:length(niftis)
    fprintf('Processing %i/%i:%s\n',curNifti,length(niftis),niftis(curNifti).name)

    % move nifti to nicer place
    tsnr_folder = fullfile(datadir,'derivates','tsnr',SID,'ses-01','func');
    if ~exist(tsnr_folder,'dir')
        mkdir(tsnr_folder)
    end
    fromFile = fullfile(niftis(curNifti).folder,niftis(curNifti).name);
    
    splitFilename = strsplit(niftis(curNifti).name,'_');
    toFile = [strjoin(splitFilename(1:3),'_') '_desc-raw_bold.nii.gz'];
    toFile = fullfile(tsnr_folder,toFile);
    system(sprintf('cp %s %s',fromFile,toFile))
    
end

%% realign the functionals
niftis = [dir(fullfile(cfg.datadir,'derivates','tsnr',cfg.subjectlist{1},'ses-01','func','*task-resting*.nii'))];
for curNifti = 1:length(niftis)
    calc_realignFunctionals(cfg.datadir,cfg.subjectlist,'funcidentifier',niftis(curNifti).name,'derivatesubfolder','tsnr','quality',0.8)

end


%%
calc_tsnr(cfg.datadir,cfg.subjectlist{1})