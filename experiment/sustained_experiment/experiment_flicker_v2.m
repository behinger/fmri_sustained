function experiment_flicker_v2(cfg,randomization)
%--------------------------------------------------------------------------

subjectid = randomization.subject(1);
runid = randomization.run(1);

outFile = fullfile('.','MRI_data',sprintf('s%i',subjectid), sprintf('ADAPT_MRI_S%d_Run%d.mat',subjectid,runid));
if ~exist(fileparts(outFile),'dir')
    mkdir(fileparts(outFile))
end
Screen('FillRect', cfg.win, cfg.background);

%--------------------------------------------------------------------------
% Generate stimulus textures
Screen('DrawText',cfg.win,'Generating textures...', 100, 100);
Screen('Flip',cfg.win);
params = cfg.flicker;
cfg = setup_stimuli(cfg,params); % adapt must be a struct of cfg, e.g. cfg.adapt must exist with necessary information

%--------------------------------------------------------------------------
% setup kb queue
setup_kbqueue(0,params); % 0 = deviceID
responses = [];
stimtimings = nan(6,length(randomization.run));
expectedtimings= nan(6,length(randomization.run));

%--------------------------------------------------------------------------
% Distractor Task Flicker randomization
ntrial = length(randomization.subject);
% trialDistractor = setup_distractortimings(params,ntrial,params.ITI); %target only in ITI
trialDistractor = setup_distractortimings(params,ntrial,params.trialLength-2); % only when the stimulus is shown, but not in the first and last second
% not in the first second
for k = 1:length(trialDistractor)
    trialDistractor{k} = round(trialDistractor{k}+1); % We want to changes to be synchronous with the phase-switches

end

%--------------------------------------------------------------------------
% Wait for mouse click to begin

clicks = 0;
Screen('FillRect',cfg.win,cfg.background);
instructions = 'Look towards the dot in the centre of the screen at all times\n\n\n\n Press a key if the dot flickers \n\n\n\n Run length: 5 minutes';
Screen('DrawText',cfg.win,'Waiting for mouse click...', 100, 100);
[~,~,~] = DrawFormattedText(cfg.win, instructions, 'center', 'center'); % requesting 3 arguments disables clipping ;)
Screen('Flip',cfg.win);

fprintf('Instructions: waiting for mouse click (waiting for ScanTrigger after this)')
while clicks < 1
    clicks = GetClicks(cfg.win);
end
fprintf(' ... click\n')

%--------------------------------------------------------------------------
% Wait to detect first scanner pulse before starting experiment
if cfg.mriPulse == 1
    Screen('DrawText',cfg.win,'Waiting for mri scanner to be ready...', 100, 100);
    Screen('Flip',cfg.win);
    waitForScanTrigger_KB(cfg);
end

%--------------------------------------------------------------------------
% MAIN TRIAL LOOP


KbQueueStart(); % start trial press queue

% Begin presenting stimuli
% Start with fixation cross
draw_fixationdot(cfg,params.dotSize)
startTime = Screen('Flip',cfg.win); % Store time experiment started
expectedTime = 0; % This will record what the expected event duration should be
firstTrial = true; % Flag to show we are on first trial

