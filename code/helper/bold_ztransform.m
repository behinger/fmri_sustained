function timeCourse_z = bold_ztransform(timeCourse,varargin)

cfg = finputcheck(varargin, ...
    { 'robust'         'boolean'   []    1; ... % Use median and mad instead of mean + sd
    
    });


if cfg.robust
    location = median(timeCourse,4);
    spread = 1.4826*mad(timeCourse,1,4);
else
    location = mean(timeCourse,4);
    spread = std(timeCourse,[],4);
    
end

timeCourse_z = (timeCourse-location)./spread;
