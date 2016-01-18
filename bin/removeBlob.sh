#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

function usage {
  echo "Error!! needs 1 argument: <Name of Blob file> "
  echo ""
  echo "Example: ./removeBlob.sh my-app.jar"
  echo "This would remove all references to the 'my-app.jar' from 'blobs/app.jar', 'config/blobs.yml' and .blobs folder "
  echo ""
}

if [ "$#" -lt 1 ]; then
  usage
  exit -1
fi

blobFileName=$1

shaFileId=`grep -A2 $blobFileName config/blobs.yml | grep sha  | awk '{print $2}' `
if [ "$shaFileId" != "" ]; then
  echo "Deleting the blob entry: $blobFileName, cancel to stop"
  sleep 5
  rm .blobs/$shaFileId
  find blobs -name $blobFileName | xargs rm 
  sed -i.bak "/$blobFileName/,/size: / { d; }" config/blobs.yml
  rm config/blobs.yml.bak

  specFile=`grep -l $blobFileName packages/*/spec ` 
  sed -i.bak "/$blobFileName/ { d; }" $specFile 
fi

# The previous edit might leave the blobs.yml incomplete with just '---' without the '{}'
# Recreate a pristine blobs.yml that has '--- {}'
numberOfLines=`cat config/blobs.yml | wc -l | awk '{print $1}' `
if [ "$numberOfLines" == "1" ]; then
  echo "--- {}" > config/blobs.yml
fi
