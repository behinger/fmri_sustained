function varargout  = setup_randomization_generate(subject,numRuns,numBlocks)

if nargin == 0
    error
end



assert(ceil(numBlocks/12) == floor(numBlocks/12)) % check that numBlocks is divisble by 6

rng(subject) % reset the random seed to make the randomization repeatable
randomization = struct('block',[],'condition',[],'stimulus',[],'run',[],'subject',[],'phase',[]);
% Path
addpath(fullfile('..','functions'));

for runNum = 1:numRuns
    
    
    % determine whether we use same or different stimuli trialtype
    condition_dict = {'continuous-8s','flashed-8s'};
    %     condition_dict = [18,12,2]; %=> 2*50ms, 2*125ms, 2*1000ms
    condition = repmat([0:length(condition_dict)-1],1,numBlocks/length(condition_dict));
    
    
    stimulus = repmat({'gabor45','gabor45','gabor135','gabor135'},1,numBlocks/4);
    phase = 1:numBlocks;
    rand_shuffle = randperm(numBlocks);
    
    randomization.condition = [randomization.condition condition_dict(condition(rand_shuffle)+1)];
    randomization.stimulus = [randomization.stimulus stimulus(rand_shuffle)];
    randomization.phase     = [randomization.phase phase(rand_shuffle)];
    
    
    randomization.block =[randomization.block 1:numBlocks];
    randomization.run =  [randomization.run repmat(runNum,1,numBlocks)];
    randomization.subject= [randomization.subject repmat(subject,1,numBlocks)];
end

assert(unique(structfun(@length,randomization)) == numBlocks * numRuns)

if ~exist('randomizations','dir')
    mkdir('randomizations')
end
save(fullfile('randomizations',['subject' num2str(subject), '_variables.mat']), 'randomization');
if nargout == 1
    varargout{1} = randomization;
end
end