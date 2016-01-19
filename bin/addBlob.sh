#!/bin/ksh


SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/utils.sh

function usage {
  echo "Error!! Needs minimum of 3 arguments: <targetDir> <Absolute Path to a Blob file> <BlobPackageName> "
  echo "        Can be max of 4 arguments: <targetDir> <Absolute Path to a Blob file> <BlobPackageName> <App Name>"
  echo ""
  echo "Example: addBlob.sh test-release-dir my-generic-app.jar my-app-java-blob"
  echo "This would add the 'my-generic-app.jar' as blob under 'test-release-dir/blobs/my-app-java-blob'"
  echo ""
  echo "A third argument denoting a job can be specified if the blob is related to a job"
  echo "Example: ./addBlob.sh test-release-dir my-generic-app.jar my-app-java-blob my-app "
  echo "This would add the 'my-generic-app.jar' as blob under 'test-release-dir/blobs/my-app-java-blob' "
  echo  " and update its related 'my-app' package folder to refer to this blob"
  echo ""
}

if [ "$#" -lt 3 ]; then
  usage
  exit -1
fi

targetDir=$(getAbsolutePath $1)
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

if [[ ! -z "$4" ]]; then 
  appName=$4
  packageName=$(lowerCaseWithUnderscore $appName )
  jobName=$(lowerCaseWithDash $appName )

  PACKAGE_SPEC_FILE=`echo packages/$packageName/spec`
  blobExists=`grep "$blobPath/$blobFile" $PACKAGE_SPEC_FILE | awk '{print $NF}' `
  if [ "$blobExists" == "" ]; then
    echo "- ${blobPath}/${blobFile}" >> $PACKAGE_SPEC_FILE
  fi

  app_prefix_name=`echo $blobFile | awk -F . '{ print $1}' `
  app_extn=`echo $blobFile  | awk -F . '{ print $NF}' `

  if [ "$blobPath" != "cf_cli" ]; then
    templateNeedsModification=`grep TEMPLATE_APP jobs/deploy-${jobName}/templates/deploy.sh.erb > /dev/null; echo $?`
    if [ "$templateNeedsModification" == "0" ]; then
      sed -i.bak "s/TEMPLATE_APP_FILE/${blobFile}/g" jobs/deploy-${jobName}/templates/deploy.sh.erb 2>/dev/null
      echo "Modified the $targetDir/jobs/deploy-${jobName}r/templates/deloy.sh.erb to refer to the correct app archive or file"
      echo ""
    fi

    packagingNeedsModification=`grep TEMPLATE_APP packages/$packageName/packaging > /dev/null; echo $?`
    if [ "$packagingNeedsModification" == "0" ]; then
      sed -i.bak "s/TEMPLATE_APP_BLOB_PATH/${blobPath}/g; s/TEMPLATE_APP_BLOB_FILE/${blobFile}/g" packages/$packageName/packaging 2>/dev/null
      echo "Modified the packages/$packageName/packaging file to refer to the correct app blob bits"
      echo ""
    else
      echo "Could not modify the packages/$packageName/packaging file to refer to the correct app blob file/path!!"
      echo "Verify $blobPath/$blobFile is specified inside the $targetDir/packages/$packageName/packaging file"
      echo ""
    fi
  fi

  find jobs/deploy-$jobName -name "*.bak" 2>/dev/null | xargs rm  
  find packages/$packageName -name "*.bak"  2>/dev/null | xargs rm  

fi


echo ""
