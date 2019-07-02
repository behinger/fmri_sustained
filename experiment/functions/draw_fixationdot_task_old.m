function draw_fixationdot_task(cfg,dotSize,targetsColor,distractorTiming_dot,startTime,expectedTime,drawingtime,noflip)
if nargin == 7
    % in case we are shortly before the stimulus wait, we do not want to
    % flip, that would flip the stimulus as well.
    noflip = 0;
end

dotDuration= cfg.flicker.targetsDuration;

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
        %fprintf('II StimOnFlip %f \n',when-startTime)
        
        %         draw_fixationdot(cfg,dotSize,0,0)
        
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