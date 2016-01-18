#!/bin/ksh

# Download the latest Linux 64 bit CF CLI binary from https://github.com/cloudfoundry/cli/releases
# Edit the link as newer releases are published

SCRIPT_DIR=$(dirname $0)

CF_CLI_VERSION=6.13.0

# Remove older references to cf_cli
$SCRIPT_DIR/removeBlob.sh cf-linux-amd64.tgz 

wget "https://cli.run.pivotal.io/stable?release=linux64-binary&version=${CF_CLI_VERSION}&source=github-rel" -O cf-linux-amd64.tgz
echo no | ./$SCRIPT_DIR/addBlob.sh cf-linux-amd64.tgz cf_cli
