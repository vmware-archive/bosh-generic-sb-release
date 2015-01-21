#!/bin/sh

# Changing Project name from generic* to $1
OLD_PATTERN=$1
NEW_PATTERN=$2

# Save a backup before renaming/replacing...
curDate=`date +'%H.%M-%m.%d.%Y' `
zip -r backup_$curDate.zip jobs packages src *sh config *yml 

for fileName in `find . -name "${OLD_PATTERN}*" | tail -r`
do
  newFileName=`echo $fileName | sed -e "s/$OLD_PATTERN/$NEW_PATTERN/g" ` 
  mv $fileName $newFileName
done


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
     sed -i.bak "s/${OLD_PATTERN}/${NEW_PATTERN}/g" $fileName
    ;;
  esac
done
