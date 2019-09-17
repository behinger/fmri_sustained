#!/bin/bash
set -e
echo "starting freesurfer"
# Run freesurfer on T1
module unload freesurfer
module load freesurfer/6.0

# This allows for e.g. export subjectlist= ... previous to running the command
_tmp=${SID:='S9'}
_tmp=${datadir:='SubjectData'}


T1Path=$datadir'/derivates/preprocessing/'$SID'/ses-01/anat/'$SID'_ses-01_desc-anatomical_T1w.nii'
export SUBJECTS_DIR=$datadir/derivates/freesurfer/$SID/
# ses-01 is done in recon-all call, no Idea how to do better sorry!
mkdir -p $SUBJECTS_DIR

recon-all -i $T1Path -subjid 'ses-01' -cw256 -all -parallel -hires

