#!/bin/ksh

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

function usage {
  echo "Error!! Needs minimum of 2 arguments: <Absolute Path to a Blob file> <BlobPackageName> "
  echo "        Can be max of 3 arguments: <Absolute Path to a Blob file> <BlobPackageName> <App Name>"
  echo ""
  echo "Example: ./addBlob.sh my-generic-app.jar my-app-java-blob"
  echo "This would add the 'my-generic-app.jar' as blob under 'blobs/my-app-java-blob'"
  echo ""
  echo "A third argument denoting a job can be specified if the blob is related to a job"
  echo "Example: ./addBlob.sh my-generic-app.jar my-app-java-blob my-app "
  echo "This would add the 'my-generic-app.jar' as blob under 'blobs/my-app-java-blob' "
  echo  " and update its related 'my-app' package folder to refer to this blob"
  echo ""
}

if [ "$#" -lt 2 ]; then
  usage
  exit -1
fi

targetDir=$1
givenBlobFile=$2
blobPath=$3

# The path to the file can have other directories
# Trim the directories
blobFile=`echo $givenBlobFile | awk  -F '/' '{print $NF } '`
#blobPath=`echo $blobFile | awk -F . '{ print $1}' `

echo "Removing older versions of the $blobFile previously added"
$SCRIPT_DIR/removeBlob.sh $targetDir $blobFile

cd $targetDir
bosh -n add blob $givenBlobFile $blobPath
bosh -n upload blobs

if [[ ! -z "$3" ]]; then 
  appName=$3
  packageName=$(lowerCaseWithUnderscore $appName )
  jobName=$(lowerCaseWithDash $appName )

  if [ "$blobPath" != "cf_cli" ]; then
    PACKAGE_SPEC_FILE=`echo $targetDir/packages/$packageName/spec`
    blobExists=`grep "$targetDir/$blobPath/$blobFile" $PACKAGE_SPEC_FILE | awk '{print $NF}' `
    if [ "$blobExists" == "" ]; then
      echo "- ${blobPath}/${blobFile}" >> $PACKAGE_SPEC_FILE
    fi
  fi

  app_prefix_name=`echo $blobFile | awk -F . '{ print $1}' `
  app_extn=`echo $blobFile  | awk -F . '{ print $NF}' `

  templateNeedsModification=`grep TEMPLATE_APP jobs/deploy-${jobName}/templates/deploy.sh.erb > /dev/null; echo $?`
  if [ "$templateNeedsModification" == "0" ]; then
    sed -i.bak "s/TEMPLATE_APP_FILE/${blobFile}/g" $targetDir/jobs/deploy-${jobName}/templates/deploy.sh.erb 2>/dev/null
    echo "Modified the $targetDir/jobs/deploy-${jobName}r/templates/deloy.sh.erb to refer to the correct app archive or file"
    echo ""
  fi

  packagingNeedsModification=`grep TEMPLATE_APP $targetDir/packages/$packageName/packaging > /dev/null; echo $?`
  if [ "$packagingNeedsModification" == "0" ]; then
    sed -i.bak "s/TEMPLATE_APP_BLOB_PATH/${blobPath}/g; s/TEMPLATE_APP_BLOB_FILE/${blobFile}/g" $targetDir/packages/$packageName/packaging 2>/dev/null
    echo "Modified the packages/$packageName/packaging file to refer to the correct app blob bits"
    echo ""
  else
    echo "Could not modify the packages/$packageName/packaging file to refer to the correct app blob file/path!!"
    echo "Verify $blobPath/$blobFile is specified inside the $targetDir/packages/$packageName/packaging file"
    echo ""
  fi

  find $targetDir/jobs/deploy-$jobName -name "*.bak" 2>/dev/null | xargs rm  
  find $targetDir/packages/$packageName -name "*.bak"  2>/dev/null | xargs rm  

fi


echo ""
