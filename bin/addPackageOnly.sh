#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

function copyPackages {
  targetDir=$1
  packageName=$(lowerCaseWithUnderscore $2)
  appName=$3
  templatePattern=cf_cli

  jobAppName=$(lowerCaseWithDash $appName)

  mkdir -p $targetDir/packages/$packageName
  cp -r $ROOT_DIR/templates/packages/generic_package/* $targetDir/packages/$packageName
  sed -i.bak "s/generic_package/${packageName}/g" $targetDir/packages/$packageName/*

  # Sed does not work correctly when it comes to adding newline for some reason on Mac
  sed -i.bak "s/- cf_cli/&\\
- ${packageName}/g"  $targetDir/jobs/deploy-*${jobAppName}*/spec 
  #awk "/- cf_cli/{print; print \"- ${packageName}\"; next}1"  $targetDir/jobs/deploy-*${jobAppName}*/spec > $targetDir/jobs/deploy-$jobAppName/spec.new
  #mv $targetDir/jobs/deploy-$jobAppName/spec.new $targetDir/jobs/deploy-$jobAppName/spec

}

function usage {
  echo "Add new package to a job"
  echo ""
  echo "Needs an arguments: TargetDir, Name of Package & Name of Application "
  echo "   Sample: ./addPackage.sh target-test spring-cloud-depedency-package spring-cloud"
  echo "Ensure the new app name without white space (use '-' as separator if needed) "
  echo "The Application should be having an associated deploy-<AppName> job"
  exit -1
}


if [ "$#" -ne 3 ]; then
  usage
fi

# Changing Project name from generic* to user provided input
PACKAGE_NAME=`echo $1 | tr '[A-]' '[a-z]' | sed -e 's/-/_/g' `
APP_NAME=`echo $2 | tr '[A-]' '[a-z]' | sed -e 's/_/-/g' `

copyPackages $TARGET_DIR $PACKAGE_NAME $APP_NAME

find . -name "*.bak" 2>/dev/null | xargs rm

