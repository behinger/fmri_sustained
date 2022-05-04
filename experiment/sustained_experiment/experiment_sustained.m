function experiment_sustained(cfg,randomization_run)
%--------------------------------------------------------------------------
if strcmp(class(cfg.bitsi_buttonbox),'Bitsi_Scanner')
    cfg.bitsi_buttonbox.clearResponses;
    cfg.bitsi_scanner.clearResponses;
end
cfg.numSavedResponses = 0;
subjectid = randomization_run.subject(1);
runid = randomization_run.run(1);

outFile = fullfile('.','MRI_data',sprintf('sub-%02i',subjectid),'ses-01','beh',...
    sprintf('sub-%02i_ses-01_task-sustained_run-%02i.mat',subjectid,runid));
if ~exist(fileparts(outFile),'dir')
    mkdir(fileparts(outFile))
end
fLog = fopen([outFile(1:end-3),'tsv'],'w');
if fLog == -1
    error('could not open logfile')
end
%print Header
fprintf(fLog,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n','onset','onsetTR','message','subject','run','block','condition','phase','stimulus');


Screen('FillRect', cfg.win, cfg.background);

%--------------------------------------------------------------------------
% Generate stimulus textures
Screen('DrawText',cfg.win,'Generating textures...', 100, 100);
Screen('Flip',cfg.win);
params = cfg.sustained;
cfg = setup_stimuli(cfg,params); % adapt must be a struct of cfg, e.g. cfg.adapt must exist with necessary information

%--------------------------------------------------------------------------
% setup kb queue


setup_kbqueue(cfg);
responses = [];
stimtimings = nan(6,length(randomization_run.run));
expectedtimings= nan(6,length(randomization_run.run));

%--------------------------------------------------------------------------
% Distractor Task Flicker randomization_run
nblocks = length(randomization_run.subject);


trialDistractor_dot = setup_distractortimings(params,nblocks,params.trialLength); % only when the stimulus is shown, but not in the first and last second

%--------------------------------------------------------------------------


%% Instructions
clicks = 0;
Screen('FillRect',cfg.win,cfg.background);

fprintf('Showing Instructions: waiting for mouse click (waiting for ScanTrigger after this)')

while ~any(clicks)
    introtex = cfg.stimTex(1);
    
    flicker = mod(GetSecs,1)<cfg.sustained.targetsDuration; % flicker every 1s
    
    
    if flicker
        colorInside = 255*cfg.sustained.targetsColor;
    else
        colorInside = 0;
    end
    instructions = 'Look at the fixation dot in the centre of the screen at all times\n\n\n\n Press a key if the FIXATION DOT flickers \n\n\n\n Run length: 5 minutes';
    Screen('DrawText',cfg.win,'Waiting for mouse click...', 100, 100);
    
    
    Screen('DrawTexture',cfg.win,introtex,[],OffsetRect(CenterRect([0 0, 0.5*cfg.stimsize],cfg.rect),cfg.width/4,0));
    
    
    
    [~,~,~] = DrawFormattedText(cfg.win, instructions, 'left', 'center'); % requesting 3 arguments disables clipping ;)
    draw_fixationdot(cfg,cfg.sustained.dotSize,0,colorInside,cfg.width/4*3,cfg.height/2)
    
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

if ~strcmp(class(cfg.bitsi_buttonbox),'Bitsi_Scanner')
    
    KbQueueStart(); % start trial press queue
end
%% Begin presenting stimuli
% Start with fixation cross

draw_fixationdot(cfg,params.dotSize)
startTime = Screen('Flip',cfg.win); % Store time experiment started
expectedTime = 0; % This will record what the expected event duration should be
firstTrial = true; % Flag to show we are on first trial
tic
for blockNum = 1:nblocks
        phase_ix = randomization_run.phase(blockNum); % just so every block starts with a different phase, could be random as well
    % Draw first reference stimulus after ITI
    if firstTrial
        expectedTime = expectedTime + params.scannerWaitTime;
        firstTrial = false;
        
    end
    
    switch randomization_run.stimulus{blockNum}
        case 'gabor45'
            rotationDecrement = 45;
            stimulusTexture = cfg.stimTex(phase_ix);
        case 'gabor135'
            rotationDecrement = 135;
            stimulusTexture = cfg.stimTex(phase_ix);
            
        case 'noise'
            error('shouldnt be here anymore')
            rotationDecrement = 0;
            %           
            stimulusTexture = cfg.stimTexPinkNoise(phase_ix);
        otherwise
            error('not implemented')
    end
    
    switch randomization_run.condition{blockNum}
        
        case 'continuous-4s'
            singleStimDuration = 4; 
            stimOffDuration = 0;
            params.trialLength = 4;
        case 'continuous-6s'
            singleStimDuration = 6; 
            stimOffDuration = 0;
            params.trialLength = 6;
        case 'continuous-8s'
            singleStimDuration = 8; 
            stimOffDuration = 0;
            params.trialLength = 8;
            
        case 'flashed-4s'
            singleStimDuration = 2*2*cfg.halfifi;
            params.trialLength = 4;
            n = 16; % siglani 2017, 30 stimuli a 2Frames in 8s
            stimOffDuration = (4-n*2*2*cfg.halfifi)/n;
        case 'flashed-6s'
            singleStimDuration = 2*2*cfg.halfifi;
            n = 24; % siglani 2017, 30 stimuli a 2Frames in 8s
            stimOffDuration = (6-n*2*2*cfg.halfifi)/n;
            params.trialLength = 6;
        case 'flashed-8s'
            singleStimDuration = 2*2*cfg.halfifi;
            n = 30; % siglani 2017, 30 stimuli a 2Frames in 8s
            stimOffDuration = (8-n*2*2*cfg.halfifi)/n;
            params.trialLength = 8;
        otherwise
            error('not implemented')
    end
    
        
  %%
