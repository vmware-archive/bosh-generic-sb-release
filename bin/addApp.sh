#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

#echo $ROOT_DIR

function copyJobsAndPackages {
  targetDir=$1
  templatePattern=$1
  appName=$3
  isApp=$4
  isBroker=$5

  jobAppName=$(lowerCaseWithDash $appName)
  packageAppName=$(lowerCaseWithUnderscore $appName)
  
  if [ "$isApp" == "true" ]; then
    mkdir -p $targetDir/jobs/deploy-$jobAppName $targetDir/jobs/delete-$jobAppName $targetDir/packages/$packageAppName
    touch $targetDir/jobs/deploy-$jobAppName/monit $targetDir/jobs/delete-$jobAppName/monit
    cp -r $ROOT_DIR/templates/packages/generic_package/* $targetDir/packages/$packageAppName
    cp -r $ROOT_DIR/templates/jobs/deploy-generic-app/* $targetDir/jobs/deploy-$jobAppName
    cp -r $ROOT_DIR/templates/jobs/delete-generic-app/* $targetDir/jobs/delete-$jobAppName
    modifyPatternInAppFiles $targetDir generic_app $appName
  fi

  if [ "$isBroker" == "true" ]; then
    mkdir -p $targetDir/jobs/register-${jobAppName}-broker $targetDir/jobs/destroy-${jobAppName}-broker 
    touch $targetDir/jobs/*${jobAppName}-broker/monit 
    cp -r $ROOT_DIR/templates/jobs/register-broker/* $targetDir/jobs/register-${jobAppName}-broker
    cp -r $ROOT_DIR/templates/jobs/destroy-broker/* $targetDir/jobs/destroy-${jobAppName}-broker
    modifyPatternInBrokerFiles $targetDir generic_app $appName
  fi
}

function usage {
  echo "Replace and rename files from GENERIC_APP to user provided name for the release"
  echo ""
  echo "Needs 4 arguments: TargetDir NameOfApp  IsApp IsBroker"
  echo "   Sample: ./createApp.sh test-directory spring-cloud true true"
  echo "Ensure the new app name without white space (use '-' as separator if needed) "
  exit -1
}


if [ "$#" -ne 4 ]; then
  usage
fi

# Changing Project name from generic* to user provided input
TARGET_DIR=$(getAbsolutePath $1)
TEMPLATE_PATTERN=generic_app
NEW_PATTERN=`echo $2 | tr '[A-]' '[a-z]' | sed -e 's/-/_/g' `
IS_APP=$3
IS_BROKER=$4

copyJobsAndPackages $TARGET_DIR $TEMPLATE_PATTERN $NEW_PATTERN $IS_APP $IS_BROKER

find . -name "*.bak" 2>/dev/null | xargs rm

