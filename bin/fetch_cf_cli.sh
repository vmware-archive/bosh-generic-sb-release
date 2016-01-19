#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

echo SCRIPT_DIR is $SCRIPT_DIR
echo ROOT_DIR is $ROOT_DIR

# Download the latest Linux 64 bit CF CLI binary from https://github.com/cloudfoundry/cli/releases
# Edit the link as newer releases are published

CF_CLI_VERSION=6.13.0

# Remove older references to cf_cli
targetDir=$(getAbsolutePath $1)
cd $targetDir
mkdir -p $targetDir/packages
cp -r $ROOT_DIR/templates/packages/cf_cli $targetDir/packages

wget "https://cli.run.pivotal.io/stable?release=linux64-binary&version=${CF_CLI_VERSION}&source=github-rel" -O cf-linux-amd64.tgz > /dev/null
$SCRIPT_DIR/addBlob.sh $targetDir cf-linux-amd64.tgz cf_cli cf_cli
