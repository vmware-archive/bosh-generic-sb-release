#!/bin/bash

set -e

template_prefix="generic-release"

infrastructure=$1
STEMCELL_OS=${STEMCELL_OS:-ubuntu}

if [ "$infrastructure" != "aws-ec2" ] && \
    [ "$infrastructure" != "vsphere" ] && \
#    [ "$infrastructure" != "vcloud" ] && \
    [ "$infrastructure" != "warden" ] ; then
#  echo "usage: ./make_manifest <warden|aws-ec2|vsphere|vcloud> "
  echo "usage: ./make_manifest <warden|aws-ec2|vsphere> "
  exit 1
fi

shift

echo "Should set the bosh target before proceeding!!!"
echo "Also tweak the stubs/*properties.yml to add/modify any attributes or properties before manifest generation"
echo ""

BOSH_STATUS=$(bosh status)
DIRECTOR_UUID=$(echo "$BOSH_STATUS" | grep UUID | awk '{print $2}')
DIRECTOR_CPI=$(echo "$BOSH_STATUS" | grep CPI | awk '{print $2}')
DIRECTOR_NAME=$(echo "$BOSH_STATUS" | grep Name | awk '{print $2}')
NAME=${NAME:-$template_prefix-$infrastructure}

if [[ $DIRECTOR_NAME = "warden" ]]; then
  if [[ $infrastructure != "warden" ]]; then
    echo "Not targeting bosh-lite with warden CPI. Please use 'bosh target' before running this script."
    exit 1
  fi
fi

if [[ $infrastructure = "aws-ec2" ]]; then
  if [[ $DIRECTOR_CPI != "aws" ]]; then
    echo "Not targeting an AWS BOSH. Please use 'bosh target' before running this script."
    exit 1
  fi
fi

if [[ $infrastructure = "vsphere" ]]; then
  if [[ $DIRECTOR_CPI != "vsphere" ]]; then
    echo "Not targeting an vSphere. Please use 'bosh target' before running this script."
    exit 1
  fi
fi

#if [[ $infrastructure = "vcloud" ]]; then
#  if [[ $DIRECTOR_CPI != "vcloud" ]]; then
#    echo "Not targeting an vCloud. Please use 'bosh target' before running this script."
#    exit 1
#  fi
#fi

function latest_uploaded_stemcell {
  bosh stemcells | grep bosh | grep $STEMCELL_OS | awk -F'|' '{ print $2, $3 }' | sort -nr -k2 | head -n1 | awk '{ print $1 }'
}

STEMCELL=${STEMCELL:-$(latest_uploaded_stemcell)}
if [[ "${STEMCELL}X" == "X" ]]; then
  echo
  echo "Uploading latest $DIRECTOR_CPI/$STEMCELL_OS stemcell..."
  STEMCELL_URL=$(bosh public stemcells --full | grep $DIRECTOR_CPI | grep $STEMCELL_OS | sort -nr | head -n1 | awk '{ print $4 }')
  bosh upload stemcell $STEMCELL_URL
fi
STEMCELL=${STEMCELL:-$(latest_uploaded_stemcell)}

stubs=$(dirname $0)/stubs
release=$stubs/..
tmpdir=$release/tmp

mkdir -p $tmpdir
cp $stubs/stub-normal.yml $tmpdir/stub-with-uuid.yml
echo $DIRECTOR_NAME $DIRECTOR_CPI $DIRECTOR_UUID $STEMCELL
perl -pi -e "s/PLACEHOLDER-DIRECTOR-UUID/$DIRECTOR_UUID/g" $tmpdir/stub-with-uuid.yml
perl -pi -e "s/NAME/$NAME/g" $tmpdir/stub-with-uuid.yml
perl -pi -e "s/STEMCELL/$STEMCELL/g" $tmpdir/stub-with-uuid.yml

spiff merge \
  $stubs/deployment.yml \
  $stubs/jobs.yml \
  $stubs/generic-broker-properties.yml \
  $stubs/infrastructure-${infrastructure}.yml \
  $tmpdir/stub-with-uuid.yml \
  $* > $tmpdir/$NAME-manifest.yml

mv $tmpdir/$NAME-manifest.yml .
rm -rf $tmpdir

echo ""
echo "Generated bosh deployment manifest for ${infrastructure}:  $NAME-manifest.yml"
bosh deployment $NAME-manifest.yml
bosh status
