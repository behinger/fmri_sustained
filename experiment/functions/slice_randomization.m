function [slice] = slice_randomization(rand,subject,run)

% Example call:
% slice.(fn{1}) = rand.(fn{1}){select};
select = rand.run == run & rand.subject == subject;
if sum(select)==0
    error('something went wrong, empty randomizationselection')
end
slice= struct();
for fn = fieldnames(rand)'
    %if iscell(rand.(fn{1}))
    %    slice.(fn{1}) = rand.(fn{1}){select};
    %else
        slice.(fn{1}) = rand.(fn{1})(select);
    %end
end
end