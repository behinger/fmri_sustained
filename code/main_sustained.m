
try
    be_setupfmri % init paths and stuff
end


cfg = [];
cfg.rootdir= '/home/predatt/benehi/projects/fmri_sustained/';

cfg.datadir = fullfile('/project/3018028.04/benehi/sustained/','data','pilot','bids');

cfg.subjectlist = {'sub-01'};

cfg.loopfun = @(cfg)['cd ' cfg.scriptdir ';export subjectlist="'  strjoin(cfg.subjectlist),'"; export datadir="' cfg.datadir '";'];
cfg.gridpipe_long_4cpu = sprintf('| qsub -l "nodes=1:ppn=4,walltime=12:00:00,mem=12gb" -o %s',fullfile(cfg.datadir,'logfiles/'));
cfg.gridpipe_long = sprintf('| qsub -l "nodes=1:walltime=22:00:00,mem=4GB,procs=1" -o %s',fullfile(cfg.datadir,'logfiles/'));
cfg.gridpipe_short = sprintf('| qsub -l "nodes=1:walltime=5:00:00,mem=4GB,procs=1" -o %s',fullfile(cfg.datadir,'logfiles/'));

error
%%
cfg.phase = 'registration';
cfg.step = [2:6];

%% Phase 1
if strcmp(cfg.phase,'preprocessing')
    % path modifications
    cfg.scriptdir = fullfile(cfg.rootdir,'code');
    addpath(cfg.scriptdir)
    
    cfg.loopeval = cfg.loopfun(cfg); % export variables and dirs
    for step =cfg.step
      
        switch step
            case 0
                % convert .mat to .tsv in BIDS format
                  calc_generateEventfile(cfg.datadir,cfg.subjectlist,'condition','sustained')

%                 Step0_reconstructCAIPI(fullfile(cfg.datadir,'../','recon'),cfg.subjectlist)
                  % XXX copy files automatically to bids or use bidscoiner
            case 4
                % get a (betteR) T1 from the mp2rage anatomical scan
%                 Step4_modifyMP2RAGE(cfg.datadir,cfg.subjectlist)
            case 5
                % recon-all to segment
                for SID =cfg.subjectlist
                    %locally
                    %[~,out] = system([cfg.loopeval 'export SID="' SID{1} '";./Step5_RunFreesurfer.sh'],'-echo');
                    % runs parrallel with freesurfer 6
                    [~,out] = system(['echo ''' cfg.loopeval 'export SID="' SID{1} '";./calc_runFreesurfer.sh''' cfg.gridpipe_long_4cpu],'-echo');
                    
                end
            case 6
                % crop the occipital cortex
                % input needed how to best save coordinates for croping to

                f_cropmark = fullfile(cfg.datadir,'derivates','preprocessing','cropmarks_occipital.mat');
               
                for SID = cfg.subjectlist
                    if exist(f_cropmark,'file')
                        crop = load(f_cropmark);
                        crop = crop.crop;
                    else
                        crop = table({},[],[],'VariableNames',{'SID','anat','func'});
                    end
                    
                    ix = find(strcmp(SID{1},crop.SID));
                    if ~isempty(ix)
                        t_sub = crop(ix,:);
                    else
                        spm_image('display',fullfile(cfg.datadir,'derivates','preprocessing',SID{1}, 'ses-01','anat',[SID{1} '_ses-01_desc-anatomical_T1w.nii']))
                        tmp_a = input('Subject not found, adding it to table. Anat {X:X, Y:Y, Z:Z}:');
                        
                        spm_image('display',fullfile(cfg.datadir,SID{1}, 'ses-01','func',[SID{1} '_ses-01_task-sustained_run-1_bold.nii']))

                        tmp_f = input('Subject not found, adding it to table. Func {X:X, Y:Y, Z:Z}:');
                        t_sub = table(SID(1),tmp_a,tmp_f,'VariableNames',{'SID','anat','func'});
                        
                        % concatenate to already loaded and save changes
                        crop = [crop; t_sub];
                        save(f_cropmark,'crop')
                    end
                    calc_cropOccipital(cfg.datadir,SID{1},t_sub)
                    
                end
                
            case 7
                %convert mgz (freesurfer) to nii
                [~,out] = system([cfg.loopeval './Step7_ConvertFreesurferOutput.sh'],'-echo');


            case 9
                % SPM linear realign of functional scans to mean functional
                % scan. Output mean nifti
                calc_realignFunctionals(cfg.datadir,cfg.subjectlist)
            case 10
                % Rough alignment of mp2rage anatomical to mean functional
                calc_alignFreesurferToFunc(cfg.datadir,cfg.subjectlist)
                
            case 'catch22'
                
                p_meanrun= dir(fullfile(cfg.datadir,'derivates','preprocessing','sub-01','ses-01','func','*task-adaptation_desc-occipitalcropMean_bold.nii'));
