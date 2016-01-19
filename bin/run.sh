#!/bin/ksh


# Use '_' for release and deployment names as ruby can trip on '-'
TARGET_PLATFORM=warden
#TARGET_PLATFORM=vsphere
RELEASE_NAME=generic_broker
DEPLOYMENT_NAME=generic-broker-${TARGET_PLATFORM}

targetDir=$1
cd $targetDir
echo "Running against bosh target platform $TARGET_PLATFORM"
echo "Please create the manifest using ./make_manifest.sh <platform> before proceeding with full deploy"
echo "Edit the templates/*properties.yml file to tweak any deployment attributes"
sleep 2

bosh_target=`bosh target`
echo "Bosh Status"
bosh status

DEPLOYMENT_MANIFEST=`pwd`/*broker-${TARGET_PLATFORM}-manifest.yml
bosh deployment $DEPLOYMENT_MANIFEST

# Cleanup existing deployment and release
bosh -n delete deployment  $DEPLOYMENT_NAME
bosh -n delete release  $RELEASE_NAME
echo "Done cleaning up the release and deployment ..."

./createRelease.sh
echo "Done creating the release ..."

bosh -n upload release; 
echo "Done uploading the release ..."

echo "Going to deploy against bosh target: $bosh_target ..."
bosh -n deploy
echo "Done deploying ..."

