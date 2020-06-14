#!/bin/bash

GITLAB_PATH=$1
GITHUB_PATH=$2

VERSION=$3
BRANCH=$4

######################
# Podspec version
######################

cd ${GITHUB_PATH}
git checkout ${BRANCH}
git pull

rm -rf ${GITHUB_PATH}/*
cp -rf ${GITLAB_PATH}/* ${GITHUB_PATH}

exit 0
