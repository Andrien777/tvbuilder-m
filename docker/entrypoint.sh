#!/bin/bash

if [ "$BUILD_WEB" = "y" ] ; then
echo "Activating emsdk environment"
/opt/tools/emsdk/emsdk activate latest
source /opt/tools/emsdk/emsdk_env.sh
fi

cd /opt/tvb-build

if [ "$BUILD_TARGET" = "RELEASE" ] ; then

	echo "Building lib for linux"
	scons platform=linux target=template_release
	echo "Building lib for windows"
	scons platform=windows target=template_release

	if [ "$BUILD_MACOS" = "y" ] ; then
	echo "Building lib for macos"
	export OSXCROSS_ROOT=/opt/tools/osxcross
	scons platform=macos target=template_release osxcross_sdk=darwin23
	fi

	if [ "$BUILD_WEB" = "y" ] ; then
	echo "Building lib for web"
	scons platform=web target=template_release
	fi

else

	echo "Building lib for linux"
	scons platform=linux target=template_debug
	echo "Building lib for windows"
	scons platform=windows target=template_debug

	if [ "$BUILD_MACOS" = "y" ] ; then
	echo "Building lib for macos"
	export OSXCROSS_ROOT=/opt/tools/osxcross
	scons platform=macos target=template_debug osxcross_sdk=darwin23
	fi

	if [ "$BUILD_WEB" = "y" ] ; then
	echo "Building lib for web"
	scons platform=web target=template_debug
	fi

fi

