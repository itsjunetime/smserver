#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

xcodebuild clean build -workspace ${ROOTDIR}/src/SMServer.xcworkspace -scheme SMServer -destination generic/platform=iOS
xcodebuild archive -workspace ${ROOTDIR}/src/SMServer.xcworkspace -scheme SMServer -archivePath ${ROOTDIR}/package/SMServer.xcarchive -destination generic/platform=iOS

cp ${ROOTDIR}/package/SMServer.xcarchive/Products/Applications/SMServer.app ${ROOTDIR}/package/deb/Applications/SMServer.app

sshpass -p $THEOS_DEVICE_PASS ssh root@$THEOS_DEVICE_IP rm -rf /var/mobile/Documents/SMServer
sshpass -p $THEOS_DEVICE_PASS scp -Crp ${ROOTDIR}/package/deb root@${THEOS_DEVICE_IP}:/var/mobile/Documents/SMServer
sshpass -p $THEOS_DEVICE_PASS ssh root@$THEOS_DEVICE_IP dpkg -b /var/mobile/Documents/SMServer
sshpass -p $THEOS_DEVICE_PASS scp -C root@${THEOS_DEVICE_IP}:/var/mobile/Documents/SMServer.deb ${ROOTDIR}/package/SMServer.deb

rm -rf ${ROOTDIR}/package/SMServer.xcarchive
