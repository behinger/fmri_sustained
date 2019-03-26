function [window,width,height] = openScreen(windowPtrOrScreenNumber)
% [window,wRect,keyboardNumber,midW,midH] = openScreen(windowPtrOrScreenNumber)
%
% Opens a new screen using windowPtrOrScreenNumber.
% If no input is provided, screen is opened on max(Screen('Screens')).
%
% Performs some common commands to do at experiment startup.
% - sets highest priority level
% - initializes some MEX files
% - hides cursor
% - unifies key names

%%%%% open window
if ~exist('windowPtrOrScreenNumber','var') || isempty(windowPtrOrScreenNumber)
    windowPtrOrScreenNumber = max(Screen('Screens'));
end

% [window,wRect] = Screen('OpenWindow', windowPtrOrScreenNumber, 127, [0 0 1024 768]);
[window,wRect] = Screen('OpenWindow', windowPtrOrScreenNumber, 127);

%%%%% get screen midpoint
rect = Screen('Rect',window);

width=rect(3);
height=rect(4);

midW = width/2;
midH = height/2;

%%%%% do other useful PTB startup stuff
priorityLevel=MaxPriority(window);
Priority(priorityLevel);

HideCursor;

KbName('UnifyKeyNames');

%%%%% initialize some commonly used mex files
% these files take a bit of time to load the first time around
GetSecs;
WaitSecs(.001);

if  IsOSX
    d=PsychHID('Devices');
    keyboardNumber = 0;
    
    for n = 1:length(d)
        if strcmp(d(n).usageName,'Keyboard');
            keyboardNumber=n;
            break
        end
    end
    KbCheck(keyboardNumber);
else
    keyboardNumber = [];
    KbCheck;
end