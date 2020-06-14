#!/bin/bash

VERSION=${VERSION:-16.11}

[ "${1}" == "--build" ] && {
    toClean=$(docker images | egrep "${USER}/${PWD##*/}|none" | awk '{ print $3 }');

    [ ! -z "${toClean}" ] && {
        docker rmi ${toClean};
    }
}

time docker build -t ${USER}/${PWD##*/}            . && \
time docker build -t ${USER}/${PWD##*/}:${VERSION} .