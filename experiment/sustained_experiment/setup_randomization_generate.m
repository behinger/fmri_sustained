function varargout  = setup_randomization_generate(subject,numRuns,numTrials)

if nargin == 0
    error
end



assert(ceil(numTrials/6) == floor(numTrials/6)) % check that numTrials is divisble by 6

rng(subject) % reset the random seed to make the randomization repeatable
randomization = struct('trial',[],'condition',[],'stimulus',[],'run',[],'subject',[],'phase',[],'attention',[]);
randomization.attention = {};
attentionList = {'attentionOnStimulus','attentionOnFixation'};
for runNum = 1:numRuns
    
    % Path
    addpath(fullfile('..','functions'));
    
    % determine whether we use same or different stimuli trialtype
    condition_dict = [6,2,0.5]; %=> 2*50ms, 2*125ms, 2*1000ms
%     condition_dict = [18,12,2]; %=> 2*50ms, 2*125ms, 2*1000ms
    condition = repmat([0 1,2],1,numTrials/length(condition_dict));
    
    
    stimulus = repmat([0 0 0 1 1 1],1,numTrials/6);
    phase = 1:numTrials;
    rand_shuffle = randperm(numTrials);
    
    randomization.condition = [randomization.condition condition_dict(condition(rand_shuffle)+1)];
    randomization.stimulus = [randomization.stimulus stimulus(rand_shuffle)+1];
    randomization.phase     = [randomization.phase phase(rand_shuffle)];
    
    randomization.attention = [randomization.attention repmat(attentionList(mod(mod(subject,2)+runNum,2)+1),1,numTrials)];
    randomization.trial =[randomization.trial 1:numTrials];
    randomization.run =  [randomization.run repmat(runNum,1,numTrials)];
    randomization.subject= [randomization.subject repmat(subject,1,numTrials)];
end


assert(unique(structfun(@length,randomization)) == numTrials * numRuns)

if ~exist('randomizations','dir')
    mkdir('randomizations')
end
save(fullfile('randomizations',['subject' num2str(subject), '_variables.mat']), 'randomization');
if nargout == 1
    varargout{1} = randomization;
end
end