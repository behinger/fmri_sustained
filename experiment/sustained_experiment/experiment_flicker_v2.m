function experiment_flicker_v2(cfg,randomization)
%--------------------------------------------------------------------------
cfg.bitsi_buttonbox.clearResponses;
cfg.bitsi_scanner.clearResponses;
cfg.numSavedResponses = 0;
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


setup_kbqueue(cfg);
responses = [];
stimtimings = nan(6,length(randomization.run));
expectedtimings= nan(6,length(randomization.run));

%--------------------------------------------------------------------------
% Distractor Task Flicker randomization
ntrial = length(randomization.subject);
% trialDistractor = setup_distractortimings(params,ntrial,params.ITI); %target only in ITI
trialDistractor_stimulus = setup_distractortimings(params,ntrial,params.trialLength-2); % only when the stimulus is shown, but not in the first and last second
trialDistractor_dot = setup_distractortimings(params,ntrial,params.trialLength-2); % only when the stimulus is shown, but not in the first and last second
% not in the first second
for k = 1:length(trialDistractor_stimulus)
    trialDistractor_stimulus{k} = (trialDistractor_stimulus{k}+1);
    
    % We want to changes to be synchronous with the phase-switches
    
    
end

%--------------------------------------------------------------------------


%% Instructions
clicks = 0;
Screen('FillRect',cfg.win,cfg.background);
if strcmp(randomization.attention{1},'AttentionOnFixation')
    fprintf('Fixation Dot Flicker Block \n')
else
    fprintf('Stimulus Dot Flicker Block \n')
end
fprintf('Showing Instructions: waiting for mouse click (waiting for ScanTrigger after this)')

while ~any(clicks)
    colorInside = 0;
    introtex = cfg.stimTex(1);
    
    flicker = mod(GetSecs,1)<cfg.flicker.targetsDuration; % flicker every 1s
    if strcmp(randomization.attention{1},'attentionOnFixation')
        
        if flicker
            colorInside = 255*cfg.flicker.targetsColor;
        else
            colorInside = 0;
        end
        instructions = 'Look at the fixation dot in the centre of the screen at all times\n\n\n\n Press a key if the FIXATION DOT flickers \n\n\n\n Run length: 5 minutes';
        Screen('DrawText',cfg.win,'Waiting for mouse click...', 100, 100);
        
    else
        instructions = 'Look towards the dot in the centre of the screen at all times\n\n\n\n Press a key if the STIMULUS flickers \n\n\n\n Run length: 5 minutes';
        if flicker
            introtex = cfg.stimTexCatch(1);
        else
            % Always 0 or in rotation condition
            introtex = cfg.stimTex(1);
        end
    end
    Screen('DrawTexture',cfg.win,introtex,[],OffsetRect(CenterRect([0 0, 0.5*cfg.stimsize],cfg.rect),cfg.width/4,0));
    
    
    
    [~,~,~] = DrawFormattedText(cfg.win, instructions, 'left', 'center'); % requesting 3 arguments disables clipping ;)
    draw_fixationdot(cfg,cfg.flicker.dotSize,0,colorInside,cfg.width/4*3,cfg.height/2)
    
    Screen('Flip',cfg.win);
    
    
    [~,~,clicks] = GetMouse();
%     clicks

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

%% Begin presenting stimuli
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
    distractorTiming_stimulus = trialDistractor_stimulus{trialNum}+expectedTime;
    distractorTiming_dot = trialDistractor_dot{trialNum}+expectedTime;
