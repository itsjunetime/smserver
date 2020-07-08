# SMServer

**An iPhone app, written in SwiftUI, which allows for one to send and receive text messages (and iMessages) from their Web browser**

## Features
- Viewing all texts & iMessages from another device
- Viewing image attachments in browser
- Saving image attachments to device
- Sending iMessages without typing on iPhone
- Authentication to protect against spying eyes
- Ability to permanently change passwords and default values
- Background operation of server (app doesn't always have to be in the foreground) 

When you run this app and click the green 'play' button in the bottom left corner, a web server will be launched from your iDevice's private IP. The app should display the IP & port that you need to connect to in another device's web browser. If you enter that into your web browser, you will be presented with an authentication screen. Type in the default password (toor), and you will be shown the web interface. It looks very similar to the iMessage app on macOS Catalina and lower, and should be easy to navigate. 

### Caveats
- One must run this on a jailbroken iPhone or one that has escaped the sandbox (for example, a device running iOS 13.4.1 or lower and using Siguza's psychic paper exploit)
- The app only has limited background time (about 1 - 3 minutes), so after that much time of the app being suspended/backgrounded, the server will be killed & you'll need to re-enter the app and restart it.
- Before you run the app, you have to open the Messages app and leave it running in the background (or just verify that the messages app is running); this is temporary, and soon you won't have to do this.

## TODO

- [x] View conversations in browser
- [x] View texts in browser
- [x] Dynamic loading of texts
- [x] Send texts from browser without on-device interaction
- [x] View all attachments in browser
- [ ] Send images/attachments from browser
- [x] Automatic checking for new messages
- [ ] Notifications on-device whenever new messages arrive
- [x] Display notifier for which conversations have unread messages
- [x] Persistent defaults

### Future plans
- [ ] Convenient Custom CSS Loading
- [ ] Allow the server to run in the background - This has somewhat been implemented. 
- [ ] Search through messages from browser
- [ ] Start new conversations from browser

### Dependencies
- libsmserver, the tweak which allows sending texts with this app. You can get it from [here](https://github.com/iandwelker/libsmserver).

## To Install
This is definitely still in Beta stages; there are still issues and many features that need to be implemented. You have two options for installing: The provided IPA or building from source. If you want to use the IPA, simply download it from the `ipa` subdirectory here. To build from source:

1. Clone this repository
2. cd into the directory where the podfile is installed
3. If cocoapods are not installed, run 'sudo gem install cocoapods'
4. Run 'pod intall'
5. Open the .xcworkspace file in Xcode
6. Build and install the project!

I would recommend building it yourself, since the IPA (under `ipa`) may not always be up to date with the source code, but if you can't or would rather not, the IPA should be updated rather frequently, so it is also safe to use.

## To run

1. First open the messages app on your phone. You don't have to leave this in the foreground, just make sure it's at least running in the background.
2. Open the SMServer app, and click the green 'play' button in the bottom left.
3. Open your browser to the ip/port combo specified at the top of the view
4. Authenticate with the default password ('toor'), or your own custom password if you already set one
5. Enjoy!
6. (Optional) Customize the defaults under the settings section of the app to better fit your needs 

## Issues
If there are any issues, questions, or feature requests at all, don't hesitate to create an issue or pull request here. I may not run into all issues that could possibly come up, so I would really appreciate any issues you let me know about.

### Acknowledged current issues:
- Message text box in web interface doesn't correctly resize when typing a multi-line text

## Companion App
There is a [python app](http://github.com/iandwelker/smserver_receiver), based on curses, which I would highly recommend one use in conjunction with this app. It is significantly faster than the web interface, much easier to navigate, much more customizable, and authenticates for you. You can get it at the link above; it has all the information necessary to get it up and running. As always, just ask or open an issue if you have a question. 
