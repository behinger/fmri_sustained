function petkok_createRegisterDat(configuration)
% petkok_createRegisterDat 
%   petkok_createRegisterDat(configuration)
%   
%
%

%% Parse configuration
subjectDirectory =      tvm_getOption(configuration, 'i_SubjectDirectory');
    %no default
referenceFile =         fullfile(subjectDirectory, tvm_getOption(configuration, 'i_RegistrationVolume'));
    %no default
freeSurferName =        tvm_getOption(configuration, 'i_FreeSurferFolder', 'FreeSurfer');
    %[subjectDirectory, 'FreeSurfer']
registerDatFile =      	fullfile(subjectDirectory, tvm_getOption(configuration, 'o_RegisterDat'));
    %no default
coregistrationFile =    fullfile(subjectDirectory, tvm_getOption(configuration, 'i_CoregistrationMatrix'));
    %no default
    
%%
freeSurferFolder = fullfile(subjectDirectory, freeSurferName);

%% Load the volume data
functionalScan          = spm_vol(referenceFile);
structuralScan          = spm_vol(fullfile(freeSurferFolder, 'mri/brain.nii'));
functionalScan.volume   = spm_read_vols(functionalScan);
structuralScan.volume   = spm_read_vols(structuralScan);

voxelDimensionsFunctional = sqrt(sum(functionalScan.mat(:, 1:3) .^ 2));
voxelDimensionsStructural = sqrt(sum(structuralScan.mat(:, 1:3) .^ 2));

%%
freeSurferMatrixFunctional = tvm_dimensionsToFreesurferMatrix(voxelDimensionsFunctional, functionalScan.dim);
freeSurferMatrixStructural = tvm_dimensionsToFreesurferMatrix(voxelDimensionsStructural, structuralScan.dim);
                    
shiftByOne = [  1, 0, 0, 1; 
                0, 1, 0, 1; 
                0, 0, 1, 1; 
                0, 0, 0, 1];

% Create RegisterDat style matrix from coregistrationMatrix
load(coregistrationFile,'coregistrationMatrix');
registerDatMatrix = coregistrationMatrix' * inv(structuralScan.mat)' * inv(shiftByOne)' * freeSurferMatrixStructural';
registerDatMatrix = inv(freeSurferMatrixFunctional)' * shiftByOne' * functionalScan.mat' * registerDatMatrix;
registerDatMatrix = inv(registerDatMatrix)';

% Now write the matrix to a register.dat file.
f = fopen(registerDatFile,'w+');
fprintf(f,'FreeSurfer\n');
fprintf(f,'0.800000\n');
fprintf(f,'0.800000\n');
fprintf(f,'0.150000\n');
fprintf(f,'%16.15e %16.15e %16.15e %16.15e\n',registerDatMatrix(1,:));
fprintf(f,'%16.15e %16.15e %16.15e %16.15e\n',registerDatMatrix(2,:));
fprintf(f,'%16.15e %16.15e %16.15e %16.15e\n',registerDatMatrix(3,:));
fprintf(f,'%d %d %d %d\n',round(registerDatMatrix(4,:)));
fprintf(f,'round\n');
fclose(f);

end %end function