%                 rfiles= dir(fullfile(cfg.datadir,'derivates','preprocessing','sub-01','ses-01','func','*Realign*.nii'));
                rp= dir(fullfile(cfg.datadir,'derivates','preprocessing','sub-01','ses-01','coreg','*_motion.txt'));
                genpath =@(p)cellfun(@(x,y)fullfile(x,y),{p.folder},{p.name},'UniformOutput',0);
               
                memolab_batch_qa('dataDir',fullfile(cfg.datadir,'derivates','preprocessing'),...
                    'QAdir',fullfile('qualcheck'),...
                    'subjects',{'sub-01'},'session','ses-01',...
                    'runs',{'task-adaptation_run-2_desc-occipitalcrop_',...
                    'task-adaptation_run-3_desc-occipitalcrop_',...
                    'task-adaptation_run-4_desc-occipitalcrop_',...
                    'task-localizer_run-1_desc-occipitalcrop_',...
                    'task-retinotopy_run-1_desc-occipitalcrop_'},...
                    'realign',struct('meanfunc',repmat({fullfile(p_meanrun.folder,p_meanrun.name)},1,5),...
                    'rfiles',{'task-adaptation_run-2_desc-occipitalcropRealign',...
                    'task-adaptation_run-3_desc-occipitalcropRealign',...
                    'task-adaptation_run-4_desc-occipitalcropRealign',...
                    'task-localizer_run-1_desc-occipitalcropRealign',...
                    'task-retinotopy_run-1_desc-occipitalcropRealign'},...
                    'rp',genpath(rp)))
                
                
            case 12
                % Boundary / Gradient based Surface / Volume alignment
                calc_boundaryBasedRegistration(cfg.datadir,cfg.subjectlist)
            
           
            case 15
                % TVM recursive Boundary Registration.
                % TODO: The clustereval should be pulled out to this script
                calc_cluster_recursiveBoundaryRegistration(cfg.datadir,cfg.subjectlist)
            
            case 16
                calc_backupFreesurfer(cfg.datadir,cfg.subjectlist)
            case 17
                % we need the tvm_boundariesToFreesurferFile function from the development
                % folder
                
                
                calc_overwriteFreesurferBoundaries(cfg.datadir,cfg.subjectlist)
            case 18

                vis_surfaceCoregistration(cfg.datadir,cfg.subjectlist{1},'boundary_identifier','%s_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-recursive_mode-surface','axis','z')
                
                vis_surfaceCoregistration(cfg.datadir,cfg.subjectlist{1},'boundary_identifier','%s_ses-01_from-ANATCROPPED_to-FUNCCROPPED_mode-surface','axis','z')
                vis_surfaceCoregistration(cfg.datadir,cfg.subjectlist{1},'boundary_identifier','%s_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-BBR_mode-surface','axis','z')
                vis_surfaceCoregistration(cfg.datadir,cfg.subjectlist{1},'boundary_identifier','%s_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-recursive_mode-surface','axis','z')
                %                 Step9_visualiseRecursiveRegistration(cfg.datadir,cfg.subjectlist,'slicelist',23,'boundary_identifier','Anat2FuncBoundaries_recurs_sam','functional_identifier','meanWM_run1_sam.nii')
                
                
            p_meanrun= dir(fullfile(cfg.datadir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','func',sprintf('*task-%s*_desc-occipitalcropMeanBias_bold.nii','sustained')));
            boundaries = dir(fullfile(cfg.datadir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','coreg','*_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-BBR_mode-surface.mat'))
            config = struct('i_SubjectDirectory',fullfile(cfg.datadir,'derivates'),...
                    'i_ReferenceVolume',fullfile('preprocessing',cfg.subjectlist{1},'ses-01','func',p_meanrun.name),...
                    'i_Boundaries',fullfile('preprocessing',cfg.subjectlist{1},'ses-01','coreg',boundaries.name),...
                    'o_RegistrationMovie','test_bbr.mp4')
                config.i_Boundaries = {config.i_Boundaries}
                tvm_makeRegistrationMovieWithMoreBoundaries(config)
                
                
                
                 p_meanrun= dir(fullfile(cfg.datadir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','func',sprintf('*task-%s*_desc-occipitalcropMeanBias_bold.nii','sustained')));
                anat= dir(fullfile(cfg.datadir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','anat','sub*_ses-01_desc-anatomical_T1w.nii'))
                coreg= dir(fullfile(cfg.datadir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','coreg','*_ses-01_from-ANAT_to-FUNCCROPPED_mode-image.mat'))
                [~,outname,~] = fileparts(coreg.name);
                config = struct('i_SubjectDirectory',fullfile(cfg.datadir,'derivates'),...
                    'i_MoveVolumes',     fullfile('preprocessing',cfg.subjectlist{1},'ses-01','label','sub-01_ses-01_desc-varealabel_space-ANAT_label.nii'),...
                    'i_ReferenceVolume',          fullfile('preprocessing',cfg.subjectlist{1},'ses-01','anat',anat.name),...
                    'i_CoregistrationMatrix',fullfile('preprocessing',cfg.subjectlist{1},'ses-01','coreg',coreg.name),...
                    'i_InverseRegistration',true,...
                    'i_InterpolationMethod','NearestNeighbours',...
                    'o_OutputVolumes',         fullfile('preprocessing',cfg.subjectlist{1},'ses-01','label_in_anat.nii'))
                
                tvm_resliceVolume(config)
                
                
                
            case 19
                
                
                
                
                [~,out] = system([cfg.loopeval './calc_biascorrectMeanFunc.sh'],'-echo');
            case 21
                % if FullBrain Functional available:
                 [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaFullFunc.sh'],'-echo');
                 
                 % if not available go over cropped Anatomical
                 [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaAnatCrop.sh'],'-echo');

                 % fsleyes anat/sub-*_ses-01_desc-occipitalcrop_T1w.nii func/sub-*_ses-01_task-sustained_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii
                 % fsleyes anat/sub-*_ses-01_desc-occipitalcrop_space-ANAT_T1w.nii anat/sub-*_ses-01_desc-anatomical_T1w.nii 
                 % fsleyes anat/sub-*_ses-01_desc-anatomical_space-FUNCCROPPED_T1w.nii func/sub-*_ses-01_task-sustained_desc-occipitalcropMeanBias_bold.nii

            case 22
                [~,out] = system([cfg.loopeval './calc_createRetinotopyFromAtlas.sh'],'-echo');
                [~,out] = system([cfg.loopeval './calc_visualLabelToFunc.sh'],'-echo');
                %fsleyes anat/sub-*_ses-01_desc-anatomical_space-FUNCCROPPED_T1w.nii label/sub-01_ses-01_desc-varealabel_space-FUNCCROPPED_label.nii func/sub-*_ses-01_task-*_desc-occipitalcropMeanBias_bold.nii


                tvm_labelToVolume
                tvm_installOpenFmriAnalysisToolbox XXX add configuration to startup
        end
        fprintf('Finished Step %i \n',step)
    end
end


% %% Phase 3
% if strcmp(cfg.phase,'ROI')
%     cfg.scriptdir = fullfile(cfg.rootdir,'code','Phase3_ROI');
%     addpath(cfg.scriptdir)
%     
%     cfg.loopeval = cfg.loopfun(cfg); % export variables and dirs
%     for step =cfg.step
%         fprintf('Running Step %i\n',step)
%         switch step
%             case 0
%             case 1
%                 % run preprocessing & a GLM on the localizer data
% %                 [~,out] = system([cfg.loopeval './Step1_RunFeat_Localiser.sh'],'-echo');
%                                 
%             case 4
%                 % Multiply z-map of orientation localizer with ROI => only
%                 % leaves voxels of a roi that are active for the
%                 % orientation
% %                 [~,out] = system([cfg.loopeval './Step4_ConstrainMasks.sh'],'-echo');
%             case 6
% %                 [~,out] = system([cfg.loopeval './Step6_combineMasks.sh'],'-echo');
%                 
%         end
%         fprintf('Finished Step %i \n',step)
%     end
% end
%% Phase Univariate Modeling
if strcmp(cfg.phase,'GLM')
    cfg.scriptdir = fullfile(cfg.rootdir,'code','Phase4_GLM');
    addpath(cfg.scriptdir)
    
    cfg.loopeval = cfg.loopfun(cfg); % export variables and dirs
    for step =cfg.step
        fprintf('Running Step %i\n',step)
        switch step
            case 0 
                StepX_generateFSLEventfile(cfg.datadir,cfg.subjectlist,'condition','adaptation')
            case 1
                for SID =cfg.subjectlist
                    for run = [1 3 4]
                        
                        [~,out] = system([cfg.loopeval sprintf('export designfile="sustain_preprocessing";export runNum="%i";export SID="%s"',run,SID{1}) ';./Step1_FSL_RunFeat.sh'],'-echo');
                    end
                end

            case 4
                % move the preprocessed trial files to
                % preprocessing/././func
                StepX_moveFeatToFunc(cfg.datadir,cfg.subjectlist)
            case 5
                % OPTIONAL
                % run FEAT over the experimental runs
                for SID =cfg.subjectlist  
                    numberOfRuns = [2 3 4 0]; %so far hardcoded
                    runstring = int2str(numberOfRuns);
                    [~,out] = system([cfg.loopeval sprintf('export designfile="adapt_statistics_%iruns";export runlist="%s";export SID="%s"',length(numberOfRuns(numberOfRuns~=0)),runstring,SID{1}) ';./Step1_FSL_RunFeat.sh'],'-echo');
                end
                
            case 5
                
            case 6
%                 Step6_CreateLocaliserFunctionalFiles(cfg.datadir,cfg.subjectlist)
            case 7
                % copy the FEAT functional files to a new folder
                % SubjectData/SID/FunctionalFiles
%                 [~,out] = system([cfg.loopeval './Step7_CopyFunctionalFiles.sh'],'-echo');

        end
        fprintf('Finished Step %i \n',step)
    end
end

%% Phase 5
if strcmp(cfg.phase,'laminar')
    cfg.scriptdir = fullfile(cfg.rootdir,'code','Phase5_laminar_analysis');
    addpath(cfg.scriptdir)
    
    cfg.loopeval = cfg.loopfun(cfg); % export variables and dirs
    for step =cfg.step
        fprintf('Running Step %i\n',step)
        switch step
            case -1
                % zscore localizer & functionals, and add weighted versions
                % (weighting might be controversial)
                
                StepX_CreateWeightedFunctionalFiles(cfg.datadir,cfg.subjectlist)
            case 0
                % I put it here, because its output goes into the tvm_layer
                % folder and is not preprocessing anymore imho
                StepX_CreateROIs(cfg.datadir,cfg.subjectlist,'topn',500)

            case 1
                Step1_layersPipeline(cfg.datadir,cfg.subjectlist)
            case 2
                Step2_createDesignMatrices(cfg.datadir,cfg.subjectlist)
            case 3
                Step3_timecourse_bene(cfg.datadir,cfg.subjectlist)
          
        end
        fprintf('Finished Step %i \n',step)
    end
end