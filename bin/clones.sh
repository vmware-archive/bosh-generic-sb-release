#!/bin/ksh

rm -rf $1
mkdir -p $1
cp -r src config templates $1
cp *.sh *yml $1
mkdir $1/jobs
mkdir $1/packages
