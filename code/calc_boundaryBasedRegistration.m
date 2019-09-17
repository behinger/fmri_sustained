% Boundary based registration to align Fressurfer surface to functional
% data
function calc_boundaryBasedRegistration(datadir,subjectlist,varargin)
cfg = finputcheck(varargin, ...
    { 'task','string',[],'sustained'
    });
if ischar(cfg)
    error(cfg)
end

for SID = 1:length(subjectlist)
    % Relaignment configuration - using settings from petkok's code, assuming
    % they are fine...
    realignmentConfiguration.ReverseContrast       = true;
    realignmentConfiguration.ContrastMethod        = 'gradient';
    realignmentConfiguration.OptimisationMethod    = 'centred';%'GreveFischl';%'centred';
    realignmentConfiguration.Mode                  = 'rts';
    realignmentConfiguration.Display              	= 'on';

    
 
    p_meanrun= dir(fullfile(datadir,'derivates','preprocessing',subjectlist{SID},'ses-01','func',sprintf('*task-%s*_desc-occipitalcropMeanBias_bold.nii',cfg.task)));
    i_corrMat   = fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANATCROPPED_to-FUNCCROPPED_mode-image.mat']);
    i_boundaries= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANATCROPPED_to-FUNCCROPPED_mode-surface.mat']);
    o_corrMat   = fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-BBR_mode-image.mat']);
    o_boundaries= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-BBR_mode-surface.mat']);
    
    
    configuration = [];
    configuration.i_SubjectDirectory = fullfile(datadir,'derivates');
    configuration.i_ReferenceVolume = fullfile('preprocessing',subjectlist{SID},'ses-01','func',p_meanrun.name);
    configuration.i_CoregistrationMatrix = i_corrMat;
    configuration.i_Boundaries = i_boundaries;
    configuration.o_CoregistrationMatrix = o_corrMat;
    configuration.o_Boundaries = o_boundaries;
    tvm_useBbregister() XXX
%     tvm_boundaryBasedRegistration(configuration,realignmentConfiguration);
   
    % Write coregistration matrix to text file so we can use it with flirt
    % (didn't use this for anything, in the end - samlaw)
%     transformationMatrix = load(fullfile(configuration.i_SubjectDirectory, configuration.o_CoregistrationMatrix));
%     outFile = fullfile(configuration.i_SubjectDirectory, 'Coregistrations/T12Func.mat');
%     dlmwrite(outFile, transformationMatrix.coregistrationMatrix);
%     
    clear configuration; clear realignmentConfiguration;
end
% Export the registrations to freesurfer (using old
                % functions from Peter Kok)
                
calc_createRegisterDat(datadir,subjectlist,varargin{:})
