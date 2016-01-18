#!/bin/ksh

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
  templatePattern=$1
  packageName=$(lowerCaseWithUnderscore $2)

  for fileName in ` grep -lr ${templatePattern} packages/* ` 
  do
     sed -i.bak "s/${templatePattern}/${packageName}/g" $fileName
  done
}

function modifyPatternInAppFiles {
  templatePattern=$1
  templateJobPattern=$(lowerCaseWithDash $templatePattern)
  appName=$(lowerCaseWithUnderscore $2)
  jobAppName=$(lowerCaseWithDash $appName)

  for fileName in ` grep -lr ${templatePattern} jobs/deploy-$jobAppName jobs/delete-$jobAppName ` 
  do
     sed -i.bak "s/${templatePattern}/${appName}/g" $fileName
     sed -i.bak "s/${templateJobPattern}/${jobAppName}/g" $fileName
  done
  modifyPatternInPackageFiles generic_package $2
}

function modifyPatternInBrokerFiles {
  templatePattern=generic_app
  templateJobPattern=$(lowerCaseWithDash $templatePattern)
  name=$(lowerCaseWithUnderscore $2)
  jobName=$(lowerCaseWithDash $2)

  #sed -i.bak "s/name: register-${templatePattern}/name: register-${jobAppName}/g" jobs/register-${jobAppName}-broker/spec
  #sed -i.bak "s/name: destroy-${templatePattern}/name: destroy-${jobAppName}/g" jobs/destroy-${jobAppName}-broker/spec

  for fileName in ` grep -lr $templatePattern jobs/*${jobName}-broker ` 
  do
     sed -i.bak "s/${templatePattern}/${name}/g" $fileName
     sed -i.bak "s/${templateJobPattern}/${jobName}/g" $fileName
  done
}

