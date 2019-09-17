#!/bin/bash
set -e

_tmp=${subjectlist:='S10'}
_tmp=${datadir:='SubjectData'}

# activate venv
source $datadir/../../../venv/bin/activate



for SID in $subjectlist
do

cd $datadir/derivates/freesurfer/$SID/ses-01/


# named benson14 but is actually benson17 ...

export SUBJECTS_DIR=$datadir/derivates/freesurfer/$SID/
python3 -m neuropythy benson14_retinotopy --verbose ses-01

mkdir -p $datadir/derivates/preprocessing/$SID/ses-01/label
mri_convert -rl mri/rawavg.mgz mri/benson14_varea.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-varealabel_space-ANAT_label.nii'
mri_convert -rl mri/rawavg.mgz mri/benson14_angle.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-angle_space-ANAT_label.nii'
mri_convert -rl mri/rawavg.mgz mri/benson14_eccen.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-eccen_space-ANAT_label.nii'
mri_convert -rl mri/rawavg.mgz mri/benson14_sigma.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-sigma_space-ANAT_label.nii'

done
