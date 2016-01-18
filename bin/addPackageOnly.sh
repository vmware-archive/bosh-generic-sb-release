#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

function copyPackages {
  templatePattern=cf_cli
  packageName=$(lowerCaseWithUnderscore $1)
  appName=$2

  jobAppName=$(lowerCaseWithDash $appName)
  
  mkdir -p packages/$packageName
  cp -r templates/packages/generic_package/* packages/$packageName
  sed -i.bak "s/generic_package/${packageName}/g" packages/$packageName/*

  # Sed does not work correctly when it comes to adding newline for some reason on Mac
  sed -i.bak "s/- cf_cli/&\\
- ${packageName}/g"  jobs/deploy-*${jobAppName}*/spec 
  #awk "/- cf_cli/{print; print \"- ${packageName}\"; next}1"  jobs/deploy-*${jobAppName}*/spec > jobs/deploy-$jobAppName/spec.new
  #mv jobs/deploy-$jobAppName/spec.new jobs/deploy-$jobAppName/spec

}

function usage {
  echo "Add new package to a job"
  echo ""
  echo "Needs an arguments: Name of Package & Name of Application "
  echo "   Sample: ./addPackage.sh spring-cloud-depedency-package spring-cloud"
  echo "Ensure the new app name without white space (use '-' as separator if needed) "
  echo "The Application should be having an associated deploy-<AppName> job"
  exit -1
}


if [ "$#" -ne 2 ]; then
  usage
fi

# Changing Project name from generic* to user provided input
PACKAGE_NAME=`echo $1 | tr '[A-]' '[a-z]' | sed -e 's/-/_/g' `
APP_NAME=`echo $2 | tr '[A-]' '[a-z]' | sed -e 's/_/-/g' `

copyPackages $PACKAGE_NAME $APP_NAME

find . -name "*.bak" 2>/dev/null | xargs rm

