function trialFlicker = setup_distractortimings(params,ntrial,flickertimeOneTrial)
assert(all(isfield(params,{'targetsPerTrial','targetsTimeDelta'})))
totalFlicker = floor(params.targetsPerTrial * ntrial);
minDist = params.targetsTimeDelta;

% flickertimeOneTrial = params.ITI;


flickertime = flickertimeOneTrial*ntrial;

flickertimings = sort(rand(totalFlicker,1)*flickertime);
while any(diff(flickertimings)<minDist)
    flickertimings = sort(rand(totalFlicker,1)*flickertime);
end

whichTrial = ceil(flickertimings./flickertimeOneTrial);
whenInTrial = mod(flickertimings,flickertimeOneTrial);

trialFlicker = cell(ntrial,1);
for tr = 1:length(whichTrial)
    trialFlicker{whichTrial(tr)} =  [trialFlicker{whichTrial(tr)} whenInTrial(tr)];
end
% just a check to be sure
tmp = cellfun(@(x)diff(x)<minDist,trialFlicker,'UniformOutput',0);
tmpix = cellfun(@(x)~isempty(x),tmp);
assert(all([tmp{tmpix}]==0));


