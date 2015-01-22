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

bosh -n add blob $blobFile $blobPath
bosh -n upload blobs

echo "Is this blob the actual app binary? Respond with y or n:"
read response

if [ "$response" == "y" ]; then
  echo "Modifying the jobs/deploy-service-broker/templates/deloy.sh.erb to refer to the correct app archive or file"
  app_prefix_name=`echo $blobFile | awk -F . '{ print $1}' `
  app_extn=`echo $blobFile | awk -F . '{ print $NF}' `
  sed -i.bak "s/TEMPLATE_APP_PREFIX_NAME/${app_prefix_name}/g;s/TEMPLATE_APP_EXTENSION/${app_extn}/g" jobs/deploy-service-broker/templates/deploy.sh.erb

  echo "Modifying the packages/*-service-broker/spec and the packaging file to refer to the correct app blob bits"
  sed -i.bak "s/TEMPLATE_APP_BLOB_PATH/${blobPath}/g;s/TEMPLATE_APP_BLOB_FILE/${blobFile}/g" packages/*-service-broker/*

  find jobs/deploy-service-broker -name "*.bak" | xargs rm 
  find packages/*-service-broker -name "*.bak" | xargs rm 
fi
