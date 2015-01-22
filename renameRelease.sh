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
  echo "Needs 2 arguments: old-pattern to be replaced with new pattern (old pattern expected to be 'generic')"
  echo "   Sample: ./renameRelease.sh generic spring-cloud"
  echo "Ensure the patterns are provided without white space in between them (use '-' as separator if needed) "
  exit -1
}


if [ "$#" -ne 2 ]; then
  usage
fi

# Changing Project name from generic* to user provided input
OLD_PATTERN=$1
NEW_PATTERN=$2
NEW_PATTERN_WITH_UNDERSCORE=`echo $2 | sed -e 's/-/_/g' `

# Generate app name with captialized first character and without any spaces
# spring_cloud would appear as SpringCloud
OLD_APP_NAME=$(capitalizeWords $OLD_PATTERN '') # Without spaces
NEW_APP_NAME=$(capitalizeWords $NEW_PATTERN '') # Without spaces

# Generate app descrp with captialized first character and with spaces
# spring-cloud would appear as Spring Cloud
OLD_APP_DESCRP=$(capitalizeWords $OLD_PATTERN ' ') # With spaces
NEW_APP_DESCRP=$(capitalizeWords $NEW_PATTERN ' ') # With spaces

echo "Application deployed to CF would be named   : ${NEW_APP_NAME}ServiceBroker"
echo "Application descrp inside the Tile would be : ${NEW_APP_DESCRP} Service Broker "

# Save a backup before renaming/replacing...
curDate=`date +'%H.%M-%m.%d.%Y' `
zip -r backup-$curDate.zip jobs packages src *sh config *yml 

for fileName in `find . -name "${OLD_PATTERN}*" | tail -r`
do
  newFileName=`echo $fileName | sed -e "s/$OLD_PATTERN/$NEW_PATTERN/g" ` 
  mv $fileName $newFileName
done

# For file contents, use underscore '_', rather than minus '-' as this can break with ruby erb files
for fileName in ` grep -lr ${OLD_PATTERN} * ` 
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
     sed -i.bak "s/${OLD_PATTERN}/${NEW_PATTERN_WITH_UNDERSCORE}/g" $fileName
    ;;
  esac
done

# If its a single word thats being replaced, check to see if there is space next to it and in those cases, use the descrp format (like 'Spring Cloud')
# If no space, then use the name (without spaces like 'SpringCloud')
sed -i.bak "s/${OLD_APP_DESCRP} /${NEW_APP_DESCRP} /g" *.yml *.sh
sed -i.bak "s/${OLD_APP_NAME}/${NEW_APP_NAME}/g" *.yml *.sh

find . -name "*.bak" | xargs rm

