function file = be_niigz_to_nii(file)
[filepath,filename,filetype] = fileparts(file);
if strcmp(filetype,'.gz')
    fprintf('unzipping nii.gz \n');
    filegz = file;
    file = fullfile(filepath,filename);

    status = system(['gzip -d < ' filegz ' > ' file]);
    if status ~= 0
        file = filegz; %failed, return gz file
    end
end