# FAQ

### I have the server running, but can't connect to it.
There are a few things you should check:
1. Have you made sure to install all of the dependencies (specifically `libsmserver` and `libMRYIPC`)?
1. Did you start the server with the green button on the bottom left of the app?
1. Are you connecting to the right address with regard to using `https://` vs `http://`?
1. Are your host and client devices on the same LAN/WLAN networks?
1. Did you verify that neither device's firewall is blocking the connection?

If you can answer 'yes' to all the above questions, feel free to file an issue in the `Issues` tab above.

### The app is crashing when I click on a conversation in the left-hand side of the web interface

Try disabling 'Mark conversations as read when viewed on web interface' in the settings of the app, restarting the app, and try again. If it still crashes, feel free to file an issue.

### I'd like to run this behind an nginx reverse proxy so that I can access it when I'm not on the same network. How would I do that?

As of version 0.7.0, SMServer can run perfectly behind a reverse proxy, and it's very easy to set it up. Here's what you have to do:

1\. Install nginx on your device.  \
2\. Open up the configuration file (`/etc/nginx/nginx.conf` on GNU/Linux, `/usr/local/etc/nginx/nginx.conf` on macOS), and add the following inside the main `server { }` block:
```
proxy_ssl_verify off;

location /smserver/ {
    proxy_pass https://192.168.0.180:8741/;
}

location /smserver_websocket/ {
    proxy_pass https://192.168.0.180:8740/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

The above block defines that you will be running the main SMServer server at the subdirectory `/smserver/`, and that you will be running the websocket at the subdirectory `/smserver_websocket/`. You are free to change these directories, but make sure to adjust the next step accordingly if you do. \
3\. Open the settings of the SMServer app on your host device, and enable 'WebSocket Proxy Compatibility' under 'Web interface Settings'. In the box that appears, enter the subdirectory that the websocket resides at in your reverse proxy (in this case, it is `/smserver_websocket/`, but if you change it you'll need to type in what you set it to instead).

### The website stops automatically updating after a while and I have to refresh it to see new texts/an accurate battery percentage.

Try disabling the option "Restart server on network change" in the host device's settings. If you're running SMServer behind a reverse proxy, you may also want to look at [this comment](https://github.com/iandwelker/smserver/issues/73#issuecomment-762618203) to see if it helps.
If neither of these fix it, feel free to file an issue.

### How did you make this?

In this same directory, there's a document called `IMCore_and_ChatKit.md` that details how I used ChatKit and IMCore for the backend of this app. It should have most things that you'd be interested in. If there are still other questions you'd like to ask or things you don't understand, feel free to DM me at u/Janshai on reddit, or @Janshaidev on twitter.

### I'd like to contribute

Feel free to! I wholly welcome pull requests, so if you feel you can implement a feature that you'd like to see included, you're welcome to fork the project and submit a pull request when you feel you've got it working well.
