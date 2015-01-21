#!/bin/sh

function usage() {
  echo "Error!! Needs 2 arguments: <Path to Blob file> <Directory or folder under ./blobs to save it>"
  echo ""
  echo "Example: ./addBlob.sh my-service-broker.jar generic-service-broker "
  echo "This would add the 'my-service-broker.jar' as blob under 'blobs/generic-service-broker' "
  echo ""
}

if [ "$#" -lt 2 ]; then
  usage
  exit -1
fi

blobFile=$1
blobPath=$2

bosh add blob $blobFile $blobPath
