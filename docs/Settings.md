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

### Interval for website to ping app (seconds):
As of right now (version 0-1-0+debug68), server does not support WebSockets connections, so it has to check with the host every time it wants new information. This setting could theoretically be set to 0, but that will virtually prevent any other connections from reaching the host, since these check requests will be taking up all the available bandwidth. The lower you set this value, the harder it will be for other requests to get through.

I think the ideal setting for this is somewhere between 3-5 seconds; it will still be regularly updating, but won't take up too much of the available bandwidth. This does not require a server restart to take effect.

### Websocket Port
This is the port that the webSocket runs on; must not be the same as the server port or outside of the allowable range, or else the app will crash when launching the server. You must restart the server before this takes effect

### Toggle debug
This will log basically every thing that happens, and may slow down the server considerably. Unless you're actually debugging or logging with the app, I'd highly recommend leaving this off. This does not require a server restart to take effect.

### Start server on load:
Toggling this on will make the server start automatically whenever the app is opened. It requires a full app restart to take effect, since that's the only thing that it does affect.

### Requre Authentication to view messages:
Toggling this on will prevent anyone from querying the host if they have not already authenticated with the main page. I'd highly recommend leaving it on; without it, anyone can send and view texts from your device without restriction.

### Enable backgrounding
Toggling this on will prevent the server from shutting off when the app goes into the background, given that the server is already running. Even if this is on, though, the server will shut down when the app is forcibly killed from the multitasking screen. This does not require anything to take effect, simply a toggle.