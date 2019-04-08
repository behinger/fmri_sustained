function cfg = setup_window(cfg,whichScreen)
% Open window and set font

% from the laptop we often have troubles to start the screen, so I will try
% it immediately 10 times before exiting
for k = 1:10
    try
        [cfg.win, cfg.rect] = Screen('OpenWindow',whichScreen);
        break
    catch
    end
end

cfg.width = cfg.rect(3);
cfg.height = cfg.rect(4);

% Screen('TextFont',cfg.win, 'Arial');
% Screen('TextSize',cfg.win, 20);

if ~cfg.debug
    Priority(1); % Set priority
    fprintf('Set Priority to 1\n')
    HideCursor(cfg.win);
    
end

KbName('UnifyKeyNames')

Screen('DrawText',cfg.win,'Estimating monitor flip interval...', 100, 100);
Screen('DrawText',cfg.win,'(This may take up to 20s)', 100, 120);
Screen('Flip',cfg.win);
% if cfg.debug
%     halfifi = 1/60;
% else
halfifi = Screen('GetFlipInterval', cfg.win, 100, 0.00005, 20);
% end
cfg.halfifi = halfifi/2;


