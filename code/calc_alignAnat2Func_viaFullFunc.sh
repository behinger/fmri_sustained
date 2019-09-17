#!/bin/bash
set -e
# Align mean functional image to 3T nu anatomy (used for retinotopy) and calculate inverse XFM to be used to transform ROIs to mean functional space.
_tmp=${subjectlist:='S10'}
_tmp=${datadir:='SubjectData'}


for SID in $subjectlist
do

cd $datadir/derivates/preprocessing/$SID/ses-01/

# Align fast corrected func to cropped anat:q!
bids=$SID'_ses-01'
echo $bids
echo 'Aligning functional image to cropped anatomy...'

TASK=sustained




# This way is only possible if fullbrain 3T images are available
# croppedFunc to Func
#fslroi '../../../../'$SID'/ses-01/func/'$bids'_task-localizer_run-1.nii' './func/'$bids'_task-wholebrain_run-1_desc-firstVolumeOnly.nii.gz' 0 1
fslroi '../../../../'$SID'/ses-01/func/sub-01_ses-01_task-restingstatewholebrain4x2flipang20_run-1_echo-1_bold.nii' './func/'$bids'_task-wholebrain_run-1_desc-firstVolumeOnly.nii.gz' 0 1

flirt -in './func/'$bids'_task-'$TASK'_desc-occipitalcropMeanBias_bold.nii' -ref 'func/'$bids'_task-wholebrain_run-1_desc-firstVolumeOnly.nii.gz' -omat './coreg/'$bids'_from-FUNCCROPPED_to-FUNC.mat' -out './func/'$bids'_task-'$TASK'_desc-occipitalcropMeanBias_space-FUNC_bold.nii' -bins 600 -cost leastsq  -dof 6 -interp trilinear -searchrx -10 10 -searchry -10 10 -searchrz -10 10
gunzip -f './func/'$bids'_task-'$TASK'_desc-occipitalcropMeanBias_space-FUNC_bold.nii.gz'

# func to Anat
flirt -in 'func/'$bids'_task-wholebrain_run-1_desc-firstVolumeOnly.nii.gz' -ref './anat/'$bids'_desc-anatomical_T1w.nii' -omat './coreg/'$bids'_from-FUNC_to-ANAT.mat' -out 'func/'$bids'_task-wholebrain_run-1_desc-firstVolumeOnly_space-ANAT.nii.gz' -bins 600 -cost mutualinfo  -dof 6 -interp trilinear
gunzip -f 'func/'$bids'_task-wholebrain_run-1_desc-firstVolumeOnly_space-ANAT.nii.gz'

convert_xfm -omat './coreg/'$bids'_from-FUNC_to-FUNCCROPPED.mat'  -inverse './coreg/'$bids'_from-FUNCCROPPED_to-FUNC.mat'



# croppedFunc to Anat
# convert_xfm -omat './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat' -concat './coreg/'$bids'_from-FUNC_to-FUNCCROPPED.mat' './coreg/'$bids'_from-ANAT_to-FUNC.mat'
convert_xfm -omat './coreg/'$bids'_from-FUNCCROPPED_to-ANAT.mat' -concat './coreg/'$bids'_from-FUNC_to-ANAT.mat' './coreg/'$bids'_from-FUNCCROPPED_to-FUNC.mat'

# Anat to CroppedFunc
convert_xfm -omat './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat'  -inverse './coreg/'$bids'_from-FUNCCROPPED_to-ANAT.mat'


echo 'Mapping Anat to Cropped Func'
flirt -in './anat/'$bids'_desc-anatomical_T1w.nii' -init './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat' \
-ref './func/'$bids'_task-'$TASK'_desc-occipitalcropMeanBias_bold.nii' -out './anat/'$bids'_desc-anatomical_space-FUNCCROPPED_T1w.nii' -applyxfm

gunzip -f './anat/'$bids'_desc-anatomical_space-FUNCCROPPED_T1w.nii.gz'

done
echo 'Done!'
