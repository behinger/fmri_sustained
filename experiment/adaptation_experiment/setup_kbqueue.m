function setup_kbqueue(deviceIndex,params)
% Keys that we want to listen for, buttons come in as 1-4 (49-52 ascii)
ListenChar(0) % in case KbChar was used before, we deactivate it here

keyList = zeros(1,256);
keyList(params.keys) = 1;
KbQueueCreate(deviceIndex, keyList); % Create queue
