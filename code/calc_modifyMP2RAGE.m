% Modifies MP2RAGE into a format that FreeSurfer will accept

function calc_modifyMP2RAGE(datadir,subjectlist)

for curSub = 1:length(subjectlist)
    configuration.i_SubjectDirectory = datadir;
    configuration.i_ContrastImage        = fullfile(subjectlist{curSub}, 'ses-01','anat',[subjectlist{curSub} '_ses-01_acq-uni_run-1_T1w.nii']);
    configuration.i_BlackBackgroundImage = fullfile(subjectlist{curSub}, 'ses-01','anat',[subjectlist{curSub} '_ses-01_acq-inv2_run-1_T1w.nii']);
    savepath = fullfile('derivates','preprocessing',subjectlist{curSub}, 'ses-01','anat');
    if ~exist(fullfile(datadir,savepath),'dir') % need the abs path here, but the rel path for the toolbox
    mkdir(fullfile(datadir,savepath)); 
    end
    configuration.o_OutputFile = fullfile(savepath,[ subjectlist{curSub} '_ses-01_desc-anatomical_T1w.nii']);
    
    tvm_modifyMp2rage(configuration);
    
%     configuration.i_ContrastImage = 'Niftis/WorkingMemory/reoriented_mp2rage_UNI_Images.nii';
%     configuration.i_BlackBackgroundImage = 'Niftis/WorkingMemory/reoriented_mp2rage_INV2.nii';
%     configuration.o_OutputFile = 'Niftis/WorkingMemory/reoriented_MP2RAGE.nii';
%     tvm_modifyMp2rage(configuration);
    clear configuration;
end