%     expectedTime=0
    expectedTime_start = expectedTime;
    expectedtimings(1,blockNum) = expectedTime;
    
    
    firstStim = 0;
    distractorTiming_dot = trialDistractor_dot{blockNum}+expectedTime;

    drawingtime = 2*cfg.halfifi;
    draw_fixationdot(cfg,params.dotSize)
    
    while true
        % Show the stimulus
        Screen('DrawTexture',cfg.win,stimulusTexture,[],[],rotationDecrement);
        draw_fixationdot_task(cfg,params.dotSize,params.targetsColor*cfg.Lmax_rgb,distractorTiming_dot,startTime,expectedTime,drawingtime,1)
        stimOnset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi,1)-startTime;
        add_log_entry('stimOnset',stimOnset)
        
          % how long should the stimulus be on?
        expectedTime = expectedTime + singleStimDuration;
        % do the fixdotpoint flip if necessary
        draw_fixationdot_task(cfg,params.dotSize,params.targetsColor*cfg.Lmax_rgb,distractorTiming_dot,startTime,expectedTime,drawingtime)
        
        %draw a gray background on top of the stimulus
        Screen('DrawTexture',cfg.win,cfg.stimTexMask(1),[],[]);
        draw_fixationdot_task(cfg,params.dotSize,params.targetsColor*cfg.Lmax_rgb,distractorTiming_dot,startTime,expectedTime,drawingtime,1)
        stimOffset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi,1)-startTime;
        add_log_entry('stimOffset',stimOffset)
        
        
        % save for some kind of stimulus timing check
        if firstStim
            stimtimings(1,trialNum) = stimOnset;
            stimtimings(2,trialNum) = stimOffset;
            expectedtimings(2,trialNum) = expectedTime;
            firstStim = 0;
        end
        
        %how long should mask be one?
        expectedTime = expectedTime + stimOffDuration;
        
        % In case its necessary to flash the dot
        draw_fixationdot_task(cfg,params.dotSize,params.targetsColor*cfg.Lmax_rgb,distractorTiming_dot,startTime,expectedTime,drawingtime)
        % Exit if time is over
        if ((expectedTime - expectedTime_start)+2*drawingtime) > params.trialLength
            
            break
        end
        
        
    end
    
    Screen('FillRect',cfg.win,cfg.background)
    % Draw Mask against afterimage
    for k = 1:6
        
    Screen('DrawTexture',cfg.win,cfg.stimTexPlaid(1+mod(k,2)*6),[],[])
    
    draw_fixationdot(cfg,params.dotSize)
    
    
    onset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi+params.ITI/6*(k-1))-startTime;
    add_log_entry('breakOnset',onset);
   %% 
    
    % overwrite expected Time to catch up with minor fluctiations in
    % expected Time
%     expectedTime = expectedTime_start+params.trialLengthfullTR + params.ITI;
    
    
    end
    trialLengthfullTR = ceil(singleStimDuration/cfg.TR)*cfg.TR;
    expectedTime = expectedTime_start+trialLengthfullTR + params.ITI;
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
            add_log_entry('buttonpress',evt.Time-startTime);

            evt.blockNumber = blockNum;
            evt.TimeMinusStart = evt.Time - startTime;
