#!/bin/bash

xcodebuild clean -workspace ./src/SMServer.xcworkspace -scheme SMServer
xcodebuild build -workspace ./src/SMServer.xcworkspace -scheme SMServer
xcodebuild archive -workspace ./src/SMServer.xcworkspace -scheme SMServer -archivePath ./ipa/SMServer.xcarchive CODE_SIGNING_ALLOWED=NO

mkdir -p ipa/Payload
cp -r ipa/SMServer.xcarchive/Products/Applications/SMServer.app ipa/Payload/SMServer.app
zip ipa/SMServer.zip ipa/Payload
mv ipa/SMServer.zip ipa/SMServer.ipa

rm -rf ipa/SMServer.xcarchive ipa/Payload
find . -name ".DS_Store" -delete
