# To Install
This is still in Beta stages; there are still issues and some features that I hope to implement. You have two options for installing: Using the provided .deb or .ipa or building from source. If you want to use the .deb or .ipa, simply download it from the `package` subdirectory here. 

### To build from source and install as regular app:

1. Make sure you have xcode commandline tools installed
1. Clone this repository
1. cd into the directory where the podfile is installed
1. If cocoapods are not installed, run `sudo gem install cocoapods`
1. Run `pod install`
1. Open the .xcworkspace file in Xcode
1. Connect your device
1. Build and install the project!

Alternately, if you want to install as a .ipa file:

1. Export `$DEV_CERT` as your apple codesigning identity (e.g. 'Apple Development: email@email.com (HS9D73GS8D)')
1. Run the `ipa_make.sh` script in the root of this directory.
1. When the finder window pops up, right-click on the 'Payload' folder and select 'Compress Payload' 
1. Rename `Payload.zip` to `SMServer.ipa` and install it as normal

### To build from source and install as .deb (system app):

1. Make sure you have xcode commandline tools installed
1. Clone this repository
1. cd into the directory where the podfile is installed
1. If cocoapods are not installed, run `sudo gem install cocoapods`
1. Run `pod install`
1. Open the .xcworkspace file in Xcode
1. In the 'product' section of the menu bar, run 'clean build folder', then 'build for > running', then 'archive'
1. When the archive window appears, right click on the archive and select 'show in finder'
1. Right click on the .xcarchive file, and select 'show package contents'. 
1. Navigate to 'products' > 'Applications', and copy 'SMServer.app'
1. Place the 'SMServer.app' package in the 'package/deb/Applications/' subdirectory of this cloned repository
1. Copy the entire 'deb' folder over to an iDevice that is jailbroken
1. SSH into the idevice (or open a terminal app), and cd into the directory where the 'deb' folder is located
1. Run `dpkg -b deb`, assuming that the 'deb' folder is still named 'deb'. This will produce a package named 'deb.deb'. You can rename it to whatever you want.
1. Install the package that the last step created just as you would install a tweak.

Alternately, if you want to install the deb but don't want to go through with the above steps, you can: 

1. Install the app 'sshpass' on your mac
1. Export `$THEOS_DEVICE_PASS` as your iDevice's password
1. Export `$THEOS_DEVICE_IP` as your iDevice's private IP
1. Export `$DEV_CERT` as your apple codesigning identity (e.g. 'Apple Development: email@email.com (HS9D73GS8D)')
1. Run the `deb_make.sh` script in the root of this repository. The new .deb will be in the 'package' subdirectory of this cloned repo.

I would recommend building it yourself, since the packages may not always be up to date with the source code, and I build it with Xcode-beta (so it may have issues that your build may not), but if you can't or would rather not, the packages will be updated rather frequently, so they are safe to use.