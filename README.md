<p align="center"><img src="assets/icon_small.png" /></p>
<h1 align="center">SMServer</h1>
<p align="center"><a href="https://github.com/iandwelker/smserver/releases"><img src="https://img.shields.io/github/v/release/iandwelker/smserver.svg?style=flat"/></a>&nbsp;&nbsp;<a href="https://github.com/iandwelker/smserver/blob/master/LICENSE"><img src="https://img.shields.io/github/license/iandwelker/smserver.svg?style=flat"></a>&nbsp;&nbsp;<a href="https://github.com/iandwelker/smserver/issues"><img src="https://img.shields.io/github/issues/iandwelker/smserver.svg?style=flat"/></a>&nbsp;&nbsp;<a href="https://github.com/iandwelker/smserver/stargazers"><img src="https://img.shields.io/github/stars/iandwelker/smserver?style=flat"/></a>&nbsp;&nbsp;<a href="https://repo.twickd.com/package/com.twickd.ian-welker.smserver"><img src="https://img.shields.io/static/v1?label=repository&message=twickd&color=red"/></a></p>

<img src="assets/smserver.png" style="border-radius: 5px;"/>
<span style="font-weight: 200; font-size: 12px">The web interface shown with personal information blurred out</span>

**SMServer is an iPhone app, written in SwiftUI, which allows for one to send and receive text messages (and iMessages) from their Web browser**

> **NOTE:** SMServer is not currently under any active development. For the forseeable future, I will not be working on any improvements, new features, or bug fixes. If anyone would like to contribute (either by taking over development or submitting PRs), I will still be happy to help you along, and am happy to answer questions about this project (submitted through an issue, an email, etc), but won't be writing any code myself.

## Features
- Viewing all texts & iMessages from another device
- Sending texts, iMessages, attachments, camera roll pictures, and tapbacks remotely
- TLS
- Desktop Notifications upon new text arrival
- Ability to browse and send attachments from host device camera roll
- Authentication to protect against spying eyes
- Background operation of server for unlimited time, with screen on or off
- Easy and accessible customization options
- Ability to set custom css rules for easy web interface customization
- Easy to use and very customizable search API
- Sending and viewing of read receipts
- Easy switching between Light, Dark, and Nord themes
- Typing indicators when you or other party starts composing
- Information on web interface about battery level and charging state

### Dislaimer
&nbsp;&nbsp;&nbsp;&nbsp; Reminder that software this comes with **no warranty** and is provided **as is**. Although I do my best to prevent it from harming your device (feel free to contact me if you would like details on how I do this), I cannot ensure that it will do no harm, and I cannot be held liable if such damage occurs.

### Caveats
- One must run this on a jailbroken iPhone. It will crash on a non-jailbroken phone.

### Dependencies
- [libMRYIPC](https://github.com/Muirey03/MRYIPC), which should be available on a default repo.

## To Install
Use the provided .ipa or .deb package under the Releases, or read `docs/INSTALL.md` for information on how to build from source.

The source code may be updated past the latest released version, so don't be surprised or confused if you see new features listed on the README or under `docs/Changelog.md` that you don't see in the app yet.

## To run
1. Open the SMServer app, and click the green 'play' button in the bottom left.
3. Open your browser to the ip/port combination specified at the top of the view
4. Authenticate with the default password (`toor`), or your own custom password if you already set one
5. Enjoy!
6. (Optional) Customize the defaults under the settings section of the app to better fit your needs

## Issues
If there are any issues, questions, or feature requests at all, don't hesitate to create an issue or pull request here, or email me at contact@ianwelker.com. I will not run into all issues that could possibly come up, so I would really appreciate any issues you let me know about.

### To file an issue:
Please include the following information:
 - Device model
 - Jailbreak (e.g. checkra1n, unc0ver, Chimera, etc)
 - iOS Version
 - How you installed the app
 - A detailed description of what failed
 - What version of SMServer & libsmserver you're running
 - And if the app crashed & you can get it, a crash log

Also, if the app did not crash on startup, but rather crashed after it was already up and running, I would appreciate if you could do the following:
 - Install the package 'oslog' from your package manager
 - ssh into your device and run (as root): `oslog --debug | grep -i -e "SMServer_app" -e "mryipc"`; do not redirect the output into a file.
 - Enable debug in the app's settings
 - Start the app and let it reach the error point
 - Manually copy the output from the above command (as much as you can get) into a text file.
 - Email me the file at contact@ianwelker.com. This file may have sensitive information, such as contact phone numbers, so it wouldn't be smart to upload it to a public site. Feel free to filter out (with something like regex or by hand) the sensitive information.

## Companion App
There is a [terminal-based app](http://github.com/iandwelker/smcurser) which I would highly recommend one use in conjunction with this app. It is significantly faster than the web interface, much easier to navigate, more easily customizable, is the only client to support pure-websocket/remote connections, and authenticates for you. You can get it at the link above; it has all the information necessary to get it up and running. As always, just ask or open an issue if you have a question.

## Donations
If you have any money to spare, I would recommend donating to the [National Network of Abortion Funds](https://abortionfunds.org/) (if you're in the US), trans rights organizations such as [Mermaids UK](https://mermaidsuk.org.uk/), or getting involved with a local climate justice organization, such as [Fridays For Future](https://fridaysforfuture.org/), [The Sunrise Movement](https://www.sunrisemovement.org/), or [The Democratic Socialists of America](https://www.dsausa.org/). If you are opposed to supporting these causes, support Conservatives/Tories/AfD/etc, or believe in other scams such as trickle-down economics or blockchain/cryptocurrencies, please don't touch my project and distance yourself from it as much as possible.
