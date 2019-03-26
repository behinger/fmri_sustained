cfg = struct();
cfg.computer_environment = 'mri'; % could be "mri", "dummy", "work_station", "behav"
cfg.mri_scanner = 'essen'; % could be "trio", "avanto","prisma", "essen"
cfg.debug = 1;
cfg.CAIPI = 1;
cfg = setup_parameters(cfg);
whichScreen = max(Screen('Screens')); %Screen ID
cfg = setup_window(cfg,whichScreen);

%% Draw Fixation Dot
fprintf('10s fixation dot color change:')
Screen('FillRect',cfg.win,cfg.background)

for k = 1:100
    fprintf('..%i',k)
%     [~,ppd] = degrees2pixels(1,cfg.distFromScreen,cfg.pixelsPerCm);
%     dotsize = [1/ppd*4,1/ppd]*4;
    dotsize = 1.5*[0.25 0.06];
    draw_fixationdot(cfg,dotsize,0,mod(k,2)*cfg.Lmax_rgb)
    Screen('Flip',cfg.win);
    % Flick Fixcross every 750ms for 250ms
    WaitSecs(cfg.adapt.flickerDuration + mod(k+1,2)*0.5);
    
end

%% MRI Trigger
waitForScanTrigger_KB(cfg);

%% Test Buttonpress
setup_kbqueue(0,cfg.adapt); % 0 = deviceID
KbEventGet()
KbQueueStart()
fprintf('10s time to press button:')
for k = 1:20
    fprintf('..%i',k)
    WaitSecs(1);
    while KbEventAvail()
        evt = KbEventGet();
        if evt.Pressed==1
            fprintf('.. key:%s ',KbName(evt.Keycode))
        end
    end
end
fprintf('\n')
