#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh
set -xv
function copyJobsAndPackages {
  targetDir=$1
  templatePattern=$2
  bpName=$3

  jobBPName=$(lowerCaseWithDash $bpName)
  packageBPName=$(lowerCaseWithUnderscore $bpName)
  
  mkdir -p $targetDir/jobs/deploy-$jobBPName $targetDir/jobs/delete-$jobBPName $targetDir/packages/$packageBPName
  cp -r $ROOT_DIR/templates/packages/generic_package/* $targetDir/packages/$packageBPName
  cp -r $ROOT_DIR/templates/jobs/deploy-buildpack/* $targetDir/jobs/deploy-$jobBPName
  cp -r $ROOT_DIR/templates/jobs/delete-buildpack/* $targetDir/jobs/delete-$jobBPName
  modifyPatternInAppFiles $targetDir generic_buildpack $bpName
}

function usage {
  echo "Replace and rename files from generic_buildpack to user provided name for the release"
  echo ""
  echo "Needs an arguments: Name of bp"
  echo "   Sample: ./addBuildpack.sh target-dir custom-java-buildpack"
  echo "Ensure the new bp name without white space (use '-' as separator if needed) "
  exit -1
}


if [ "$#" -ne 2 ]; then
  usage
fi

# Changing Project name from generic* to user provided input
TARGET_DIR=$1
TEMPLATE_PATTERN=generic_buildpack
#NEW_PATTERN=`echo $1 | tr '[A-]' '[a-z]' | sed -e 's/-/_/g' `
NEW_PATTERN=$2

copyJobsAndPackages $TARGET_DIR $TEMPLATE_PATTERN $NEW_PATTERN

find . -name "*.bak" 2>/dev/null | xargs rm

