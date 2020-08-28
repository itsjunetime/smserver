# Settings

There are a few settings available on the app for customization, and are all persistent over app restarts.

## To take effect:

After you change any settings, you'll need to (at least) click the purple 'refresh' button in the bottom left for them to take effect. Some also require a server restart.

## Options: 

### Port:
This is the port that the server will be run on. It needs to be completely numeric, and over 1000. One also must restart the server before this takes effect.

### Pass:
This is the password that you need to type in to authenticate with the server. It can include any characters and be any length. The server must also be restarted before this takes effect.

### Custom CSS:
This allows you to upload a file with CSS rules which will be applied to your main chats page; it doesn't style the gatekeeper page as of right now. However, it doesn't require a server restart to take effect, so you can load a file, hit refresh, and it will immediately be applied. For more information, visit the CustomCSS.md file.

### Initial number of chats to load:
This is the initial number of conversations that will appear in the sidebar (underneath 'Messages') when you first visit the web interface. Setting this to 0 will load all your chats. The server does not need to be restarted for this to take effect

### Initial number of messages to load: 
This is the initial number of messages to load when you select a conversation on the web interface. Setting this to 0 will load all the messages in that conversation (which will inevitably take a very long time if it is a conversation with upwards of 5000 messages.). The server does not need to be restarted for this to take effect.

### Initial number of photos to load:
This is the initial number of photos that will load when retrieving photos from the photos library on the device, specifically with the `photos` parameter on the `requests` As of 0-2-0+debug8, this has not yet been implemented into the web interface, but exists in the API. 

### Websocket Port
This is the port that the webSocket runs on; must not be the same as the server port or outside of the allowable range, or else the app will crash when launching the server. You must restart the server before this takes effect

### Theme
This setting sets the color theme of the web interface; Dark is the default. It is much more polished, and, I think, looks much better than the light theme, but I did make a light theme as well for easy access.

### Toggle debug
This will log basically every thing that happens, and may slow down the server considerably. Unless you're actually debugging or logging with the app, I'd highly recommend leaving this off. This does not require a server restart to take effect.

### Requre Authentication to view messages:
Toggling this on will prevent anyone from querying the host if they have not already authenticated with the main page. I'd highly recommend leaving it on; without it, anyone can send and view texts from your device without restriction.

### Enable backgrounding
Toggling this on will prevent the server from shutting off when the app goes into the background, given that the server is already running. Even if this is on, though, the server will shut down when the app is forcibly killed from the multitasking screen. This does not require anything to take effect, simply a toggle.

### Enable SSL
Toggling this will require you to connect to the `https://` site, instead of the `http://` site. It also encrypts everything sent to your phone for the server, preventing anyone from listening in on your messages.

### Mark conversations as read when viewed on web interface
This should be fairly self explanatory; if this is toggled, whenever you view a conversation on the web interface, it is marked as read on your device as well.
