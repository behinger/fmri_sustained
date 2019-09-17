% Backup old Freesurfer files before replacing them with new corrected
% files
function calc_backupFreesurfer(datadir,subjectlist)
% Subjects to process


for SID = 1:length(subjectlist)
    configuration = [];
    configuration.i_SubjectDirectory = fullfile(datadir,'derivates','freesurfer',subjectlist{SID},'ses-01');
    configuration.i_Files = {'surf/lh.white', 'surf/lh.pial', 'surf/lh.orig',...
                            'surf/rh.white', 'surf/rh.pial', 'surf/rh.orig'};
    configuration.p_Suffix = '_backup';
    
    tvm_backupFiles(configuration);
    
    % I think this is not necessary?!
%     tvm_restoreBackupFiles(configuration);
    
    clear configuration;
end

