# WebSocket (API)

As of 0.2.0+debug2, the server supports websockets. This is not used at all to send messages from client to the host, but only to send messages from host to client. It supports sending 3 messages as of right now, all plain text. They are all in the format of `$context:$content`, e.g. `text:+15202583393`

## `text`
Every time that the host receives a new text, a message with the context of `text` is sent to all connected clients with the content of the chat_id that send the message. For example: `text:email@icloud.com` or `text:+19398792093`

## `battery`
This is currently never sent, but will be sent every time the battery level of the host device changes, and will be send as an Int between 0 - 100. For example: `battery:89`

## `wifi`
This is currently never sent, but will be sent every time the wifi signal level changes. Since it is not currently implemented, I don't know what the content will be. 