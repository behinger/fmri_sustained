function experiment_adaptation(cfg,randomization)
%--------------------------------------------------------------------------
% Set up queue for recording button presses
% Keys that we want to listen for, buttons come in 1!, 2@ etc.
keys = {'1!', '2@'};


if cfg.debug
    ntrial = 10;
end

subjectid = randomization.subject(1);runid = randomization.run(1);
outFile = fullfile('.','MRI_data',sprintf('s%i',subjectid), sprintf('ADAPT_MRI_S%d_Run%d.mat',subjectid,runid));
if ~exist(fileparts(outFile),'dir')
    mkdir(fileparts(outFile))
end
Screen('FillRect', cfg.win, cfg.background);

%--------------------------------------------------------------------------
% Generate stimulus textures
Screen('DrawText',cfg.win,'Generating textures...', 100, 100);
Screen('Flip',cfg.win);
params = cfg.adapt;
cfg = setup_stimuli(cfg,params); % adapt must be a struct of cfg, e.g. cfg.adapt must exist with necessary information

%--------------------------------------------------------------------------
% setup kb queue
setup_kbqueue(0,params); % 0 = deviceID
responses = [];
stimtimings = nan(6,length(randomization.run));
expectedtimings= nan(6,length(randomization.run));

%--------------------------------------------------------------------------
% Flicker randomization
ntrial = length(randomization.subject);
trialFlicker = setup_flickertimings(params,ntrial,params.ITI); %flicker only in ITI


%--------------------------------------------------------------------------
% Wait for mouse click to begin
clicks = 0;
Screen('FillRect',cfg.win,cfg.background);
instructions = 'Look towards the dot in the centre of the screen at all times\n\n Press a key if the dot flickers \n\n Run length: 9 minutes';
Screen('DrawText',cfg.win,'Waiting for mouse click...', 100, 100);
DrawFormattedText(cfg.win, instructions, 'center', 'center');
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
        expectedTime = expectedTime + params.ITI;
    end

    
    
    
    % FIRST STIMULUS
    Screen('DrawTexture',cfg.win,cfg.stimTex(1),[],[],params.refOrient(randomization.stimulus1(trialNum)));
    draw_fixationdot(cfg,params.dotSize)
    Screen('DrawingFinished', cfg.win);
    stimtimings(1,trialNum) = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
    expectedtimings(1,trialNum) = expectedTime;
    fprintf('1st...')
    % PAUSE
    expectedTime = expectedTime + params.stim1Pres;
    draw_fixationdot(cfg,params.dotSize)
    Screen('DrawingFinished', cfg.win);
    stimtimings(2,trialNum) = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
    expectedtimings(2,trialNum) = expectedTime;
    fprintf('pause...')
    % SECOND STIMULUS
    expectedTime = expectedTime + params.ISI;
    Screen('DrawTexture',cfg.win,cfg.stimTex(1),[],[],params.refOrient(randomization.stimulus2(trialNum)));
    draw_fixationdot(cfg,params.dotSize)
    Screen('DrawingFinished', cfg.win);
    stimtimings(3,trialNum) = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
    expectedtimings(3,trialNum) = expectedTime;
    fprintf('2nd...')
    % FIXATION
    expectedTime = expectedTime + params.stim2Pres;
    draw_fixationdot(cfg,params.dotSize)
    Screen('DrawingFinished', cfg.win);
    stimtimings(4,trialNum) = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
    expectedtimings(4,trialNum) = expectedTime;
    fprintf('long pause...\n')
    if ~isempty(trialFlicker{trialNum})
        for flickertime  = 1:length(trialFlicker{trialNum})
            
            % flicker on
            % flicker gets their own expectedTime to not disturb others
            expectedTime_flicker = expectedTime + trialFlicker{trialNum}(flickertime);
            % Parameters: size (inner outer in deg), black outer, white inner
            draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
            Screen('DrawingFinished', cfg.win);
            stimtimings(5,trialNum) = Screen('Flip', cfg.win, startTime + expectedTime_flicker - cfg.halfifi)-startTime;
            expectedtimings(5,trialNum) = expectedTime_flicker;
            
            % reset to normal color after params.flickerColor
            expectedTime_flicker = expectedTime_flicker + params.flickerDuration;
            draw_fixationdot(cfg,params.dotSize)
            Screen('DrawingFinished', cfg.win);
            stimtimings(6,trialNum) = Screen('Flip', cfg.win, startTime + expectedTime_flicker - cfg.halfifi)-startTime;
            expectedtimings(6,trialNum) = expectedTime_flicker;
        end
        
    end
    
    % Read out all the button presses
    while KbEventAvail()
        evt = KbEventGet();
        if evt.Pressed==1 % don't record key releases
            evt.trialnumber = trialNum;
            evt.TimeMinusStart = evt.Time - startTime;
            evt.trialFlicker = trialFlicker{trialNum};
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
            save(outFile, 'randomization','cfg', 'responses','stimtimings','expectedtimings','trialFlicker');
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