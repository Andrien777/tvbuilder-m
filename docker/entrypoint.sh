#!/bin/bash
echo "Activating emsdk environment"
./emsdk/emsdk activate latest
source ./emsdk/emsdk_env.sh
echo "Building lib for linux"
scons platform=linux target=template_release
echo "Building lib for windows"
scons platform=windows target=template_release
echo "Building lib for macos"
export OSXCROSS_ROOT=/opt/tvb-build/osxcross
scons platform=macos target=template_release osxcross_sdk=darwin23
echo "Building lib for web"
scons platform=web target=template_release

cp -r ./bin/* ./build-artifacts

