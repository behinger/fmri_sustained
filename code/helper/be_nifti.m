function out = be_nifti(file,varargin)
% unzip if necessary
if nargin<2
    try
        
        file = be_niigz_to_nii(file);
        
    catch
        warning('could not unzip nifti')
    end
end

% use spm if needed
if nargin > 1 && strcmp(varargin{1},'spmnifti')
    out = nifti(file);
elseif nargin > 1 && strcmp(varargin{1},'spmvol')
    out = spm_vol(file);
else
    out = niftiRead(file);
end

