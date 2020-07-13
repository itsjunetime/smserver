#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

xcodebuild clean build -workspace ${ROOTDIR}/src/SMServer.xcworkspace -scheme SMServer -destination generic/platform=iOS
xcodebuild archive -workspace ${ROOTDIR}/src/SMServer.xcworkspace -scheme SMServer -archivePath ${ROOTDIR}/package/SMServer.xcarchive -destination generic/platform=iOS

rm -rf ${ROOTDIR}/package/SMServer.xcarchive
rm -rf ${ROOTDIR}/package/deb/Applications/SMServer.app
cp -r ${ROOTDIR}/package/SMServer.xcarchive/Products/Applications/SMServer.app ${ROOTDIR}/package/deb/Applications/SMServer.app

echo "Removing past directory"
sshpass -p $THEOS_DEVICE_PASS ssh root@$THEOS_DEVICE_IP rm -rf /var/mobile/Documents/SMServer
echo "Sending over deb directory"
sshpass -p $THEOS_DEVICE_PASS scp -Crp ${ROOTDIR}/package/deb root@${THEOS_DEVICE_IP}:/var/mobile/Documents/SMServer
echo "Making new package"
sshpass -p $THEOS_DEVICE_PASS ssh root@$THEOS_DEVICE_IP dpkg -b /var/mobile/Documents/SMServer
echo "Receiving new deb"
sshpass -p $THEOS_DEVICE_PASS scp -C root@${THEOS_DEVICE_IP}:/var/mobile/Documents/SMServer.deb ${ROOTDIR}/package/SMServer.deb

rm -rf ${ROOTDIR}/package/SMServer.xcarchive
