#!/bin/sh

# Cleanup existing deployment and release
CLEAN_UP=true

# For use to create final release tarball
CREATE_FINAL_TARBALL=true
VERSION=1.3
RELEASE_NAME=generic-sb
DEPLOYMENT_NAME=generic-sb
DEPLOYMENT_MANIFEST=`pwd`/generic-sb-boshlite.yml

if [ "$CLEAN_UP" == "true" ]; then
  bosh deployment $DEPLOYMENT_MANIFEST
  bosh -n delete deployment $DEPLOYMENT_NAME
  bosh -n delete release $RELEASE_NAME
fi

echo "Creating the release ..."
bosh create release --force; 


if [ "$CREATE_FINAL_TARBALL" == "true" ]; then
  # To create a final tarball release
  bosh -n create release --name $RELEASE_NAME --version $VERSION --with-tarball --final --force
fi

echo "Done creating the release ..."
bosh -n upload release; 
echo "Done uploading the release ..."
bosh -d $DEPLOYMENT_MANIFEST -n deploy
echo "Done deploying ..."


# Working with blobs...
# bosh add blob packages/openjdk/openjdk-1.8.0_M7.tar.gz # this will go to the root
# bosh add blob packages/openjdk/openjdk-1.8.0_M7.tar.gz openjdk  # this will go under the openjdk folder
# bosh add blob packages/oracle-service-broker/oracleservicebroker/oracle-service-broker-0.1.0.jar  oracle-service-broker
# bosh upload blobs
