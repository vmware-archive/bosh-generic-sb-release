#!/bin/sh

function capitalizeWords {
   givenWord=$1
   spacer=$2
   modifiedWord=""
   for word in  `echo $givenWord | sed -e 's/-/ /g;s/_/ /g;'`
   do
     upperWord=`echo ${word:0:1} | tr  '[a-z]' '[A-Z]'`${word:1}
     modifiedWord=${modifiedWord}${upperWord}${spacer}
   done
   echo $modifiedWord | sed 's/ *$//'
}

function usage {
  echo "Replace and rename files from generic* to user provided name for the release"
  echo ""
  echo "Needs an arguments: New name of release"
  echo "Old name getting replaced defaults to 'generic'"
  echo "   Sample: ./renameRelease.sh spring-cloud"
  echo "Ensure the new release name without white space (use '-' as separator if needed) "
  exit -1
}


if [ "$#" -ne 1 ]; then
  usage
fi

# Changing Project name from generic* to user provided input
OLD_RELEASE=generic
NEW_RELEASE=`echo $1 | sed -e 's/-/_/g' `
NEW_RELEASE_WITH_DASH=`echo $1 | sed -e 's/_/-/g' `

# Generate app name with captialized first character and without any spaces
# spring_cloud would appear as SpringCloud
OLD_APP_NAME=$(capitalizeWords $OLD_RELEASE '') # Without spaces
NEW_APP_NAME=$(capitalizeWords $NEW_RELEASE '') # Without spaces

# Generate app descrp with captialized first character and with spaces
# spring-cloud would appear as Spring Cloud
OLD_APP_DESCRP=$(capitalizeWords $OLD_RELEASE ' ') # With spaces
NEW_APP_DESCRP=$(capitalizeWords $NEW_RELEASE ' ') # With spaces

echo "Application deployed to CF would be named   : ${NEW_APP_NAME}ServiceBroker"
echo "Application descrp inside the Tile would be : ${NEW_APP_DESCRP} Service Broker "

# Save a backup before renaming/replacing...
curDate=`date +'%H.%M-%m.%d.%Y' `
zip -r backup-$curDate.zip jobs packages src config templates *sh *yml make*   > /dev/null
echo "Backed up original contents as backup-$curDate.zip"

for fileName in `find . -name "${OLD_RELEASE}*" | tail -r`
do
  newFileName=`echo $fileName | sed -e "s#$OLD_RELEASE#$NEW_RELEASE#g" ` 
  mv $fileName $newFileName
done

for fileName in `find . -name "${NEW_RELEASE}*yml" | tail -r`
do
  newFileName=`echo $fileName | sed -e "s#$NEW_RELEASE#$NEW_RELEASE_WITH_DASH#g" ` 
  mv $fileName $newFileName
done

# For file contents, use underscore '_', rather than minus '-' as this can break with ruby erb files

for fileName in ` grep -lr ${OLD_RELEASE} * ` 
do
  case "$fileName" in 
    renameRelease.sh )
     continue;;
    releases* )
     continue;;
    .dev_builds* )
     continue;;
    .blobs* )
     continue;;
    *zip )
     continue;;
    *tgz )
     continue;;
    *tar )
     continue;;
    *pivotal )
     continue;;
     README.md )
     continue;;
    *class )
     continue;;
    *jpeg )
     continue;;
    * )
     sed -i.bak "s/${OLD_RELEASE}/${NEW_RELEASE}/g" $fileName
    ;;
  esac
done


# Make sure the deployment name uses dash instead of underscore - used by both run.sh and deployRelease.sh and the tile
sed -i.bak "s/DEPLOYMENT_NAME=${NEW_RELEASE}/DEPLOYMENT_NAME=${NEW_RELEASE_WITH_DASH}/g" run.sh deployRelease.sh
sed -i.bak "s/DEPLOYMENT_NAME/${NEW_RELEASE_WITH_DASH}-broker/g" *yml
sed -i.bak "s/APP_URI/${NEW_RELEASE_WITH_DASH}-broker/g" *yml

# If its a single word thats being replaced, check to see if there is space next to it and in those cases, use the descrp format (like 'Spring Cloud')
# If no space, then use the name (without spaces like 'SpringCloud')
sed -i.bak "s/${OLD_APP_DESCRP} /${NEW_APP_DESCRP} /g" *.yml *.sh  templates/*.yml
sed -i.bak "s/${OLD_APP_NAME}/${NEW_APP_NAME}/g" *.yml *.sh  templates/*.yml

# For the app_uri, make sure the endpoint does not use '_', change those to '-'
# Ruby would fail!!: 
# Request failed: 500: {\"code\"=>10001, #
# "description"=>"the scheme http does not accept registry part: test_broker.10.244.0.34.xip.io
sed -i.bak "s/app_uri: ${NEW_RELEASE}/app_uri: ${NEW_RELEASE_WITH_DASH}/g" *.yml templates/*.yml

# Have the mainfest file using dash instead of underscore
sed -i.bak "s/${NEW_RELEASE}/${NEW_RELEASE_WITH_DASH}/g" make_manifest.sh
#sed -i.bak "s/${NEW_RELEASE}/${NEW_RELEASE_WITH_DASH}/g" *.yml templates/*.yml

find . -name "*.bak" | xargs rm

