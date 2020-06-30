# SMServer

**An iPhone app, written in SwiftUI, which allows for one to send and receive text messages (and iMessages) from their Web browser**

## Features
- Viewing all texts & iMessages from another device
- Viewing image attachments in browser
- Saving image attachments to device
- Sending iMessages without typing on iPhone
- Authentication to protect against spying eyes
- Ability to change passwords and default values

When you run this app and click the green 'play' button in the bottom left corner, a web server will be launched from your iDevice's private IP. The app should display the IP & port that you need to connect to in another device's web browser. If you enter that into your web browser, you will be presented with an authentication screen. Type in the default password (toor), and you will be shown the web interface. It looks very similar to the iMessage app on macOS Catalina and lower, and should be easy to navigate. 

### Caveats
- One must run this on a jailbroken iPhone or one that has escaped the sandbox (for example, a device running iOS 13.4.1 or lower and using Siguza's psychic paper exploit)
- Sending a text requires on-device confirmation before the text is dispatched. This is ~~because I couldn't figure out how do make a tweak to programatically send a text~~ so that the app is compatible with non-jailbroken devices.
- As of right now, the server will not work unless the app is in the foreground. Soon, that will not be the case, but it is so right now.

## TODO

- [x] View conversations in browser
- [x] View texts in browser
- [x] Dynamic loading of texts
- [x] View Images in browser
- [x] Send texts (mostly) from browser
- [ ] Send texts without on-device interaction
- [x] View images in browser
- [x] View all attachments in browser
- [ ] Send images/attachments from browser
- [ ] Display new messages when they arrive
- [x] Automatic checking for new messages
- [x] Display notifier for which conversations have unread messages
- [ ] Persistent defaults

### Future plans
- [ ] Convenient Custom CSS Loading
- [ ] Allow the server to run in the background
- [ ] Search through messages from browser

## To Install
This is definitely still in Beta stages; there are still issues and many features that need to be implemented. However, if you do want to test it or use it for the time being, the steps are pretty simple:

1. Clone this repository
2. CD into the directory where the podfile is installed
3. If cocoapods are not installed, run 'sudo gem install cocoapods'
4. Run 'pod intall'
5. Open the .xcworkspace file in Xcode
6. Build and install the project!

## Issues
If there are any issues, questions, or feature requests at all, don't hesitate to create an issue or pull request here. I may not run into all issues that could possibly come up, so I would really appreciate any issues you let me know about.

### Acknowledged current issues:
- Message text box in web interface doesn't correctly resize when typing a multi-line text
- Conversations with unread messages aren't always displayed as such in web interface
- Users have to authenticate twice if connecting to web server over USB as opposed to WLAN
- Sometimes, windows browsers can't connect to server (or maybe my computer is just messed up. This issue needs confirmation.)

## Companion App
Currently, there is a python companion app in the works; it is compatible with this and the mac version of this app but I'm not releasing it yet since it doesn't have all the features necessary to work correctly. Wait a bit and it'll be out soon.

