echo $PWD

export RELEASE_NAME=${RELEASE_NAME:-appdirect-dev}
export RELEASE_VERSION=${RELEASE_VERSION:-1.0}
export RELEASE_FILE=${RELEASE_NAME}_${RELEASE_VERSION}.tgz

apt-get update
apt-get install wget

ls repo/

echo Creating a bosh release
cd repo
./fetch_cf_cli.sh
bosh -n create release --name $RELEASE_NAME --version $RELEASE_VERSION --force --with-tarball
#ls -al ./dev_releases/appdirect-dev/appdirect-(.+).tgz
