function calc_freesurferLabel_to_Volume(datadir,subjectlist)
% converts freesurfer
for SID = 1:length(subjectlist)
    %%
    freesurferpath    = fullfile(datadir,'derivates','freesurfer',subjectlist{SID},'ses-01');
    preprocessingpath = fullfile(datadir,'derivates','preprocessing',subjectlist{SID},'ses-01');
    configuration = [];
    configuration.i_SubjectDirectory = fullfile(datadir,'derivates');
    configuration.i_FreeSurfer = fullfile('freesurfer',subjectlist{SID},'ses-01');
    configuration.i_LabelFiles = {};
    configuration.i_Hemisphere = {};
    configuration.o_VolumeFile = {};
    for area = {'V1','V2'}
        for hem = {'lh','rh'}
            configuration.i_LabelFiles{end+1} = fullfile('freesurfer',subjectlist{SID},'ses-01','label',sprintf('%s.%s_exvivo.thresh.label',hem{1},area{1}));
            configuration.i_Hemisphere{end+1} = hem{1};
                configuration.o_VolumeFile{end+1} = fullfile('preprocessing',subjectlist{SID},'ses-01','label',sprintf('%s_ses-01_desc-freesurfArea%sHemi%s_space-FUNCCOPPED_label.nii',subjectlist{SID},area{1},hem{1}));
            
        end
        
    end
    p_meanrun= dir(fullfile(preprocessingpath,'func','*task-sustained*_desc-occipitalcropMean_bold.nii'));
    configuration.i_ReferenceVolume = fullfile('preprocessing',subjectlist{SID},'ses-01','func',p_meanrun.name);
    configuration.i_CoregistrationMatrix = fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANAT_to-FUNCCROPPED_mode-image.mat']);
    tvm_labelToVolume(configuration)
end
end