# Remote Communication

As of version 1.0.0, SMServer has support for easy communication with out-of-network clients via Websockets.

## How it works

Both the SMServer host and client connect through [this application](https://github.com/iandwelker/ws_router), which must be run on a different computer. You can read the instructions on the README of that repository, which describes how both the host and client register and connect to the server.

To enable it, you'll need to toggle the `Enable remote connection` setting on the host, and configure the subsequent options to exactly what works for you.

## Once it's connected

The single websocket communication allows both the host and client to send messages to the other, and since that is the only connection between the two, that is how all data is sent. Every message sent between the two is in the form of a __JSON object__ and contains at least one parameter, `command`, which signals the information that is being requested or sent.

Most commands have a REST API equivalent, and the parameters and return information for the websocket communication is exactly the same as the REST API equivalent. Those that don't have a REST Equivalent are explained in detail

### Messages to the client
The format of all messages to the client are in the form of a JSON object with three keys:
- `id`: The unique identifier for this command. This key will not exist if the message is not in response to a request from the client. However, if it is in response to a request from the client, `id` will be the same as the `id` in the corresponding request to the host.
- `command`: A string that identifies what type of information the host is sending to the client
- `data`: The information that is actually being sent
- `last`: Whether or not this is the last message that will be sent to the client with this same ID.

### Messages to the host
The format of all messages to the host are in the form of a JSON object with three keys:
- `id`: This is required in all messages to the host, so that the client can recognize the return message. It must be a uuid generated client-side.
- `command`: A string that identifies what type of information is being requested from or sent to the host.
- `params`: The parameters that should be sent with the REST API, translated from a url query to a json Object. E.g. if the original url query was `messages=+11231231234&num_messages=40`, the json Object would be:
```json
{
	"messages": "+11231231234",
	"num_messages": 40
}
```

## All The Commands:

__Types of Requests__
- *rwr*: Request with response
- *not*: Notification sent from host to client(s), with no response from client(s)
- *req*: Request from client to host with no response

| Command | Corresponding REST | Type | Notes |
| - | - | - | - |
| `get-chats` | `requests?chats` | rwr | This does not require a value for the `chats` parameter, but it must at least include the key `chats` |
| `get-messages` | `requests?messages` | rwr | |
| `get-name` | `requests?name` | rwr | |
| `get-attachment` | `data?path` | rwr | The REST API returns data for this, so read the below section on how this websocket system handles data |
| `get-icon` | `data?chat` | rwr | Once again, read the below section on how this websocket system handles data |
| `send-message` | POST `send` | req | Read the below section on sending messages through this system |
| `attachment-data` | | req | Used to help with sending attachments through `send-message`, and is not used at all when using the REST API instead of the Remote version. |
| `send-tapback` | `send?tapback` | req | |
| `delete-chat` | `send?delete_chat` | req | |
| `delete_text` | `send?delete_text` | req | |
| `send-typing` | | req | This one corresponds to the function in the websocket to send typing indicators. <br/><br/> The two parameters for this are `chat` (the `chat_identifier` of the conversation you're typing in), and `active` (a bool which corresponds to if you just started typing or just stopped) |
| `battery-status` | | not | This is called when the battery percentage or charging status changes. <br/><br/> The two parameters for this are `charging` (a bool to indicate whether or not the host is charging), and `percentage` (a float to indicate the current battery percentage, never more than 100). |
| `typing` | | not | This is sent when somebody else starts typing in a conversation you're in, and you're being notified of it. The parameters for this are the same as `send-typing` |
| `new-message` | | not | This one corresponds to the function in the websocket to notify of new texts, and contains the same information as that. |

## Handling binary data
This websocket system has support for downloading attachments and getting profile pictures, both of which require sending binary data from the host to the clients. To do this, the host sends a series of base64-encoded chunks, which must be __combined and then decoded__ to create the binary data.

In a message that sends a base64-encoded chunk, the `data` object in the JSON message follows the following format:
```json
{
	"data": "dGhpcyBpcyBkYXRhIQ==", // the base64-encoded chunk
	"total": 1 // the total number of chunks that will be sent to the client
}
```

## Sending iMessages/texts
This system also supports sending iMessages/texts with attachments. How do we do that?

The client must send an initial socket message to tell the host that it is trying to send an iMessage/text. This `data` object of this message must be in the following format:
```json
{
	"chat": "+11231231234",
	"text": "This is the body of the text message!",
	"subject": "This is the subject of the text message!",
	"attachments": [
		{
			"id": "0129hd21h9d1209jd43n288bwlo9d",
			"size": 6,
			"filename": "song.mp3"
		},
		{
			"id": "9h3b10d129xmmdn1029hd891bf984",
			"size": 1,
			"filename": "info.txt"
		}
	]
}
```

__The Attachment Fields__
- `id`: A UUID for the attachment that will be used to identify it when sending data for the attachments later on
- `size`: How many base64-encoded chunks, which comprise the data of this attachment, will be sent to the host
- `filename`: The name of the file, without any parent directories

So after this initial message has been sent, the data that comprises the attachments must be sent to the host. To do this, a series of `attachment-data` messages are sent to the host. The `data` object of each `attachment-data` should look something like the following:
```json
{
	"attachment_id": "0129hd21h9d1209jd43n288bwlo9d",
	"message_id": "9u02hd0948bb29bcsoakwf9203hfi",
	"index": 2,
	"data": "g7g5AjgzMzNBQUFBurfDCg=="
}
```

__The Fields__
- `attachment_id`: The `id` of the attachment that this data is a part of, as specified in the `id` field of the attachment in the initial message
- `message_id`: The `id` of the message which the attachment is a part of
- `index`: The index of the chunk (0-indexed) with relation to how many chunks will be sent for this specific attachment
- `data`: The chunk itself.

These chunks are generated by:
1. Reading all the data from the file
2. Encoding the data into a single base64-encoded string
3. Splitting the string into its chunks based on the chunk size
4. Sending each chunk starting with the one comprising of the data at the beginning of the file

This is how the chunks are generated for data from the host to a client as well.
