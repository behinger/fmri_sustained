
function calc_tsnr(datadir,SID)
% Script to calculate TSNR of any image called 'resting'
% fslmaths input -Tmean mean
% fslmaths input -Tstd std
% fslmaths mean -div std tSNR

niftis = [dir(fullfile(datadir,'derivates','tsnr',SID,'ses-01','func','*desc-raw-realign*.nii'))]
 

% create tsnr-folder if not exist
tsnr_folder = fullfile(datadir,'derivates','tsnr',SID,'ses-01','func');
if ~exist(tsnr_folder,'dir')
    mkdir(tsnr_folder)
end

for curNifti = 1:length(niftis)
    fprintf('Processing %i/%i:%s\n',curNifti,length(niftis),niftis(curNifti).name)
    
   nifti_name = fullfile(niftis(curNifti).folder,niftis(curNifti).name);
    % new filename
    splitFilename = strsplit(niftis(curNifti).name,'_');
    tsnr_name = [strjoin(splitFilename(1:4),'_') '_%s.nii.gz'];
    tsnr_name = fullfile(tsnr_folder,tsnr_name);
    % mean
    system(sprintf('fslmaths %s -Tmean %s',nifti_name,sprintf(tsnr_name,'mean')));
    % std
    system(sprintf('fslmaths %s -Tstd %s',nifti_name,sprintf(tsnr_name,'std')));
    % tsnr
    system(sprintf('fslmaths %s -div %s %s',sprintf(tsnr_name,'mean'),sprintf(tsnr_name,'std'), sprintf(tsnr_name,'tsnr')));
end
