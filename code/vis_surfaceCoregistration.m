% Visualise results of recursive boundary registration

% Subjects to process
function vis_surfaceCoregistration(datadir,SID,varargin)
cfg = finputcheck(varargin, ...
    { 'slicelist'         'integer'   []       []; ...
    'axis',             'string', {'x','y','z'}, 'z';...
    'boundary_identifier'       'string'     []    'Anat2FuncBoundaries_recurs' ; ...
    'functional_identifier'     'string'     []    '%s_ses-01_task-%s_desc-occipitalcropMeanBias_bold.nii';
    'task','string',[],'sustained'
    });
if ischar(cfg)
    error(cfg)
end

cfg.functional_identifier = sprintf(cfg.functional_identifier,SID,cfg.task);
cfg.boundary_identifier = sprintf(cfg.boundary_identifier,SID);

configuration = [];
subjectDirectory = fullfile(datadir, SID);
subjectDirectory = fullfile(datadir,'derivates','preprocessing',SID,'ses-01');
functional = spm_vol(fullfile(subjectDirectory, 'func',cfg.functional_identifier));
configuration.i_Volume = spm_read_vols(functional);
%dimension = 1;
configuration.i_Axis = cfg.axis;

if isempty(cfg.slicelist)
    
    cfg.slicelist = unique(round(linspace(1,functional.dim(cfg.axis=='xyz'),24)));
end

load(fullfile(subjectDirectory, 'coreg',[cfg.boundary_identifier '.mat']), 'wSurface', 'pSurface', 'faceData');
configuration.i_Vertices{1} = wSurface;
configuration.i_Vertices{2} = pSurface;
configuration.i_Faces{1} = faceData;
configuration.i_Faces{2} = faceData;

%for curSlice = 1:3:30
for curSlice = 1:length(cfg.slicelist)
    if curSlice == 1
        figure
    end
    if length(cfg.slicelist)>1
        switch cfg.axis
            case 'x'
                m_row = ceil(sqrt(length(cfg.slicelist)));
                n_col = ceil(sqrt(length(cfg.slicelist)));
            case 'y'
                n_col = 3;
                m_row = ceil(length(cfg.slicelist)/n_col);
                
            case 'z'
                m_row = 3;
                n_col = ceil(length(cfg.slicelist)/m_row);
        end
        subplot_er(m_row,n_col,curSlice);
        
    end
    
    
    configuration.i_Slice = cfg.slicelist(curSlice);
    
  
    tvm_showObjectContourOnSlice(configuration);
    
    

%     text(0.01,0.01,sprintf('Slice %i \nBound: %s\nFunctional: %s',cfg.slicelist(curSlice),cfg.boundary_identifier,cfg.functional_identifier),'VerticalAlignment','bottom','units','normalized','Fontsize',7,'Interpreter','none','Color','White')
end

splt = strsplit(cfg.boundary_identifier,'_');


% '%s_ses-01_from-ANATCROPPED_to-FUNCCROPPED_mode-surface','
splt(3:4) = [];
ix = strfind(splt,'desc');
ix = cellfun(@(x)isempty(ix),ix);
if any(ix)
    splt{ix} = [splt{ix} '%s%s'];
else
    splt(end+1) = splt(end);
    splt{end-1} = 'desc-%s%s';
end

if ~exist(fullfile(subjectDirectory,'surface'),'dir')
    mkdir(fullfile(subjectDirectory,'surface'))
end

for hemisphere = {'left','right'}
    for surface = {'white','gray'}
        fName= fullfile(subjectDirectory,'surface',sprintf(strjoin(splt,'_'),surface{1},hemisphere{1}));
        
        switch surface{1}
            case 'white'
                surf = wSurface;
            case 'gray'
                surf = pSurface;
        end
        tvm_exportObjFile(surf{strcmp(hemisphere{1},'right')+1}, faceData{strcmp(hemisphere{1},'right')+1}, fName)


    end
end


clear configuration;


