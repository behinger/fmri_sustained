function varargout = calc_generateEventfile(datadir,subjectlist,varargin)
% Function that creates the TSV DesignEvent File
% A text file needed to specify the design.
%
% (AFAIK) Specifications of the file:
% Text file with tab stop
% Time(s) | Duration(s) | Value
% usually value is 1 for factorial designs.
%
cfg = finputcheck(varargin, ...
    {
    'condition','string',{'sustained','localizer','retinotopy'},''
    });

if nargout == 1
    outlist = [];
end

for SID = subjectlist
    bids_beh = fullfile(datadir,SID{1},'ses-01','beh');
    
    savefolder = fullfile(datadir,SID{1},'ses-01','func');
    if ~exist(savefolder,'dir')
        error('func folder has to exist')
    end
    
    if strcmp(cfg.condition,'localizer')
        nruns = 1;
    else
        nruns = length(dir(fullfile(bids_beh,'*_task-sustained_*.mat')));
    end
    
    tmp= load(fullfile(bids_beh,[SID{1} '_ses-01_task-sustained_run-1_log.mat']));
    if strcmp(cfg.condition,'sustained')
        exp_cfg = tmp.cfg.flicker; % for localizer and retinotopy it does not matter which run, only the tmp,cfg matters there
    else
        % we would love to always use this, but unfortunately I called the
        % field "filter" instead of the now default "sustained"
        exp_cfg = tmp.cfg.(cfg.condition);
    end
    switch cfg.condition
        
        case 'sustained'
            % each run is different for adapt
            out_save = [];
            for runid = 1:nruns
                % we have to reload the correct run
                try
                    tmp= load(fullfile(bids_beh,[SID{1} '_ses-01_task-sustained_run-' num2str(runid) '_log.mat']));
                    exp_cfg = tmp.cfg.flicker;
                    rando = tmp.randomization;
                catch
                    warning(sprintf('generateFSLDesign: could not find run %i',runid))
                    continue
                end
                
                % stimulus events
                stimuluslabel = {'45','135'};
                
                attention = rando.attention';
                stimulusOrient= stimuluslabel(rando.stimulus)';
                trial_type = rando.condition';
                
                onset = exp_cfg.scannerWaitTime + (exp_cfg.trialLength*2)*(0:length(trial_type)-1)';
                stimduration = exp_cfg.ITI;
                duration = repmat(stimduration,1,length(trial_type))';
                
                
                out = table(onset,duration,trial_type,stimulusOrient,attention);
                
                out.run = repmat(runid,size(out,1),1);
                
                writetable(out,fullfile(savefolder,[SID{1} '_ses-01_task-sustained_run-' num2str(runid) '_events.tsv']),'WriteVariableNames',1,'Delimiter','\t','FileType','text')
                
                out_save = [out_save;out];
            end
        case 'localizer'
            
            error("TODO")
            % First 3 Volumes are deleted by FEAT prior to this, therefore
            % the blocks start at time = 0 directly
            condition = repmat(exp_cfg.orientation,1,exp_cfg.numBlocks/2)';
            times = (exp_cfg.stimBlockLength + exp_cfg.offBlockLength)*(0:length(condition)-1)';
            duration = repmat(exp_cfg.stimBlockLength,1,length(condition))';
            value = repmat(1,1,length(condition))';
            
            out = table(condition,times,duration,value);
            
            
            writetable(out(out.condition==45,2:4),fullfile(savefolder,[SID{1} '_ses-01_task-localizer_desc-45DegOrientation.tsv']),'WriteVariableNames',0,'Delimiter','\t')
            writetable(out(out.condition==135,2:4),fullfile(savefolder,[SID{1} '_ses-01_task-localizer_desc-135DegOrientation.tsv']),'WriteVariableNames',0,'Delimiter','\t')
            
            out.run = repmat(1,size(out,1),1);
            out_save = out;
            
            
    end
    if nargout == 1
        out_save.times_volume = out_save.times/tmp.cfg.TR;
        outlist{end+1} = out_save;
    end
end
if nargout == 1
    varargout{1} = outlist;
end
end