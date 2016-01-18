#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
if [ "${SCRIPT_DIR:0:1}" == "." ]; then
  SCRIPT_DIR=`pwd`/$SCRIPT_DIR
fi

ROOT_DIR=$(dirname $SCRIPT_DIR)

function capitalizeWords {
   givenWord=$1
   spacer=$2
   modifiedWord=""
   for word in  `echo $givenWord | sed -e 's/-/ /g;s/_/ /g;'`
   do
     upperWord=`echo ${word:0:1} | tr  '[a-z]' '[A-Z]'`${word:1}
     modifiedWord=${modifiedWord}${upperWord}${spacer}
   done
   echo $modifiedWord | sed 's/ *$//'
}

function lowerCaseWithUnderscore {
   givenWord=$1
   echo  ${givenWord} | tr '[A-Z]' '[a-z]' | sed -e 's/-/_/g'
}

function lowerCaseWithDash {
   givenWord=$1
   echo  ${givenWord} | tr '[A-Z]' '[a-z]' | sed -e 's/_/-/g'
}

function modifyPatternInPackageFiles {
  targetDir=$1
  templatePattern=$2
  packageName=$(lowerCaseWithUnderscore $3)

  for fileName in ` grep -lr ${templatePattern} $targetDir/packages/* ` 
  do
     sed -i.bak "s/${templatePattern}/${packageName}/g" $fileName
  done
}

function modifyPatternInAppFiles {
  targetDir=$1
  templatePattern=$2
  templateJobPattern=$(lowerCaseWithDash $templatePattern)
  appName=$(lowerCaseWithUnderscore $3)
  jobAppName=$(lowerCaseWithDash $appName)

  for fileName in ` grep -lr ${templatePattern} $targetdir/jobs/deploy-$jobAppName $targetdir/jobs/delete-$jobAppName ` 
  do
     sed -i.bak "s/${templatePattern}/${appName}/g" $fileName
     sed -i.bak "s/${templateJobPattern}/${jobAppName}/g" $fileName
  done
  modifyPatternInPackageFiles $targetDir generic_package $3
}

function modifyPatternInBrokerFiles {
  targetDir=$1
  templatePattern=$2
  templateJobPattern=$(lowerCaseWithDash $templatePattern)
  name=$(lowerCaseWithUnderscore $3)
  jobName=$(lowerCaseWithDash $3)

  #sed -i.bak "s/name: register-${templatePattern}/name: register-${jobAppName}/g" jobs/register-${jobAppName}-broker/spec
  #sed -i.bak "s/name: destroy-${templatePattern}/name: destroy-${jobAppName}/g" jobs/destroy-${jobAppName}-broker/spec

  for fileName in ` grep -lr $templatePattern $targetdir/jobs/*${jobName}-broker ` 
  do
     sed -i.bak "s/${templatePattern}/${name}/g" $fileName
     sed -i.bak "s/${templateJobPattern}/${jobName}/g" $fileName
  done
}

