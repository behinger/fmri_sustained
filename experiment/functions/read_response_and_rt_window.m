function [response, rt] = read_response_and_rt_window(responseWindow, expectedKeys)

% Function that will wait for an expected key press, then return it (response)
% and the time elapsed since the function was called (rt)
% Expected keys are currently set up below and will need to be changed
% if you are expecting different responses, but this should be fine for any
% psychophysics or TMS experiments we are currently running.

% Written by SL, 19/01/2014

% SL edit 11/10/2016
% Now specificy response window in input, whiich is the maximum amount of
% time the function will wait for a response. Response will be 'm' if
% missed.

% SL edit 30/01/2017
% Can now specify expected keys with second input argument, if nothing is
% specified will use old defaults.

% First get the current time to be used to calculate reaction time
startTime  = GetSecs;

% Create a cell array containing all the key presses we are expecting - any
% key press that is not stored in the array will be ignored
if nargin < 2
    expectedKeys = {'z','x','q'};
end

% Flush any currently stored key presses - Bruce's response functions don't
% seem to use this so may not be necessary but doing it for now
% Commenting out the flush because it seems to cause a lag in reading
% responses that can cause a failure to read quick responses.
%FlushEvents;

% response empty to start
response = [];

% While we haven't received a response...
while isempty(response)

    % Get the response and timing of th response
    [~, secs, keyCode] = KbCheck;
    
    % Translate keyCode into the key pressed
    response = KbName(keyCode);
    
    % Check if the key pressed was one we expected
    a = find(strcmp(response,expectedKeys) == 1, 1);
    
    % If the response was not one of the keys we were expecting, then make
    % response empty again and wait for another response. 
    if isempty(a)
        response = [];
    end
    
    % If we have been going on for too long then break
    if GetSecs > startTime + responseWindow
        response = 'm'; %m for miss
        break
    end
    
end

% Calculate reaction time
rt = secs - startTime;

end