#!/bin/bash

# Run FEAT for working memory runs on cluster. IMPORTANT first ensure design file in subject directory is updated with subject specific information!
set -e # quit if error
_tmp=${SID:='S10'}
_tmp=${runNum:='0'}
_tmp=${runlist:='1 2 3 4'}

_tmp=${datadir:='SubjectData'}
_tmp=${designfile:='sustain_preprocessing'}


echo $runNum


cd $datadir'/derivates/FSL/'$SID'/ses-01/'

# make a copy of the generic design file
cp $datadir/config/FSL/sustained/* ./

# change the paths in the file


funcdir=$datadir'/derivates/preprocessing/'$SID'/ses-01/func/'$SID'_ses-01_task-sustained'
featdir=$datadir'/derivates/FSL/'$SID'/ses-01/'

echo $funcdir
echo $featdir
# in case of single trial preprocessing
echo 'outputdir'
sed -i -e 's,OUTPUTDIR,'"$featdir"'task-sustained_run-'"$runNum"',' $designfile.fsf


echo 'fmrifile'          
sed -i -e 's,FMRIFILE,'"$funcdir"'_run-'"$runNum"'_desc-occipitalcropRealign_bold.nii,' $designfile.fsf

echo 'meanrun'          
sed -i -e 's,MEANRUN,'"$funcdir"'_desc-occipitalcropMean_bold.nii,' $designfile.fsf

echo 'run1-4'          
# in case of combination of runs
echo $runlist
runlist=(${runlist}) # convert to array
sed -i -e 's,FEATRUN1,'"$featdir"'task-sustained_run-'"${runlist[0]}"'.feat,' $designfile.fsf
sed -i -e 's,FEATRUN2,'"$featdir"'task-sustained_run-'"${runlist[1]}"'.feat,' $designfile.fsf
sed -i -e 's,FEATRUN3,'"$featdir"'task-sustained_run-'"${runlist[2]}"'.feat,' $designfile.fsf
sed -i -e 's,FEATRUN4,'"$featdir"'task-sustained_run-'"${runlist[3]}"'.feat,' $designfile.fsf

echo 'eventfiles'          
sed -i -e 's,DIFFEVENTFILE,'"$featdir"'/events/'"$SID"'_ses-01_task-sustained_desc-differentStimuli_run-'"$runNum"'.txt,' $designfile.fsf
sed -i -e 's,SAMEEVENTFILE,'"$featdir"'/events/'"$SID"'_ses-01_task-sustained_desc-sameStimuli_run-'"$runNum"'.txt,' $designfile.fsf


echo 'starting feat'

feat $designfile.fsf #Run feat for each run

echo 'done'