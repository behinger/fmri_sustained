function experiment_localizerOrientation(cfg,subjectid,run)
% Run localiser to identify voxels with preference for 45 or 135 degree
% orientations.
%
% Alternate between blocks of 45deg and 135deg gratings, with fixation
% blocks in between. Flicker grating on and off during block. Luminance
% detection task at fixation throughout.
%
% 13/10/2016 SJDL wrote it.
%
% 02/11/2016 V2 edit - timings adjusted for TR = 1050ms, also stimuli
% smoothed with Gaussian kernel (SD = 1 pixel) to soften hard edges
%
% 03/11/2016 V3 edit = using a different function to generate stimuli that
% smoothes the edges of the stimulus.
%
% Essen version designed to run in Essen, has longer TR
%
% 01/05/2017 V5 edit - designed to be called by another script that
% iterates through runs, so we don't have to enter expt info and relaunch
% between every run.


%--------------------------------------------------------------------------
% Set up queue for recording button presses

%--------------------------------------------------------------------------
assert(isnumeric(subjectid))
assert(isnumeric(run))

outFile = fullfile('.','MRI_data',sprintf('sub-%02i',subjectid),'ses-01','beh', sprintf('sub-%02i_ses-01_task-localizer_run-%02i.mat',subjectid,run));
if ~exist(fileparts(outFile),'dir')
    mkdir(fileparts(outFile))
end

fLog = fopen([outFile(1:end-3),'tsv'],'w');
if fLog == -1
    error('could not open logfile')
end
%print Header
fprintf(fLog,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n','onset','onsetTR','message','subjectid','run','block','orientation','phase');
Screen('FillRect', cfg.win, cfg.background);

%--------------------------------------------------------------------------
% Generate stimulus textures
Screen('DrawText',cfg.win,'Generating textures...', 100, 100);
Screen('Flip',cfg.win);
params = cfg.localizer;
cfg = setup_stimuli(cfg,params);
%--------------------------------------------------------------------------
setup_kbqueue(cfg);


%--------------------------------------------------------------------------
% Preallocate some variables for storing information
misses = 0;
hits = 0;

%--------------------------------------------------------------------------
% Wait for mouse click to begin
clicks = 0;
Screen('FillRect',cfg.win,cfg.background);
fprintf('Drawing Instructions \n')
instructions = 'Look towards the dot in the centre of the screen at all times\n\nPress the button with your index finger when this dot flashes\n\nRun length: 5 minutes';
Screen('DrawText',cfg.win,'Waiting for mouse click...', 100, 100);
DrawFormattedText(cfg.win, instructions, 'center', 'center');
Screen('Flip',cfg.win);

fprintf('Instructions: waiting for mouse click (waiting for ScanTrigger after this)')
while clicks < 1
    clicks = GetClicks(cfg.win);
end
fprintf('... click \n')
%--------------------------------------------------------------------------
% Flicker randomization
[flickers45,flickers45Timings,flickers135,flickers135Timings,flickersOff,flickersOffTimings] = setup_flickertimings_localizer(params);

%--------------------------------------------------------------------------
% Wait to detect first scanner pulse before starting experiment
if cfg.mriPulse == 1
    Screen('DrawText',cfg.win,'Waiting for mri pulse...', 100, 100);
    Screen('Flip',cfg.win);
    waitForScanTrigger_KB(cfg);
end



%--------------------------------------------------------------------------
% MAIN TRIAL LOOP

% Begin presenting stimuli
cfg.phases = repmat([1, 2], 1, round(params.stimPerBlock/2));%+1); % For indexing stimulus phase % +1 to avoid crashes when odd number of stim per block
% Start with fixation cross
draw_fixationdot(cfg,params.dotSize)
startTime = Screen('Flip',cfg.win); % Store time experiment started
expectedTime = 0; % This will record what the expected event duration should be

% Start recording key presses
if ~strcmp(class(cfg.bitsi_buttonbox),'Bitsi_Scanner')

