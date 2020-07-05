#!/bin/bash

FRAMEWORK_NAME=$1
VERSION=$2
BRANCH=$3

SRCROOT_PATH=..

cd $SRCROOT_PATH
git checkout $BRANCH
git pull

######################
# Podspec version
######################
POD_PAHT=./${FRAMEWORK_NAME}.podspec
if [[ $BRANCH == 'pre' ]]; then
    POD_PAHT=./${FRAMEWORK_NAME}-pre.podspec
fi

POD_VERSION_CODE="  s.version      = "
if [ `grep -c "\"${VERSION}\"" $POD_PAHT` == '0' ]; then
    LINE=`grep -n "${POD_VERSION_CODE}" ${POD_PAHT} | head -1 | cut -d ":" -f 1`
    LINE=$((${LINE} - 1))
    echo "${POD_VERSION_CODE} at line: ${LINE}"

    sed -i '' "/${POD_VERSION_CODE}/d" ${POD_PAHT}
    sed -i '' "${LINE} a\ 
    \\${POD_VERSION_CODE}\"${VERSION}\"
    " ${POD_PAHT}
fi

######################
# Lib version
######################
LIB_VERSION_PATH=${FRAMEWORK_NAME}/${FRAMEWORK_NAME}.m
LIB_VERSION_CODE="#define VERSION @"
if [ `grep -c "${LIB_VERSION_CODE}\"${VERSION}\"" ${LIB_VERSION_PATH}` == '0' ]; then
    LINE=`grep -n "${LIB_VERSION_CODE}" ${LIB_VERSION_PATH} | head -1 | cut -d ":" -f 1`
    LINE=$((${LINE} - 1))
    echo "${LIB_VERSION_CODE} at line: ${LINE}"

    sed -i '' "/${LIB_VERSION_CODE}/d" ${LIB_VERSION_PATH}
    sed -i '' "${LINE} a\ 
    \\${LIB_VERSION_CODE}\"${VERSION}\"
    " ${LIB_VERSION_PATH}
fi

######################
# GitLab
######################
# 提交版本修改代码
#git add .
#git commit -m "修改版本号为：${VERSION}"
#git push

exit 0
