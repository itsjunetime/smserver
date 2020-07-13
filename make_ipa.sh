#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

rm -rf ${ROOTDIR}/package/SMServer.xcarchive
xcodebuild clean build -workspace ${ROOTDIR}/src/SMServer.xcworkspace -scheme SMServer -destination generic/platform=iOS
xcodebuild archive -workspace ${ROOTDIR}/src/SMServer.xcworkspace -scheme SMServer -archivePath ${ROOTDIR}/package/SMServer.xcarchive -destination generic/platform=iOS

rm -rf ${ROOTDIR}/package/Payload/SMServer.app
cp -r ${ROOTDIR}/package/SMServer.xcarchive/Products/Applications/SMServer.app ${ROOTDIR}/package/Payload/SMServer.app

open ${ROOTDIR}/package # 'Cause 'Compress' in the finder can't be done via commandline
# Now, once it's open, just Click 'compress' on the Payload folder and rename it to 'SMServer.ipa'
