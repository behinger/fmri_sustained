[surf,fnum] = read_surf('/project/3018028.04/benehi/sustained/data/pilot/bids/derivates/freesurfer/sub-01/ses-01/surf/rh.pial');
[curv,fnum] = read_curv('/project/3018028.04/benehi/sustained/data/pilot/bids/derivates/freesurfer/sub-01/ses-01/surf/rh.benson14_varea');


for area = {'V1','V2','V3'}
    out = fopen(sprintf('test%s.thresho.label',area{1}),'w')
   switch area{1}
       case 'V1'
           ix = curv == 1;
       case 'V2'
           ix = curv == 2;
       case 'V3'
           ix = curv == 3;
   end

    fprintf(out,'#!ascii label  , from subject ses-01 vox2ras=TkReg\n');
    fprintf(out,'%i\n',sum(ix));
    
    fprintf(out,'%i  %.3f  %.3f  %.3f 0.0000000000\n',[find(ix),surf(ix,1),surf(ix,2),surf(ix,3)].');
    fclose(out);
end
