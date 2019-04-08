
function safeQuit

% Close window
Screen('Close');
Screen('Closeall');
%
% Clean up
try
    jheapcl; % clean the java heap space
catch
    disp('Could not clean java heap space');
end

disp('Quit safely');
end