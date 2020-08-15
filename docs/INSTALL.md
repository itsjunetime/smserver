# To Install

### To build from source and install as regular app:

1. Make sure you have xcode commandline tools installed
1. Clone this repository
1. cd into the directory where the podfile is installed
1. Edit the podfile so that the git url of pod 'Criollo' is `https://github.com/iandwelker/Criollo.git`. This is my custom fork which allows for uploading of multiple files in one input tag
1. If cocoapods are not installed, run `sudo gem install cocoapods`
1. Run `pod install`
1. Open the .xcworkspace file in Xcode
1. Connect your device
1. Build and install the project!

### To build from source and install as .deb (system app):

1. Make sure you have xcode commandline tools installed
1. Clone this repository
1. cd into the directory where the podfile is installed
1. Edit the podfile so that the git url of pod 'Criollo' is `https://github.com/iandwelker/Criollo.git`. This is my custom fork which allows for uploading of multiple files in one input tag
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
