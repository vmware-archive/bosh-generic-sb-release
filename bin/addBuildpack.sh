#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

function copyJobsAndPackages {
  templatePattern=$1
  targetDir=$2
  bpName=$3

  jobBPName=$(lowerCaseWithDash $bpName)
  packageBPName=$(lowerCaseWithUnderscore $bpName)
  
  mkdir -p $targetDir/jobs/deploy-$jobBPName jobs/delete-$jobBPName packages/$packageBPName
  cp -r $ROOT_DIR/templates/packages/generic_package/* $targetDir/packages/$packageBPName
  cp -r $ROOT_DIR/templates/jobs/deploy-buildpack/* $targetDir/jobs/deploy-$jobBPName
  cp -r $ROOT_DIR/templates/jobs/delete-buildpack/* $targetDir/jobs/delete-$jobBPName
  modifyPatternInAppFiles $targetDir generic_buildpack $bpName
}

function usage {
  echo "Replace and rename files from generic_buildpack to user provided name for the release"
  echo ""
  echo "Needs an arguments: Name of bp"
  echo "   Sample: ./addBuildpack.sh custom-java-buildpack"
  echo "Ensure the new bp name without white space (use '-' as separator if needed) "
  exit -1
}


if [ "$#" -ne 1 ]; then
  usage
fi

# Changing Project name from generic* to user provided input
TEMPLATE_PATTERN=generic_buildpack
#NEW_PATTERN=`echo $1 | tr '[A-]' '[a-z]' | sed -e 's/-/_/g' `
TARGET_DIR=$1
NEW_PATTERN=$2

copyJobsAndPackages $TEMPLATE_PATTERN $TARGET_DIR $NEW_PATTERN

find . -name "*.bak" 2>/dev/null | xargs rm

