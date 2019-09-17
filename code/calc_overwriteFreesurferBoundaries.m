% Overwrite freesurfer boundaries with results of recursive boundary
% registration

function calc_overwriteFreesurferBoundaries(datadir,subjectlist,varargin)


cfg = finputcheck(varargin, ...
    { 'task','string',[],'sustained'
    });
if ischar(cfg)
    error(cfg)
end

% first backup it
calc_backupFreesurfer(datadir,subjectlist)

%then overwrite them
for SID = 1:length(subjectlist)
    
    p_meanrun= dir(fullfile(datadir,'derivates','preprocessing',subjectlist{SID},'ses-01','func',sprintf('*task-%s_desc-occipitalcropMean_bold.nii',cfg.task)));
    i_boundaries= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-recursive_mode-surface.mat']);
    corregistrationMatrix= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANATCROPPED_to-FUNCCROPPED_mode-image.mat']);
    
    configuration = [];
    configuration.i_SubjectDirectory = fullfile(datadir,'derivates');
    configuration.i_ReferenceVolume = fullfile('preprocessing',subjectlist{SID},'ses-01','func',p_meanrun.name);
    
    
    
    
    
    configuration.i_Boundaries = i_boundaries;
    configuration.i_CoregistrationMatrix = corregistrationMatrix;
    configuration.i_FreeSurferFolder = fullfile('freesurfer',subjectlist{SID},'ses-01');
    configuration.o_WhiteMatterSurface = fullfile('freesurfer',subjectlist{SID},'ses-01','surf','?h.white');
    configuration.o_PialSurface =  fullfile('freesurfer',subjectlist{SID},'ses-01','surf','?h.pial');
    
    
    tvm_boundariesToFreesurferFile(configuration);
    
    clear configuration;
end

