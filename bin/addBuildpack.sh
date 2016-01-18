#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

function copyJobsAndPackages {
  templatePattern=$1
  bpName=$2

  jobBPName=$(lowerCaseWithDash $bpName)
  packageBPName=$(lowerCaseWithUnderscore $bpName)
  
  mkdir -p jobs/deploy-$jobBPName jobs/delete-$jobBPName packages/$packageBPName
  cp -r templates/packages/generic_package/* packages/$packageBPName
  cp -r templates/jobs/deploy-buildpack/* jobs/deploy-$jobBPName
  cp -r templates/jobs/delete-buildpack/* jobs/delete-$jobBPName
  modifyPatternInAppFiles generic_buildpack $bpName
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
NEW_PATTERN=$1

copyJobsAndPackages $TEMPLATE_PATTERN $NEW_PATTERN

find . -name "*.bak" 2>/dev/null | xargs rm

