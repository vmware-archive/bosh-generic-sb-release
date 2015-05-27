#!/bin/sh

TILE_NAME=Generic-Broker-Experimental
TILE_VERSION=OPS_MGR_VERSION
TILE_FILE=`pwd`/*tile-${TILE_VERSION}.yml
RELEASE_TARFILE=`pwd`/releases/*/*.tgz
BOSH_STEMCELL_FILE=`cat ${TILE_FILE} | grep "bosh-stemcell" | grep "^ *file:" | awk '{print $2}' `
BOSH_STEMCELL_LOCATION=https://s3.amazonaws.com/bosh-jenkins-artifacts/bosh-stemcell/vsphere

mkdir -p tmp
pushd tmp
#Dont bundle the stemcell into the .pivotal Tile file as the stemcell must already be available in the Ops Mgr.
mkdir -p metadata releases #stemcells
cp $TILE_FILE metadata
cp $RELEASE_TARFILE releases
#if [ ! -e "stemcells/$BOSH_STEMCELL_FILE" ]; then
#  curl -k $BOSH_STEMCELL_LOCATION/$BOSH_STEMCELL_FILE -o stemcells/$BOSH_STEMCELL_FILE
#fi
zip -r ${TILE_NAME}-${TILE_VERSION}.pivotal metadata releases #stemcells
mv ${TILE_NAME}-${TILE_VERSION}.pivotal ..
popd
