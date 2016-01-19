rm -rf $1
mkdir -p $1
mkdir -p $1/blobs
cp -r src config templates bin $1
#cp *.sh *yml $1
