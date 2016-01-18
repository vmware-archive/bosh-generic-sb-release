#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

function copyJobsAndPackages {
  templatePattern=$1
  appName=$2
  isApp=$3
  isBroker=$4

  jobAppName=$(lowerCaseWithDash $appName)
  packageAppName=$(lowerCaseWithUnderscore $appName)
  
  if [ "$isApp" == "true" ]; then
    mkdir -p jobs/deploy-$jobAppName jobs/delete-$jobAppName packages/$packageAppName
    touch jobs/deploy-$jobAppName/monit jobs/delete-$jobAppName/monit
    cp -r templates/packages/generic_package/* packages/$packageAppName
    cp -r templates/jobs/deploy-generic-app/* jobs/deploy-$jobAppName
    cp -r templates/jobs/delete-generic-app/* jobs/delete-$jobAppName
    modifyPatternInAppFiles generic_app $appName
  fi

  if [ "$isBroker" == "true" ]; then
    cp -r templates/jobs/register-broker jobs/register-${jobAppName}-broker
    cp -r templates/jobs/destroy-broker jobs/destroy-${jobAppName}-broker
    modifyPatternInBrokerFiles generic_broker $appName
  fi
}

function usage {
  echo "Replace and rename files from GENERIC_APP to user provided name for the release"
  echo ""
  echo "Needs an arguments: Name of App"
  echo "Old name getting replaced defaults to 'generic'"
  echo "   Sample: ./createApp.sh spring-cloud"
  echo "Ensure the new app name without white space (use '-' as separator if needed) "
  exit -1
}


if [ "$#" -ne 3 ]; then
  usage
fi

# Changing Project name from generic* to user provided input
TEMPLATE_PATTERN=generic_app
NEW_PATTERN=`echo $1 | tr '[A-]' '[a-z]' | sed -e 's/-/_/g' `
IS_APP=$2
IS_BROKER=$3

copyJobsAndPackages $TEMPLATE_PATTERN $NEW_PATTERN $IS_APP $IS_BROKER

find . -name "*.bak" 2>/dev/null | xargs rm

