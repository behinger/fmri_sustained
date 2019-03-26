function varargout  = setup_randomization_generate(subject)
if nargin == 0
    error
end
numRuns = 6; % Number of runs
numTrials = 40 ; % Number of trials in a run


randomization = [];
assert(ceil(numTrials/4) == floor(numTrials/4)) % check that numTrials is divisble by 2

rng(subject) % reset the random seed to make the randomization repeatable
randomization = struct('trial',[],'stimulus1',[],'stimulus2',[],'trialtype',[],'run',[],'subject',[]);
randomization.trialtype = {}; % because if we initialize directly as cell, the struct function works differently
for runNum = 1:numRuns
    % Path
    addpath('.\..\Functions');
    
    % determine whether we use same or different stimuli trialtype
    trialtype_dict = {'same','diff'};
    trialtype = repmat([0 1],1,numTrials/2); %Create_pseudo_randomised_list([1,2,3,4], numTrials/4);
    
    
    stimulus1 = repmat([0 0 1 1],1,numTrials/4);
    stimulus2 = stimulus1;
    stimulus2(trialtype==1) = abs(stimulus2(trialtype==1)-1); %flip for diff trials
    
    rand_shuffle = randperm(numTrials);
    
    randomization.trialtype = [randomization.trialtype trialtype_dict(trialtype(rand_shuffle)+1)];
    randomization.stimulus1 = [randomization.stimulus1 stimulus1(rand_shuffle)+1];
    randomization.stimulus2 = [randomization.stimulus2 stimulus2(rand_shuffle)+1];
    
    randomization.trial =[randomization.trial 1:numTrials];
    randomization.run =  [randomization.run repmat(runNum,1,numTrials)];
    randomization.subject= [randomization.subject repmat(subject,1,numTrials)];
end


assert(strcmp(unique({randomization.trialtype{randomization.stimulus1 == randomization.stimulus2}}),'same'))
assert(strcmp(unique({randomization.trialtype{randomization.stimulus1 ~= randomization.stimulus2}}),'diff'))
assert(unique(structfun(@length,randomization)) == numTrials * numRuns)

if ~exist('randomizations','dir')
    mkdir('randomizations')
end
save(['.\randomizations\subject', num2str(subject), '_variables.mat'], 'randomization');
if nargout == 1
    varargout{1} = randomization;
end
end