%             evt.trialDistractor_stimulus = trialDistractor_stimulus{blockNum};
            evt.trialDistractor_dot = trialDistractor_dot{blockNum};
            evt.subject = randomization_run.subject(1);
            evt.run = randomization_run.run(1);
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
            save(outFile, 'randomization_run','cfg', 'responses','stimtimings','expectedtimings','trialDistractor_stimulus','trialDistractor_dot');
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

    function add_log_entry(varargin)
        if nargin <1
            message = '';
        else
            message = varargin{1};
        end
        if nargin < 2
            time = GetSecs-startTime;
        else
            time = varargin{2};
        end
        time_tr = time/cfg.TR;
        
        fprintf(fLog,'%.3f\t%.3f\t%s\t%03i\t%i\t%i\t%s\t%.3f\t%s\n',time,time_tr,message,...
            randomization_run.subject(blockNum),...
            randomization_run.run(blockNum),...
            randomization_run.block(blockNum),...
            randomization_run.condition{blockNum},...
            params.phases(randomization_run.phase(blockNum)),...
            randomization_run.stimulus{blockNum});
    end

    function draw_fixationdot_task(cfg,dotSize,targetsColor,distractorTiming_dot,startTime,expectedTime,drawingtime,noflip)
        if nargin == 7
            % in case we are shortly before the stimulus wait, we do not want to
            % flip, that would flip the stimulus as well.
            noflip = 0;
        end
        
        dotDuration= cfg.sustained.targetsDuration;
        
        distractorTiming_dot(distractorTiming_dot<(GetSecs-startTime-dotDuration-0.5*drawingtime)) = [];
        expectedTime = (expectedTime);
        currTime = GetSecs - startTime;
        % 4 cases
        draw_fixationdot(cfg,dotSize,0,0)
        
        if isempty(distractorTiming_dot)
            draw_fixationdot(cfg,dotSize,0,0)
            return
        end
        
        % %fprintf('----------\n')
        k = 1;
        %fprintf('currTime %.3f < distractorTime %.3f & dist+%.2f < expected %.3f \n',currTime,distractorTiming_dot(k),dotDuration,expectedTime)
        % %fprintf('%f > %f & show: %f < %f \n',currTime,distractorTiming_dot(k)+dotDuration,distractorTiming_dot(k)+dotDuration,expectedTime)
        % currTime 43.663 < distractorTime 44.499 & dist+0.10 < expected 44.667
        % I StimOnFlip 44.496428
        % I StimOffFlip 44.596432
        % mask: 3	 44.666667/45.666667
        % ----------
        % currTime 44.597 < distractorTime 44.499 & dist+0.10 < expected 44.667
        % II StimOn
        % II StimOnFlip 44.629722
        % II StimOffFlip 44.672060
        
        % distractorTiming_dot(1) = 44.499
        % expectedTime = 44.667;
        % drawingtime = 0.016;
        % dotDuration = 0.1
        % % currTime = 44.597;
        % currTime = 27.2
        
        % Time for Stim On & Stim Off?
        if ~noflip && (currTime< (distractorTiming_dot(1))) && ((distractorTiming_dot(1)+dotDuration) < expectedTime-drawingtime)
            
            draw_fixationdot(cfg,dotSize,0,targetsColor)
            when = Screen('Flip', cfg.win, startTime+distractorTiming_dot(1) - cfg.halfifi,1);
            add_log_entry('fixCatch',when-startTime)

            %fprintf('I StimOnFlip %f\n',when-startTime)
            draw_fixationdot(cfg,dotSize,0,0)
            
            % only flip if enough time, else let the stimulus flip do the work
            if (distractorTiming_dot(1)+drawingtime+dotDuration)< expectedTime
                
                when = Screen('Flip', cfg.win, startTime+distractorTiming_dot(1)+dotDuration - cfg.halfifi,1);
                %fprintf('I StimOffFlip %f\n',when-startTime)
            end
            
            % Time for Stim On?
        elseif (currTime< (distractorTiming_dot(1)+dotDuration)-drawingtime) && ((distractorTiming_dot(1)) < expectedTime)
            %fprintf('II StimOn \n')
            draw_fixationdot(cfg,dotSize,0,targetsColor)
            
            % only flip if enough time, else let the stimulus flip do the work
            if ~noflip && (distractorTiming_dot(1)+drawingtime)< expectedTime
                
                when = Screen('Flip', cfg.win, startTime+distractorTiming_dot(1) - cfg.halfifi,1);
                add_log_entry('fixCatch',when-startTime)
                %fprintf('II StimOnFlip %f \n',when-startTime)
                
                %         draw_fixationdot(cfg,dotSize,0,0)
            else
                add_log_entry('fixCatchNextStimulus')
            end
            
            % only flip if enough time, else let the stimulus flip do the work
            if (distractorTiming_dot(1)+drawingtime+dotDuration)< expectedTime
                
                draw_fixationdot(cfg,dotSize,0,0)
                
                when = Screen('Flip', cfg.win, startTime+distractorTiming_dot(1)+dotDuration - cfg.halfifi,1);
                %fprintf('II StimOffFlip %f\n',when-startTime)
            end
            
            % Time for Stim Off
        elseif ~noflip && currTime > distractorTiming_dot(1) &&  (distractorTiming_dot(1)+dotDuration) < expectedTime
            %fprintf('III StimnOffFlip \n')
            draw_fixationdot(cfg,dotSize,0,0)
            Screen('Flip', cfg.win, startTime+distractorTiming_dot(1)+dotDuration - cfg.halfifi,1);
            
        else
            %fprintf('IV StimnOff \n')
            draw_fixationdot(cfg,dotSize,0,0)
        end
    end
end
