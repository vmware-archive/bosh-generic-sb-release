rm -rf $1
mkdir -p $1
cp -r src packages jobs config templates $1
cp *.sh *yml $1
