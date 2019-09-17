% change folder for now when running this script. This should be fixed for
% a new subject by getting the root directory.

if exist('spm','file')
    % don't add the stuff twice
    return
end


% fprintf('adding mrVista \n')
% addpath(genpath('local/lib/toolboxes/vistalab'));

fprintf('adding SPM12 \n')
cd(fullfile(fileparts(mfilename('fullpath')),'../'))

addpath('code')

addpath('local/lib/toolboxes/spm12')

spm('defaults','fmri')



fprintf('adding TVM toolbox')
addpath('local/lib/toolboxes/tvm_openfmrianalysis/')
tvm_installOpenFmriAnalysisToolbox(struct('Development',true))

fprintf('adding the donders-grid qsub functions\n')
addpath '/home/common/matlab/fieldtrip/qsub'

fprintf('adding helper code\n')
addpath('code/helper')


fprintf('adding memolab QA\n')
addpath('local/lib/toolboxes/memolab')

fprintf('adding exportfig\n')
addpath('local/lib/toolboxes/export_fig')

fprintf('adding artrepair\n')
addpath('local/lib/toolboxes/ArtRepair')


fprintf('adding gramm\n')
addpath('local/lib/toolboxes/gramm')

fprintf('adding bids-matlab')
addpath('local/lib/toolboxes/bids-matlab')
%fprintf('adding recon script\n')
%addpath(genpath('lib/recon'))
%addpath(genpath('code'))