KbQueueStart;
end
responses = [];
for blockNum = 1:params.numBlocks
    fprintf('Localizer (%i/%i):',blockNum,params.numBlocks)

    for stimNum = 1:params.stimPerBlock
        % Check for button presses in previous off block
        % (if on first stim of not the first block)
        if blockNum > 1 && stimNum == 1
            checkFixationResponse(2, blockNum - 1);
        end
        
        fprintf(',%i',stimNum)
        % Stimulus Block
        % If on first stim of first block need to wait for scanner wait time
        if blockNum == 1 && stimNum == 1
            expectedTime = expectedTime + params.scannerWaitTime;
        elseif stimNum == 1
            % If on first stim of this block need to wait for fixation block
            % length
            % Need to calculate how much time we spent on flickers and wait
            % the remainder of offBlockLength
            expectedTime = expectedTime + params.offBlockLength - (params.ISI+flickersOffTimings{blockNum-1}(end));
        else % Otherwise just wait for ISI
            expectedTime = expectedTime + params.ISI;
        end
        
        %
        % Present first stimulus
        % 135deg if on even block
        if mod(blockNum,2) == 0
            Screen('DrawTexture', cfg.win, cfg.stimTex(cfg.phases(stimNum)), [], [], params.orientation(2));
        else % Otherwise 45deg
            Screen('DrawTexture', cfg.win, cfg.stimTex(cfg.phases(stimNum)), [], [], params.orientation(1));
        end
        
        draw_fixationdot(cfg,params.dotSize)
        Screen('DrawingFinished', cfg.win);
        onset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
        if stimNum == 1; % for log entry
        add_log_entry('RestOffset',onset)
        end
        add_log_entry('stimOnset',onset)
        
        
        
        % Return to fixation after stimulus presentation time
        expectedTime = expectedTime + params.stimPres;
        % Find out if fixation should be changing this trial
        if mod(blockNum,2) == 0 % Even blocks, 135deg
            if find(flickers135Timings{round(blockNum/2)} == stimNum) >= 1
                draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
                mesg = 'stimOffsetWithFlicker';
            else
                draw_fixationdot(cfg,params.dotSize,0,0)
                mesg = 'stimOffset';
                
            end
        else % Odd blocks, 45deg
            if find(flickers45Timings{round(blockNum/2)} == stimNum) >= 1
                draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
                mesg = 'stimOffsetWithFlicker';
            else
                draw_fixationdot(cfg,params.dotSize,0,0)
                mesg = 'stimOffset';
            end
        end
        Screen('DrawingFinished', cfg.win);
        offset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
        add_log_entry(mesg,offset)
        
        % Safe quit mechanism (hold q to quit)
        [keyPr,~,key,~] = KbCheck;
        % && instead of & causes a crash here, for some reason - some
        % interaction with keyboard queue, I think
        if keyPr == 1 & any(strcmp(KbName(key),'q'))
            save_and_quit;
            return
        end
    end
    add_log_entry('RestOnset',GetSecs-startTime)

    % During off blocks, flicker fixation when we are supposed to
    for fl = 1:length(flickersOffTimings{blockNum})
        if fl == 1
            expectedTime = expectedTime + params.ISI + flickersOffTimings{blockNum}(fl);
        else
            expectedTime = expectedTime + (flickersOffTimings{blockNum}(fl) - (flickersOffTimings{blockNum}(fl-1) + params.ISI));
        end
        draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
        Screen('DrawingFinished', cfg.win);
        flickerOn = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
        add_log_entry('flickerInPause',flickerOn)
        
        if fl == 1
            % At this point check for button presses in previous stim block
            checkFixationResponse(1, blockNum);
        end
        % Flick back after .25s (equal to ISI)
        expectedTime = expectedTime + params.ISI;
        draw_fixationdot(cfg,params.dotSize,0,0)
        Screen('DrawingFinished', cfg.win);
        Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);  
    end
end

% Make sure we wait for last fixation block before stopping
expectedTime = expectedTime + params.offBlockLength - (flickersOffTimings{blockNum}(end) + params.ISI);
endTime = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);

% Check for button presses for last off block
checkFixationResponse(2, blockNum);

Priority(0); % Reset priority

disp(['Time elapsed was ',num2str(endTime - startTime),' seconds']);
disp(['(Should be ',num2str(expectedTime),' seconds)']);

% -----------------------------------------------------------------
% call function to save results, close cfg.win and clean up

save_and_quit;

    function save_and_quit
        
        % Save results
        save(outFile, 'flickers45Timings', 'flickers135Timings', 'flickersOffTimings', 'responses','hits', 'misses');
        try
            jheapcl; % clean the java heap space
        catch
            disp('Could not clean java heap space');
        end
        
        % Close keyboard queue
        KbQueueStop;
        KbQueueRelease;
        
        disp('Quit safely');
    end

% Function for checking button presses
    function checkFixationResponse(blockType,blockInd)
        
        % For blockType, 1 = stim block and 2 = off block
        
        % Check how many flickers there were
        if blockType == 1 % Stimulus blocktrialDistractor_stimulus
            if mod(blockInd,2) == 0 % 135 degrees
                numFlickers = length(flickers135Timings{round(blockInd/2)});
            else % 45 degrees
                numFlickers = length(flickers45Timings{round(blockInd/2)});
            end
        elseif blockType == 2 % Off block
            numFlickers = length(flickersOffTimings{blockInd});
        end
        
        
        numPresses = 0;
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
                add_log_entry('ButtonPress',evt.Time-startTime)

                evt.trialnumber = blockNum;
                evt.TimeMinusStart = evt.Time - startTime;
                
                evt.trialDistractor_45= flickers45Timings{blockNum};
                evt.trialDistractor_135 = flickers135Timings{blockNum};
                evt.trialDistractor_off = flickersOffTimings{blockNum};

                evt.subjectid = subjectid(1);
                evt.run = run(1);
                responses = [responses evt];
            end
            numPresses = numPresses+1;
        end
        misses_thisTrial = numFlickers - numPresses;
        hits_thisTrial = numFlickers - misses_thisTrial;
        
        % Update hit and miss counters
        hits = hits + hits_thisTrial;
        misses = misses + misses_thisTrial;
        if blockType ~=2
            fprintf(' hits:%i, misses:%i\n',hits,misses)
        end
        
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
        fprintf(fLog,'%.3f\t%.3f\t%s\t%03i\t%i\t%i\t%i\t%.1f\n',time,time_tr,message,...
            subjectid,...
            run,...
            blockNum,...
            params.orientation(1+(mod(blockNum,2) == 0)),...
            cfg.phases(stimNum));
    end
end