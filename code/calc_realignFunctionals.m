% Realign all functionals to first run
function calc_realignFunctionals(datadir,subjectlist,varargin)

cfg = finputcheck(varargin, ...
    { 'funcidentifier','string',[],'sub*_desc-occipitalcrop_*.nii'
    'derivatesubfolder','string',[]','preprocessing'
    'quality','real',[],1
    });
if ischar(cfg)
    error(cfg)
end



% Subjects to process

% Relaignment configuration - using settings from petkok's code, assuming
% they are fine...
realignmentConfiguration = [];
realignmentConfiguration.quality = cfg.quality;
realignmentConfiguration.sep = 1;
realignmentConfiguration.rtm = 1;
realignmentConfiguration.interp = 4;
realignmentConfiguration.fwhm = 1;

for SID = 1:length(subjectlist)
    niftis = dir(fullfile(datadir,'derivates',cfg.derivatesubfolder,subjectlist{SID},'ses-01','func',cfg.funcidentifier));
    niftis = cellfun(@(x,y)fullfile(x,y),{niftis(:).folder},{niftis(:).name},'UniformOutput',0);
    spm_realign(niftis, realignmentConfiguration);
    spm_reslice(niftis, realignmentConfiguration);

    % fix spms terrible file management
    fprintf('reslicing complete\n')
    for nifti = niftis
        
            
        
        [filepath,filename]=fileparts(nifti{1});
        fprintf('running %s \n',filename)
        splitFilename = strsplit(filename,'_');
        desc_ix = find(cellfun(@(x)~isempty(x),strfind(splitFilename,'desc-')));
        suffix_ix = find(cellfun(@(x)~isempty(x),strfind(splitFilename,'bold')));
        
        assert(length(desc_ix) == 1) % there can be only one desc!
        
        
        splitFilename{desc_ix} = [splitFilename{desc_ix} 'Realign'];
        resliced_target = fullfile(filepath,[strjoin(splitFilename,'_') '.nii']);

        % Rename resliced
        movefile(fullfile(filepath,['r' filename '.nii']),resliced_target);
        
        
        % fix nan-problem
        fprintf('removing all nans (occasionally they exist :/) \n')
        system(sprintf('fslmaths %s -nan %s',resliced_target,resliced_target));
        system(sprintf('gunzip %s.gz -f',resliced_target))
    
        
        % rename & move realignment files
        splitFilename{desc_ix} = 'from-run_to-mean';
        splitFilename{suffix_ix} = 'coreg';
        mkdir(fullfile(filepath,'..','coreg'));
        movefile(fullfile(filepath,[filename '.mat']),fullfile(filepath,'..','coreg',[strjoin(splitFilename,'_') '.mat']));
        
        % move motion to motion folder
        splitFilename{suffix_ix} = 'motion';
        if ~exist(fullfile(filepath,'..','motion'),'dir')
            mkdir(fullfile(filepath,'..','motion'))
        end
        movefile(fullfile(filepath,['rp_' filename '.txt']),fullfile(filepath,'..','motion',[strjoin(splitFilename,'_') '.txt']));
        
    end
    % rename mean file
    [filepath,filename]=fileparts(niftis{1});
    splitFilename = strsplit(filename,'_');
    desc_ix = find(cellfun(@(x)~isempty(x),strfind(splitFilename,'desc-')));
    run_ix = find(cellfun(@(x)~isempty(x),strfind(splitFilename,'run-')));
    
    splitFilename{desc_ix} = [splitFilename{desc_ix} 'Mean'];
    splitFilename(run_ix) = []; % delete the run information, its meaningless anyway for meanrun
    meanFile = fullfile(filepath,['mean' filename '.nii']);
    assert(exist(meanFile,'file')==2);
    movefile(meanFile,fullfile(filepath,[strjoin(splitFilename,'_') '.nii']));
    
    
    
    %     movefile(fullfile(niftiFolder, 'mean*.nii'), realignmentFolder);
    %     movefile(fullfile(niftiFolder, 'r*.nii'), realignmentFolder);
    %     movefile(fullfile(niftiFolder, 'r*.mat'), realignmentFolder);
    %     movefile(fullfile(niftiFolder, 'rp*.txt'), realignmentFolder);
    
end

