#!/bin/bash

BUILD_TYPE=$1

build_package() {
    local build_type=$1
    if [ "$build_type" == "rootless" ]; then
        echo "Building rootless"
        export THEOS_PACKAGE_SCHEME=rootless
    else
        echo "Building rootful"
        export THEOS_PACKAGE_SCHEME=
    fi

    make package FINALPACKAGE=1
    make clean
}

rm -rf ./packages


if [ -z "$BUILD_TYPE" ]; then
    build_package "rootful"
    build_package "rootless"
else
    build_package "$BUILD_TYPE"
fi