%     display(distractorTiming_dot)
    phase_ix = randomization.phase(trialNum); % just so every trial starts with a different phase, could be random as well
    lastchange = 0;
    
    %take 10ms to draw everything, i.e. we will change the fixation dot only previous to stimonset if
    % disctractorTiming_dot < expectedTime-drawingtime
    drawingtime = 2*cfg.halfifi;
    draw_fixationdot(cfg,params.dotSize)
    stimOnset = 0;
    stimOffset = 0;
    while true
        
        catchtype = 'spatialFreq'; % could be 'rotation' as well
        if (abs(stimOffset-stimOnset)-singleStimDuration)>cfg.halfifi
            fprintf('----------------\n stim: %i\t %f/%f \n',trialNum,expectedTime,expectedTime+singleStimDuration)
            fprintf('Mask-Duration: %f \n',stimOffset-stimOnset)
        end
        % Define Rotation decrement (thisis also indicator of catch trial)
        if any(distractorTiming_stimulus>(expectedTime) & distractorTiming_stimulus<(expectedTime+catchDuration))
            rotationDecrement = (randi([0,1],1)*2-1) * 45/4;
            %             warning('stimulus-catch-trial! \n')
        else
            rotationDecrement = 0;
        end
        
        
        
        %         if expectedTime - lastchange >= 2
        % Choose a new phase that is at least 3 different from the old
        % phase in order to make large jumps more prominent
        new_phase = randi(length(cfg.stimTex)-3,1)+3;
        % go in either way in minimal steps of 3
        new_phase = randi([0,1])*2-1*new_phase;
        phase_ix = phase_ix+new_phase;
        % we could have a phase_ix higher than the length of stimuli,
        % wrap around, add+1 because mod(12,12) = 0;
        phase_ix = mod(phase_ix,length(cfg.stimTex))+1;
        lastchange = expectedTime;
        %         fprintf('changed phase\n')
        
        % if, while showing the mask, we shold have the onset of a white
        % dot, draw it & flip it
        
        
        
        if strcmp(catchtype,'spatialFreq') && rotationDecrement ~=0
            Screen('DrawTexture',cfg.win,cfg.stimTexCatch(phase_ix),[],[],params.refOrient(randomization.stimulus(trialNum)));
        else
            % Always 0 or in rotation condition
            Screen('DrawTexture',cfg.win,cfg.stimTex(phase_ix),[],[],rotationDecrement+params.refOrient(randomization.stimulus(trialNum)));
        end
        
        
        %         draw_fixationdot(cfg,params.dotSize)
        % if we should keep the white dot
        
        
        draw_fixationdot_task(cfg,params.dotSize,params.targetsColor*cfg.Lmax_rgb,distractorTiming_dot,startTime,expectedTime,drawingtime,1)
        stimOnset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi,1)-startTime;
        
        % how long should the stimulus be on?
        expectedTime = expectedTime + singleStimDuration;
        draw_fixationdot_task(cfg,params.dotSize,params.targetsColor*cfg.Lmax_rgb,distractorTiming_dot,startTime,expectedTime,drawingtime)
        %% Mask
        %         fprintf('mask: %i\t %f/%f \n',trialNum,expectedTime,expectedTime+singleStimDuration)
        % Catch Trial on Mask
        if any(distractorTiming_stimulus>(expectedTime) & distractorTiming_stimulus<(expectedTime+catchDuration))
            rotationDecrement = (randi([0,1],1)*2-1) * 45/4;
            %             warning('rotation! \n')
        else
            rotationDecrement = 0;
        end
     
        if strcmp(catchtype,'spatialFreq') && rotationDecrement ~=0
            Screen('DrawTexture',cfg.win,cfg.stimTexMaskCatch(phase_ix),[],[],params.refOrient(randomization.stimulus(trialNum)));
        else
            Screen('DrawTexture',cfg.win,cfg.stimTexMask(phase_ix),[],[],rotationDecrement+params.refOrient(randomization.stimulus(trialNum)));
        end
        
        %         Screen('DrawingFinished', cfg.win);
        
        draw_fixationdot_task(cfg,params.dotSize,params.targetsColor*cfg.Lmax_rgb,distractorTiming_dot,startTime,expectedTime,drawingtime,1)
        stimOffset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi,1)-startTime;
        if (abs(stimOffset-stimOnset)-singleStimDuration)>cfg.halfifi
            fprintf('Stim-Duration: %f \n',stimOffset-stimOnset);
        end
        % save for some kind of stimulus timing check
        if firstStim
            stimtimings(1,trialNum) = stimOnset;
            stimtimings(2,trialNum) = stimOffset;
            expectedtimings(2,trialNum) = expectedTime;
            firstStim = 0;
        end
        
        %how long should mask be one?
        expectedTime = expectedTime + singleStimDuration;
        draw_fixationdot_task(cfg,params.dotSize,params.targetsColor*cfg.Lmax_rgb,distractorTiming_dot,startTime,expectedTime,drawingtime)
        % Exit if time is over
        if (expectedTime - expectedTime_start) > params.trialLength
            break
        end
        
        
        
    end
    Screen('FillRect',cfg.win,cfg.background)
    draw_fixationdot(cfg,params.dotSize)
    
    Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
    
    
    expectedTime = expectedTime + params.ITI;
    
    % Read out all the button presses
    while true
        
        % only if we don't have a keyboard or bitsi input break
        if ~strcmp(class(cfg.bitsi_buttonbox),'Bitsi_Scanner')
            if ~KbEventAvail()
            break
            end
             evt = KbEventGet();
        else
            evt = struct();
            % wait max 0.1s, but we should not reach here anyway if there
            % are no buttons left
            [response,timestamp] = cfg.bitsi_buttonbox.getResponse(.1,true);
            if response == 0
                break
            end
            evt.Time = timestamp;
            evt.response = char(response);
            
            if lower(evt.response) == evt.response
                % lower letters for rising
                evt.Pressed = 1;
            else
                % upper letters for falling edge
                evt.Pressed = 0;
            end
        end
        if evt.Pressed==1 % don't record key releases
            evt.trialnumber = trialNum;
            evt.TimeMinusStart = evt.Time - startTime;
            evt.trialDistractor_stimulus = trialDistractor_stimulus{trialNum};
            evt.trialDistractor_dot = trialDistractor_dot{trialNum};
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
            save(outFile, 'randomization','cfg', 'responses','stimtimings','expectedtimings','trialDistractor_stimulus','trialDistractor_dot');
        catch
            disp('Could not save outFile - may not exist');
        end
        % Clean up
        try
            jheapcl; % clean the java heap space
        catch
            disp('Could not clean java heap space');
        end
   
        disp('Quit SubFunction safely');
        
    end

end