for trialNum = 1:ntrial
    fprintf('Adaptation Trial %i from %i | ',trialNum,ntrial)
    
    % Draw first reference stimulus after ITI
    if firstTrial
        expectedTime = expectedTime + params.scannerWaitTime;
        firstTrial = false;
    else
        warning('DEBUG SPEEDUP')
        expectedTime = expectedTime;% + params.ITI;
    end
    
    singleStimDuration = (1/randomization.condition(trialNum))/2; %divided by two because half of it will be stimulus, half mask
    catchDuration = 1;%s
    warning('BalanceStimulation Time!!')
    
    %% FIRST STIMULUS
    expectedTime_start = expectedTime;
    expectedtimings(1,trialNum) = expectedTime;
    firstStim = 0;
    distractorTiming = trialDistractor{trialNum}+expectedTime;
    display(distractorTiming)
    phase_ix = randomization.phase(trialNum); % just so every trial starts with a different phase, could be random as well
    lastchange = 0;
    while true
        
        catchtype = 'spatialFreq';
        fprintf('%i\t %f/%f \n',trialNum,expectedTime,expectedTime+singleStimDuration)
        
        
        % Catch Trial on Stimulus?
        if any(distractorTiming>(expectedTime) & distractorTiming<(expectedTime+catchDuration))
            rotationDecrement = (randi([0,1],1)*2-1) * 45/4;
            warning('rotation! \n')
        else
            rotationDecrement = 0;
        end
        
        if expectedTime - lastchange >= 1
            % every second change the phase of the stimulus and choose a
            % new mask
            
            % Choose a new phase that is at least 2 different from the old
            % phase in order to make large jumps more prominent
            new_phase = randi(length(cfg.stimTex)-2,1)+2;
            phase_ix = phase_ix+new_phase;
            % we could have a phase_ix higher than the length of stimuli,
            % wrap around, add+1 because mod(12,12) = 0;
            phase_ix = mod(phase_ix,length(cfg.stimTex))+1;
            lastchange = expectedTime;
            fprintf('changed phase\n')
        end

        if strcmp(catchtype,'spatialFreq') && rotationDecrement ~=0
            Screen('DrawTexture',cfg.win,cfg.stimTexCatch(phase_ix),[],[],params.refOrient(randomization.stimulus(trialNum)));
        else 
            % Always 0 or in rotation condition
            Screen('DrawTexture',cfg.win,cfg.stimTex(phase_ix),[],[],rotationDecrement+params.refOrient(randomization.stimulus(trialNum)));
        end
        draw_fixationdot(cfg,params.dotSize)
        Screen('DrawingFinished', cfg.win);
        stimOnset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
        
        % how long should the stimulus be on?
        expectedTime = expectedTime + singleStimDuration;
        
        %% Mask       
        fprintf('%i\t %f/%f \n',trialNum,expectedTime,expectedTime+singleStimDuration)
        % Catch Trial on Mask
        if any(distractorTiming>(expectedTime) & distractorTiming<(expectedTime+catchDuration))
            rotationDecrement = (randi([0,1],1)*2-1) * 45/4;
            warning('rotation! \n')
        else
            rotationDecrement = 0;
        end
        
        if expectedTime - lastchange >= 1
            % every second change the phase of the stimulus and choose a
            % new mask
            
            % Choose a new phase that is at least 2 different from the old
            % phase in order to make large jumps more prominent
            new_phase = randi(length(cfg.stimTex)-2,1)+2;
            phase_ix = phase_ix+new_phase;
            % we could have a phase_ix higher than the length of stimuli,
            % wrap around, add+1 because mod(12,12) = 0;
            phase_ix = mod(phase_ix,length(cfg.stimTex))+1;
            lastchange = expectedTime;
            fprintf('changed phase\n')
        end

        
        if strcmp(catchtype,'spatialFreq') && rotationDecrement ~=0
            Screen('DrawTexture',cfg.win,cfg.stimTexMaskCatch(phase_ix),[],[],params.refOrient(randomization.stimulus(trialNum)));
        else
            Screen('DrawTexture',cfg.win,cfg.stimTexMask(phase_ix),[],[],rotationDecrement+params.refOrient(randomization.stimulus(trialNum)));
        end
        draw_fixationdot(cfg,params.dotSize)
        Screen('DrawingFinished', cfg.win);
        stimOffset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
        
        
        % save for some kind of stimulus timing check
        if firstStim
            stimtimings(1,trialNum) = stimOnset;
            stimtimings(2,trialNum) = stimOffset;
            expectedtimings(2,trialNum) = expectedTime;
            firstStim = 0;
        end
        
        %how long should mask be one?
        expectedTime = expectedTime + singleStimDuration;
        
        % Exit if time is over
        if (expectedTime - expectedTime_start) > params.trialLength
            break
        end
        
        
        
    end
    draw_fixationdot(cfg,params.dotSize)
    Screen('DrawingFinished', cfg.win);
    Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
    expectedTime = expectedTime + params.ITI;
    
    % Read out all the button presses
    while KbEventAvail()
        evt = KbEventGet();
        if evt.Pressed==1 % don't record key releases
            evt.trialnumber = trialNum;
            evt.TimeMinusStart = evt.Time - startTime;
            evt.trialDistractor = trialDistractor{trialNum};
            evt.subject = randomization.subject(1);
            evt.run = randomization.run(1);
            responses = [responses evt];
        end
    end
    
    % Safe quit mechanism (hold q to quit)
    [keyPr,~,key,~] = KbCheck;
    % && instead of & causes crashes here, for some reason
    key = find(key);
    if keyPr == 1 && strcmp(KbName(key(1)),'q')
        save_and_quit;
        return
    end
    
    
end  % END OF TRIAL LOOP

% Make sure wait till end of last ITI before stopping
expectedTime = expectedTime + params.ITI;

endTime = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);

KbQueueStop();	% Stop delivering events to the queue

disp(['Time elapsed was ',num2str(endTime - startTime),' seconds']);
disp(['(Should be ',num2str(expectedTime),' seconds)']);

% -----------------------------------------------------------------
% call function to save results, close window and clean up

save_and_quit;

    function save_and_quit
        
        % First dump everything to workspace just in case something goes
        % wrong
        assignin('base', 'responses', responses);
        
        % Save out results
        try
            save(outFile, 'randomization','cfg', 'responses','stimtimings','expectedtimings','trialDistractor');
        catch
            disp('Could not save outFile - may not exist');
        end
        % Clean up
        try
            jheapcl; % clean the java heap space
        catch
            disp('Could not clean java heap space');
        end
        
        disp('Quit safely');
    end

end