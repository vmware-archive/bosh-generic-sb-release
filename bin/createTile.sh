#!/bin/ksh

TILE_VERSION=OPS_MGR_VERSION
TILE_NAME=Generic-Tile-Experimental
TILE_FILE=`pwd`/*tile-v${TILE_VERSION}.yml
RELEASE_TARFILE=`pwd`/releases/*/*.tgz

targetDir=$1
cd $targetDir

rm -rf tmp
mkdir -p tmp
cd tmp
#Dont bundle the stemcell into the .pivotal Tile file as the stemcell must already be available in the Ops Mgr.
mkdir -p metadata releases #stemcells
cp $TILE_FILE metadata
cp $RELEASE_TARFILE releases
cp -r ../content_migrations .

# Ignore bundling the stemcell as most often the Ops Mgr carries the stemcell.
# If Ops Mgr complains of missing stemcell, change the version specified inside the tile to the one that Ops mgr knows about

#if [ ! -e "stemcells/$BOSH_STEMCELL_FILE" ]; then
#  curl -k $BOSH_STEMCELL_LOCATION/$BOSH_STEMCELL_FILE -o stemcells/$BOSH_STEMCELL_FILE
#fi
zip -r ${TILE_NAME}-${TILE_VERSION}.pivotal metadata releases content_migrations
mv ${TILE_NAME}-${TILE_VERSION}.pivotal ..
cd ..

