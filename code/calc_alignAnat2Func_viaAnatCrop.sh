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




# croppedFunc to croppedAnat
flirt -in './func/'$bids'_task-'$TASK'_desc-occipitalcropMeanBias_bold.nii' -ref './anat/'$bids'_desc-occipitalcrop_T1w.nii' -omat './coreg/'$bids'_from-FUNCCROPPED_to-ANATCROPPED.mat' -out './func/'$bids'_task-'$TASK'_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii' -bins 600 -cost corratio  -dof 6 -interp trilinear -searchrx -10 10 -searchry -10 10 -searchrz -10 10
gunzip -f './func/'$bids'_task-'$TASK'_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii.gz'

# Create inverse transform

echo 'Generating Cropped Anat to Cropped Func'
convert_xfm -omat './coreg/'$bids'_from-ANATCROPPED_to-FUNCCROPPED.mat' -inverse './coreg/'$bids'_from-FUNCCROPPED_to-ANATCROPPED.mat'

# Align cropped anatomy to original anatomy
# we can use normcorr here as it is intramodal
echo 'Aligning cropped anatomy to original anatomy...'

flirt -in './anat/'$bids'_desc-occipitalcrop_T1w.nii' -ref './anat/'$bids'_desc-anatomical_T1w.nii' \
-out './anat/'$bids'_desc-occipitalcrop_space-ANAT_T1w.nii' -omat './coreg/'$bids'_from-ANATCROPPED_to-ANAT.mat' -bins 600 -cost leastsq -dof 6 -interp trilinear -nosearch

# Create inverse transform

echo 'Generating Anat to Cropped Anat'
convert_xfm -omat './coreg/'$bids'_from-ANAT_to-ANATCROPPED.mat'  -inverse './coreg/'$bids'_from-ANATCROPPED_to-ANAT.mat'



# unzip nii.gz
gunzip -f './anat/'$bids'_desc-occipitalcrop_space-ANAT_T1w.nii.gz'

# make a link from ANAT to FUNCCROPPED
echo 'Generating Anat to Cropped Func'
convert_xfm -omat './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat' -concat './coreg/'$bids'_from-ANATCROPPED_to-FUNCCROPPED.mat' './coreg/'$bids'_from-ANAT_to-ANATCROPPED.mat'

echo 'Mapping Anat to Cropped Func'
flirt -in './anat/'$bids'_desc-anatomical_T1w.nii' -init './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat' \
-ref './func/'$bids'_task-'$TASK'_desc-occipitalcropMeanBias_bold.nii' -out './anat/'$bids'_desc-anatomical_space-FUNCCROPPED_T1w.nii' -applyxfm

gunzip -f './anat/'$bids'_desc-anatomical_space-FUNCCROPPED_T1w.nii.gz'

done
echo 'Done!'
