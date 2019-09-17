% Create Freesurfer registration .dat file from coregistration matrix
function calc_createRegisterDat(datadir,subjectlist,varargin)

cfg = finputcheck(varargin, ...
    { 'task','string',[],'sustained'
    });
if ischar(cfg)
    error(cfg)
end
for SID = 1:length(subjectlist)
    
    

    p_meanrun= dir(fullfile(datadir,'derivates','preprocessing',subjectlist{SID},'ses-01','func',sprintf('*task-%s_desc-occipitalcropMean_bold.nii',cfg.task)));
    
    p_corrMat   = fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-BBR_mode-image.mat']);
    p_boundaries= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-BBR_mode-surface.mat']);

    configuration = [];
    configuration.i_SubjectDirectory = fullfile(datadir,'derivates');
    configuration.i_FreeSurferFolder = fullfile('freesurfer',subjectlist{SID},'ses-01');

    configuration.i_RegistrationVolume = fullfile('preprocessing',subjectlist{SID},'ses-01','func',p_meanrun.name);
    configuration.i_CoregistrationMatrix = p_corrMat;
    configuration.o_RegisterDat = [p_boundaries(1:end-4) '_register.dat'];
    
    petkok_createRegisterDat(configuration);
    clear configuration;
end

