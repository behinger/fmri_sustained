% Crop functionals to only include the occipital lobe - to avoid
% distortions in other parts affecting registrations unnecessarily. Note x,
% y and z indices to include will change on a per subject / sesion basis!
% Edit these manually.

% Subject to process
function calc_cropOccipital(datadir,SID,t_sub)
% Indices to crop around


% Nifti files to process
niftis = [dir(fullfile(datadir,SID,'ses-01','func','*.nii'))
    
          dir(fullfile(datadir,'derivates','preprocessing',SID,'ses-01','anat','*anatomical_T1w.nii'))];


for curNifti = 1:length(niftis)
    fprintf('Processing %i/%i:%s\n',curNifti,length(niftis),niftis(curNifti).name)
    [~,anatOrFunc] = fileparts(niftis(curNifti).folder);
    if strcmp(anatOrFunc,'anat')
            xind = t_sub.anat{1};
            yind = t_sub.anat{2};
            zind = t_sub.anat{3};
    elseif strcmp(anatOrFunc,'func')
        
            xind = t_sub.func{1};
            yind = t_sub.func{2};
            zind = t_sub.func{3};
    else 
        error('needs to be anat or func')
    end
    
    niipath = fullfile(niftis(curNifti).folder,niftis(curNifti).name);
    vols = spm_vol(niipath);
    
    for iVol = 1:length(vols)
        oldVol = vols(iVol);
        img = spm_read_vols(vols(iVol));
        
        img = img(xind,yind,zind);
        
        newVol = oldVol;
        newVol = rmfield(newVol,'private');
        
        newVol.descrip = [newVol.descrip ' - cropped'];
        
        splitFilename = strsplit(niftis(curNifti).name,'_');
        if strcmp(anatOrFunc,'anat')
            runix = 2;
        else
            runix = find(cellfun(@(x)~isempty(x),strfind(splitFilename,'run'))); % we want to keep only the BIDS name until run
        end
            
        savepath = fullfile(datadir,'derivates','preprocessing',SID,'ses-01', anatOrFunc);
        if ~exist(savepath,'dir')
            mkdir(savepath);
        end
        newVol.fname = fullfile(savepath, ...
                            [strjoin(splitFilename(1:runix),'_') '_desc-occipitalcrop_' splitFilename{end}]); % 
        newVol.dim = size(img);
        % added to preserve the TR timing
        newVol.private.timing = oldVol.private.timing;
        spm_write_vol(newVol,img);
    end
    
end