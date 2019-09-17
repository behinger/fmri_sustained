#!/bin/bash
set -e
# Align mean functional image to 3T nu anatomy (used for retinotopy) and calculate inverse XFM to be used to transform ROIs to mean functional space.
_tmp=${subjectlist:='S10'}
_tmp=${datadir:='SubjectData'}


for SID in $subjectlist
do

cd $datadir/derivates/preprocessing/$SID/ses-01/func/

# FAST correct mean func
echo 'Fast correcting functional image...'
# -t 2 => T2 weighted
# -n 2 => two tissue types (three are grey matter, white matter & csf, 2 I think brain vs csf)
# -H 0.1 => default value (something with initial segmentation?)
# -I 4 => default value (number of iterations during bias field removal)
# -l 20 => default value (smoothing in mm)
# --nopve (no partial volume estimation)
# -B output bias corrected image
#
# This is run to get the bias correct image (I imagine)
                                                                                                                  
TASK='sustained'
    
fast -t 2 -n 2 -H 0.1 -I 4 -l 20.0 --nopve -B -o './'$SID'_ses-01_task-'$TASK'_desc-occipitalcropMeanBias_bold.nii' './'$SID'_ses-01_task-'$TASK'_desc-occipitalcropMean_bold.nii' 
mv './'$SID'_ses-01_task-'$TASK'_desc-occipitalcropMeanBias_bold_restore.nii.gz' './'$SID'_ses-01_task-'$TASK'_desc-occipitalcropMeanBias_bold.nii.gz'
gunzip './'$SID'_ses-01_task-'$TASK'_desc-occipitalcropMeanBias_bold.nii.gz'
rm './'$SID'_ses-01_task-'$TASK'_desc-occipitalcropMeanBias_bold*.nii.gz'
done