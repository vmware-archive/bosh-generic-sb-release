#!/bin/sh


# Use '_' for release and deployment names as ruby can trip on '-'
TARGET_PLATFORM=warden
#TARGET_PLATFORM=vsphere
RELEASE_NAME=generic_broker
DEPLOYMENT_NAME=generic-broker-${TARGET_PLATFORM}

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

bosh -n deploy
echo "Done deploying ..."


