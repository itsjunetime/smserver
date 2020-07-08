#!/bin/bash

xcodebuild clean -workspace ./src/SMServer.xcworkspace -scheme SMServer
xcodebuild build -workspace ./src/SMServer.xcworkspace -scheme SMServer
xcodebuild archive -workspace ./src/SMServer.xcworkspace -scheme SMServer -archivePath ./ipa/SMServer.xcarchive CODE_SIGNING_ALLOWED=NO

mkdir -p ipa/SMServer_new/Payload
cp -r ipa/SMServer.xcarchive/Products/Applications/SMServer.app ipa/SMServer_new/Payload/SMServer.app
zip ipa/SMServer.ipa ipa/SMServer_new

rm -rf ipa/SMServer.xcarchive ipa/SMServer_new
find . -name ".DS_Store" -delete
