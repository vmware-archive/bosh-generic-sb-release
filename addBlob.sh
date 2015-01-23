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

givenBlobFile=$1

# The path to the file can have other directories
# Trim the directories
blobFile=`echo $givenBlobFile | awk  -F '/' '{print $NF } '`
blobPath=$2

bosh -n add blob $givenBlobFile $blobPath
bosh -n upload blobs

echo "Is this blob the actual app binary? Respond with y or n:"
read response

if [ "$response" == "y" ]; then
  app_prefix_name=`echo $blobFile | awk -F . '{ print $1}' `
  app_extn=`echo $blobFile  | awk -F . '{ print $NF}' `
  sed -i.bak "s/TEMPLATE_APP_PREFIX_NAME/${app_prefix_name}/g; s/TEMPLATE_APP_EXTENSION/${app_extn}/g" jobs/deploy-service-broker/templates/deploy.sh.erb
  echo "Modified the jobs/deploy-service-broker/templates/deloy.sh.erb to refer to the correct app archive or file"

  sed -i.bak "s/TEMPLATE_APP_BLOB_PATH/${blobPath}/g; s/TEMPLATE_APP_BLOB_FILE/${blobFile}/g" packages/*_service_broker/*
  echo "Modified the packages/*_service_broker/spec and the packaging file to refer to the correct app blob bits"

  find jobs/deploy-service-broker -name "*.bak" | xargs rm 
  find packages/*_service_broker -name "*.bak" | xargs rm 
fi

echo ""
