KbName('UnifyKeyNames');
KbQueueCreate;
KbQueueFlush;
KbQueueStart;
WaitSecs(5);
[press, nremaining] = KbEventGet;
KbQueueStop;
KbQueueRelease;
KbQueueCreate;
KbQueueStart;
[press2, nremaining2] = KbEventGet;
KbQueueStop;
KbQueueRelease;
    