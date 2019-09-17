function be_writenifti(nifti,pathAndName)
niftiWrite(nifti,pathAndName);

% Unzip niftis so that spm can read them
cmd = ['gzip -d -f ', pathAndName];
system(cmd);