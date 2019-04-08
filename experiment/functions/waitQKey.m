
function waitQKey(cfg)


if nargin ==0
    cfg = 0;
end
fprintf('press Q to safequit ... ')

for waitTime = 1:5
    fprintf('%i..',waitTime)
    % Safe quit routine - hold q to quit
    WaitSecs(1);
    [keyPr,~,key,~] = KbCheck;
    key = find(key);
    if keyPr == 1 && strcmp(KbName(key(1)), 'q')
        inp = input('Are you sure you want to quit the MAIN experiment (y/n)','s');
        if strcmp(inp,y)
            safeQuit(cfg);
            return
        end
    end
    
end
fprintf(' - SafeQuit End \n')

end