function out = be_spm_vol(file)
file = be_niigz_to_nii(file);
out = spm_vol(file);
    