# WebSocket (API)

As of 0.2.0+debug2, the server supports websockets. This is, as of 0.5.0, used to send messages from client to the host, and from host to client. It supports sending/receiving 5 messages as of right now, all plain text. They are all in the format of `$prefix:$content`, e.g. `battery:34`. The default port for the websocket on the host device is 8740.

## Messages to client from host

### `text`
Every time that the host reeives a new text, a message with the prefix `text` is sent to all connected devices. The content of this message is a JSON message with a key of `text` that describes all the necessary parameters of the most recent text that you just received. For example, if you just got sent a text that simply said 'Hello!' from the number '+11231231234', this message would look something like:
```json
text:{ "text": {  "ROWID" : "150000",  "subject" : "",  "chat_identifier" : "+11231231234",  "balloon_bundle_id" : "",  "is_from_me" : "0",  "service" : "iMessage",  "guid" : "3FCF9CC7-FFF3-4172-82FD-773F9A3CC89A",  "text" : "Hello!",  "date_read" : "0",  "date" : "626981115265999744",  "cache_has_attachments" : "0",  "handle_id" : "100",  "associated_message_type" : "0",  "associated_message_guid" : ""}}
```

### `battery`
A message with this prefix is sent every time the battery level or battery state of the host device changes, and will either be sent as an Int between 0 - 100 (to show the battery level), or a string that is either `charging` or `unplugged`. For example, to show that the battery level is now 89, it would send: `battery:89`. And to show that the phone is now charging when it previously wasn't, it would send `battery:charging`.

### `typing`
A message with this prefix is sent every time that someone in one of their conversations starts typing. The content of this message is a string which is the chat_identifier of the conversation where the other party started typing. It will look something like `typing:+11231231234`.

## Messages sent to host from client

### `typing`
A message with this prefix is sent every time you start typing on the web interface, and its content contains a string which is the converation in which you started typing. If you have the 'Send typing indicator when you type' setting enabled on the host device, your device will then notify the other party in that conversation that you are typing (just like if you started typing in the iMessages app)

### `idle`
A message with this prefix is sent every time the length of the text you are composing goes down to 0, or you stop typing for 10 straight seconds. The content of this message is a string which is the conversation in which you stopped typing. This will then notify the other party that you stopped typing (just as if you stopped typing in the iMessages app)
