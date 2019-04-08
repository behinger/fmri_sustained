function setup_kbqueue(cfg)
% Keys that we want to listen for, buttons come in as 1-4 (49-52 ascii)

if isnan(cfg.bitsi_buttonbox)
ListenChar(0) % in case KbChar was used before, we deactivate it here

keyList = zeros(1,256);
keyList(cfg.keys) = 1;
KbQueueCreate([], keyList); % Create queue
% If this fails, try KbQueueCreate(1,keyList)

else
    
end