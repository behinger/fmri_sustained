% Wait for scanner trigger using keyboard input (trigger comes in as a 5)
function waitForScanTrigger_KB(cfg)
if nargin == 1&& cfg.mriPulse && strcmp(class(cfg.bitsi_scanner),'Bitsi_Scanner')
    cfg.bitsi_scanner.clearResponses()
    cfg.bitsi_scanner.getResponse(60,true)
    return
end
fprintf(' Waiting for MR trigger ... ')
KbName('UnifyKeyNames');
KbEventFlush;
trigger = 0;
while trigger == 0
    [~, keyCode] = KbWait;
    keyPressed = KbName(keyCode);
    if any(strcmp(keyPressed(1),'t')) || any(strcmp(keyPressed(1),'5'))
        trigger = 1;
    end
end
fprintf(' ... Trigger received \n')
end
