# API

All plain text GET requests must be made to \<ip>:\<port>/requests (e.g. 192.168.0.127:8741/requests). Requests for binary data (whether it be pictures from the camera roll, profile pictures, or attachments) must be sent to /data. All post requests must be directed to /send.

All request parameters require a value, but only some of the values are consequential. However, the app will not interpret a parameter as a parameter unless it has an accompanying value -- For example, to retrieve the list of conversations, one must make a request to /requests with a parameter of 'chat', but 'GET /requests?chat' will return nothing. Something like 'GET /requests?chat=0' will return the correct information.

Requests to all of these API endpoints besides `/requests?password` will return nothing, unless you authenticate first, at `/requests?password`. Details are under the first subsection of the `/requests` requests

# `/requests` requests:

Most requests to `/requests` return information in the form of a JSON object, but some return plain text. Each group of query parameters specifies specifically iwhich type it returns.

The below sections detail the query key/value pairs that you can combine to get the information you need from the API.

## `password`

Authenticates with the server, so that you can retrieve more information from it. This returns plain text.

| Key | Required | Type | Description |
| - | - | - | - |
| password | Yes | String | If you pass in a different password from what is specified in the main view of the app for this key, it will return `false` as plain text. If it is the same password, it will return `true`, and you will be able to make further requests to other API endpoints. |

__Example queries:__
- /requests?password=toor

__Example return:__
```json
true
```

## `messages`, `num_messages`, `messages_offset`, `read_messages`, `messages_from`

Retrieves the most recent `num` messages to or from `person`, offset by `offset`. Returns a JSON object.

| Key | Required | Type | Description |
| - | - | - | - |
| messages | Yes | String | Must be chat_identifier of the conversation in question (either full phone number or email address for single person conversations, or `chat` followed by 16-20 integers for group chats). You can pass multiple chat_identifiers in for the value for this paramter, delimited by commas. |
| num_messages | No | Int | Will be number of the most recent messages that are returned for this conversation. If it is 0, it will return all the messages for this conversation, and if this key is not included in the query, it will return the default number of messages as is specified in the settings of the app. |
| messages_offset | No | Int | Will be the offset of messages that you want to receive. For example, if you already retrieved the latest 100 messages from this contact, you could set offset to 100 to get the next 100. If this key is not included in the query, offset will be 0. |
| read_messages | No | Bool | If value is `true`, this conversation will be marked as read on the device (or, if you pass in multiple values for `person`, all will be marked as read on the device). If this key is not included in the query, the conversation(s) will be marked as read only if you have the `Automatically mark as read` setting toggled on in the host device's settings. |
| messages_from | No | Int | This value must either be a 0, 1, or 2. If it is 0 or the key is not included in the query, it will return all messages to and from you in this conversation. If it is 1, if will return only texts that are from you, and if it is 2, it will return only texts that are to you. |

__Example queries:__
- /requests?messages=chat192370112946281736&num_messages=500
- /requests?messages=+15202621138&messages_from=2
- /requests?messages=email@icloud.com&num_messages=50&messages_offset=100&read_messages=false
- /requests?messages=person@gmail.com&messages_offset=200
- /requests?messages=email@icloud.com,+15202621138,person@gmail.com&num_messages=100&read_messages=true

__Example return:__
```json
{ "texts": [
	{
		"date" : 628153075801778048,
		"balloon_bundle_id" : "",
		"attachments" : [
			{
				"mime_type" : "text\/x-python-script",
				"filename" : "Attachments\/79\/09\/6B094BD9-430C-4B16-8810-6E45FF409F02\/clean_up.py"
			}
		],
		"cache_has_attachments" : true,
		"associated_message_type" : 0,
		"associated_message_guid" : "",
		"subject" : "",
		"is_from_me" : false,
		"service" : "iMessage",
		"date_read" : 628153077592212992,
		"guid" : "06F2E807-3607-4A97-A7E8-DC2BD051DEE9",
		"ROWID" : 176227,
		"text" : "￼Oh and here’s the python file you were asking for earlier"
	  },
	  {
		"is_from_me" : true,
		"date" : 628152957708999936,
		"subject" : "",
		"cache_has_attachments" : false,
		"associated_message_type" : 0,
		"guid" : "DBC43A7C-C8A9-42CB-838A-B574F7857FE3",
		"text" : "Hey! You should check out this song that I really like!",
		"balloon_bundle_id" : "",
		"ROWID" : 176224,
		"date_read" : 628152958118957952,
		"associated_message_guid" : "",
		"service" : "iMessage"
	  },
	  {
		"ROWID" : 176223,
		"attachments" : [
			{
				"filename" : "Attachments\/e8\/08\/88BB7DB7-D78D-4A8C-91EF-9934D2DFEF26\/AFC76D4C-2664-4555-BA7A-7DCA3B21A502.pluginPayloadAttachment",
				"mime_type" : ""
			},
			{
				"filename" : "Attachments\/cc\/12\/B46F7234-68A5-40B8-8B7C-66DE078B5A97\/10A2FC94-5732-453A-B4CE-040D275B2477.pluginPayloadAttachment",
				"mime_type" : ""
			}
		],
		"balloon_bundle_id" : "com.apple.messages.URLBalloonProvider",
		"link_title" : "Mover Awayer",
		"link_subtitle" : "Hobo Johnson · Song · 2019",
		"link_type" : "Website",
		"cache_has_attachments" : true,
		"service" : "iMessage",
		"subject" : "",
		"date_read" : 0,
		"associated_message_guid" : "",
		"date" : 628152944292000000,
		"associated_message_type" : 0,
		"is_from_me" : true,
		"guid" : "ED180020-AEF5-4E2F-9991-E5C227B648C3",
		"text" : "https:\/\/open.spotify.com\/track\/1yyIxshSIfW89EPTW0xkPH?si=D-S1TWN5S4CjjR65x9LBjg"
	}
]}
```

### Return fields description
| Key | Type | Description |
| - | - | - |
| date | Int | This is the date when the text was sent, in apple's own way of storing dates (to get a unix timestamp from it, do `(date / 1000000000) + 978307200`. |
| is_from_me | Bool | true if it is from you, false if it was sent to you. |
| date_read | Int | Theoretically the date at which the message was read by the other party. Is only something other than `0` if the text in question is a regular text (not a rich link, not a reaction, not just an attachment, etc), and either the other party sends read receipts or the text is to you. |
| guid | String |The guid of the text. Will become relevant in the case of reactions, which specify guid of the text which they are reacting to. |
| subject | String |The subject of the text, as opposed to the body. |
| ROWID | Int |The rowid of the text. Normally irrelevant, but can be useful for checking order of texts, if that is something that can help you. |
| cache_has_attachments | Bool | true if the text has any attachments, false if it has no attachments. |
| service | String | "iMessage" if the text is an iMessage, "SMS" if it is an SMS. |
| text | String | The body of the text, the most important part. |
| attachments | Array | This is an array of the attachments associated with this text. `filename` is the path of this attachment in the host device's filesystem, minus the prefix of `/private/var/mobile/Library/SMS/`. `mime_type` contains the mime type of this attachment. |
| balloon_bundle_id | String | Generally empty, but is something for special types of messages. This is "com.apple.messages.URLBalloonProvider" for rich links, and "com.apple.DigitalTouchBalloonProvder" for digital touch messages. |
| link_type | String |Only exists on rich link messages. Specifies what type of content the link leads to, generally. For most spotify links, for example, it is "Music", and for youtube videos, it is "Video". Generally is just "Website", though. |
| link_title | String |The title of the link, that generally shows up right underneath the rich link preview image. |
| link_subtitle | String |The subtitle of the link, that generally shows up right underneath the title of the rich link. |


## `chats`, `chats_offset`

Retrieves the latest `num_chats` conversations. Returns a JSON object.

| Key | Required | Type | Description |
| - | - | - | - |
| chats | Yes | Int | Specifies how many conversations to the information of. If there is no value for this key in the query, it will default to the device's default, which is specified in the settings of the host app.
| chats_offset | No | Int | Specifies the offset of the list of conversations that you want to retrieve. For example, if you have already retrieved the first 100 conversations, and would like to retrieve the next 100, you would set the value for this key to `100`, and that would get you what you want. If this key is not included in the query, it will default to 0 for the offset.

__Example queries:__
- /requests?chats
- /requests?chats=40
- /requests?chats&chats_offset=160

__Example return:__
```json
{ "chats": [
	{
		"has_unread" : false,
		"chat_identifier" : "+11231231234",
		"pinned" : false,
		"latest_text" : "Hey there friend",
		"display_name" : "John Smith",
		"time_marker" : 625632825876320896,
		"relative_time" : "1 month ago",
		"addresses" : "+11231231234,email@email.com"
	}
]}
```

__Return fields description__
| Key | Type | Description |
| - | - | - |
| has_unread | Bool | If it is true, this conversation currently has at least one unread message. Else, it has none. |
| chat_identifier | String | The chat_identifier of the conversation. This is the value that you would pass in for the `person` key in the queries listed first.
| pinned | Bool | If it is true, the conversation is pinned in the iMessages app on the host device. Else, it is not. |
| latest_text | String | The body of the latest text (iMessage or SMS) sent to or from this conversation. |
| display_name | String | This is the name that shows up in the iMessages app for this conversation. If the conversation is just with one person, it will contain their first and last name. If it is with a group chat that has a name, it will show that group chat's name, and if it is with a group chat that has no name, it will be a list of the first + last names of everyone in the group chat (e.g. "John Smith, Jane Doe, Bob Johnson").
| time_marker | Int | This is the date at which the latest text was sent or received in this conversation, also in apple's own time  format. To get a unix timestamp, do `(time_marker / 1000000000) + 978307200`. |
| relative_time | String | A simple description of about when the last text was sent, somewhat similar to how it is shown in the iMessages app (but not exactly).
| addresses | String | If the `Merge contact addresses` option is turned on in the host device's settings, this field will contain all of the email addresses and phone numbers that are associated with the contact who holds this `chat_identifier`. |

## `name`
Retrieves the contact name that accompanies chat_identifier `name`. Returns plain text.

| Key | Required | Type | Description |
| - | - | - | - |
| name | Yes | String | Value for this key must be the chat_identifier of the conversation which name you want. This will get you the `display_name` of the conversation, as described above. If there is no contact associated with the chat_identifier you passed in, it will simply give you back the value that you passed in. |

__Example queries:__
- /requests?name=email@icloud.com
- /requests?name=+12761938272
- /requests?name=chat193827462058278283

__Example return:__
```json
John Smith
```

## `search`, `search_case`, `search_gaps`, `search_group`
This searches for the term `search` in all your texts. `case_sensitive`, `bridge_gaps`, and `group_by` are customization options. Returns a JSON object.

| Key | Required | Type | Description |
| - | - | - | - |
| search | Yes | String | This is the term you want to search for. Does not have to be surrounded by quotes. |
| search_case | No | Bool | Either "true" or "false". If "true", the matches must match case-sensitive. Else, the matches are all case-insensitive. |
| search_gaps | No | Bool | If this is "true", all spaces are replaced by wildcard characters so that the spaces don't have to match exactly. For example, if you searched for "hello friend" and set `bridge_gaps` to `true`, this search would also match a text that contained only "hello there friend". |
| search_group | No | String | If you pass in `time` or don't include this key in the query, it will return all the search matches as a list of texts, with the most recent one first. If you pass in anything else, it will group them by conversation (return a list of conversations, each containing a list of texts which match this query). |

__Example queries:__
- /requests?search=hello%20world&search_case=true&search_gaps=false
- /requests?search=hello_there&search_group=conversation

__Example return:__

With `group_by=time`

```json
{ "matches": [
  {
    "chat_identifier" : "+11231231234",
    "text" : "Hey there, friend",
    "cache_has_attachments" : false,
    "display_name" : "John Smith",
    "service" : "SMS",
    "date" : 627285343072013056,
    "ROWID" : 175309
  },
]}
```

With `group_by=chat`

```json
{ "matches": {
	"+11231231234" : [
		{
			"chat_identifier" : "+11231231234",
			"text" : "Hey there, friend",
			"cache_has_attachments" : false,
			"display_name" : "John Smith",
			"service" : "SMS",
			"date" : 627285343072013056,
			"ROWID" : 175309
		},
	]
}}
```

See above, in the `person` query return value descriptions for how to understand these return values

## `photos`, `photos_offset`, `photos_recent`

If `photos_recent == "true"`, this retrieves a list of information about the most recent `photos` (`photos` is an integer) photos, offset by `photos_offset` (`photos_offset` is also an integer). If `photos_recent` != "true", this retrieves a list of the oldest `photos` photos, offset by `photos_offset`. Returns a JSON object.

| Key | Required | Type | Description |
| - | - | - | - |
| photos | Yes | Int | Must be the number of photos that you want to receive information about, and if it is not an integer or no value is passed in for this key, it will be changed to the default number of photos (which is available to set in the settings of the host device). Setting this to 0 will retrieve 0 photos, and the only way to retrieve all photos would be to set this value to an absurdly large number that is higher than or equal to the number of photos that you have on the host device.
| photos_offset | No | Int | Must be the offset for the list of photos that you want to retrieve. For example, if you had already retrieved the most recent 100 photos, but want to retrieve info about the next 100, you would set offset to 100 (and photos to 100 as well). If this is not an integer or the key is not included in the query, it will default to 0.
| photos_recent | No | Bool | If it is "true" or this key is not included in the query, it will retrieve the most recent photos. Else, it will retrieve the oldest photos. |

__Example queries:__
- /requests?photos=100
- /requests?photos=40&photos_offset=120&photos_recent=false
- /requests?photos=1&photos_recent=false

__Example return:__
```json
{ "photos": [
  {
    "is_favorite" : false,
    "URL" : "DCIM\/100APPLE\/IMG_0244.JPG"
  },
  {
    "is_favorite" : true,
    "URL" : "DCIM\/100APPLE\/IMG_0243.JPG"
  }
]}
```

__Return fields Description:__
| Key | Type | Description |
| - | - | - |
| is_favorite | Bool | Tells whether or not the photo is favorited on the host device. |
| URL | String | This value holds the URL of the photo on the host device, minus the prefix of `/var/mobile/Media/` |

# `/data` requests

Requests to this URL return image data, which is why they have to be sent to a different url from /requests

## `path`

You should use this to get attachments from a conversation; it will simply return the data of a file at a certain URL.

| Key | Required | Type | Description |
| - | - | - | - |
| path | Yes | String | Should contain the path of the file to get, minus the attachment prefix URL (`/private/var/mobile/Library/SMS/Attachments/`). The server also filters out all instances of `../` to prevent LFI. |

__Example queries:__
- /data?path=00/D8/172BC809-BA7A-118D-18BCF0DEF/IMG_9841.JPEG

## `chat_id`

This query key can be used to get the profile picture for a certain chat.

| Key | Required | Type | Description |
| - | - | - | - |
| chat_id | Yes | String | This should contain the chat_id of the conversation for which you want the profile picture. It should be in the same format as the `person` parameter above. If there is no profile picture associated with the specified `chat_id`, it will return a 404. If you pass in `default` for this parameter or give it a `chat_id` that corresponds with a group chat, it will return a generic profile picture. |

__Example queries:__
- /data?chat_id=+15204458272

## `photo`

This will return an image from the image library, specifically from the `/var/mobile/Media/` folder. It it protected against LFI, just like `path` above. It will return whatever is at that address, whether it be a video or image.

| Key | Required | Type | Description |
| - | - | - | - |
| photo | Yes | String | Should be the raw path of the photo in the filesystem, excluding the prefix of `/var/mobile/Media`. |

__Example queries:__
- /data?photo=DCIM/109APPLE/IMG_8273.JPEG

# `/send` requests

Requests to `/send` actually enact change, as opposed to requests to `/requests`, which only retrieve information. At the time of writing this, you can send texts and tapbacks and delete texts and conversations with this section of the API, so be very careful you are certain of what you're doing before you do it. Your requests here could have major consequences if you mess something up. If you would like to be certain, you can always back up your `SMS.db` database on your phone before attempting anything with the API.

Requests to this url are all sent using both `POST` and `GET` (for different purposes) as opposed to just `GET`, for `/requests`. As with all other requests (besides to the gatekeeper), you must authenticate before sending any requests to this url, or else nothing will happen.

## `GET` requests

All of the `GET` requests to `/send` return only status codes, and no text in the message body. They generally return either:
 - `200`, meaning that everything has gone correctly,
 - `400`, meaning that something in the URL Query parameter was incorrect,
 - `403`, meaning that you have yet to authenticate with the server, so the request was not processed, or
 - `503`, meaning that an internal error occured and the request could not be completed as requested. Feel free to retry if you run into a 503 code.

### `tapback`, `tap_guid`, `tap_in_chat`, `remove_tap`

Sends a tapback for the message with `tap_guid`, in `tap_in_chat` chat.

| Key | Required | Type | Description |
| - | - | - | - |
| tapback | Yes | Int | This should be an int, describing the reaction to send. "Heart" is 0, "Thumbs up" is 1, "Thumbs down" is 2, "Haha" is 3, "Emphasis" is 4, and "Question" is 5. If this number is greater than 5 or less than 0 or is not an int, the tapback will fail to send.
| tap_guid | Yes | String | Must be the guid of the message that the tapback is being sent for. |
| tap_in_chat | Yes | String | Must be the chat_identifier of the conversation in which the tapback is being sent. |
| remove_tap | No | String | Must be either true or false. If it is neither, it defaults to false. When this is `true`, it removes the tapback with the above attributes instead of adding it. |

__Example queries:__
- /send?tapback=1&tap_guid=0AD2418E-19E4-47B1-9380-DB8E0A90B30C&tap_in_chat=+11231231234
- /send?tapback=0&tap_guid=D11C0838-02F0-4917-AE38-AC7628E1DBCC&tap_in_chat=email@email.com&remove_tap=true

## `delete_chat`, `delete_text`

This will delete either a conversation or a single message. If the content of the `delete_text` value has a length greater than 0, it will delete the text with the guid of the value in `delete_text`. Otherwise, it will delete the conversation with the `chat_identifier` which is in the value of `delete_chat`. If there is something incorrect about the query, it will return a warning message instead of "true". Returns plain text.

| Key | Required | Type | Description |
| - | - | - | - |
| delete_chat | Yes | String | Must be the `chat_identifier` of the conversation to be deleted, or the `chat_identifier` of the conversation in which the message which is to be deleted resides. Either way, it must be included. |
| delete_text | No | String | Must be the `guid` of the message which is to be deleted. If this value is not included, or its length is 0, the conversation which has the `chat_identifier` that is included in the `delete_chat` parameter of this request will be deleted. |

__Example queries:__
- /send?delete_chat=+11231231234&delete_text=473EED50-D302-473C-920B-3353A43C6B75
- /send?delete_chat=email@email.org

## `POST` requests

The `POST` requests are sent as multipart/form-data forms (as opposed to application/x-www-form-urlencoded), and are only used to send texts through the app. In practice, it's generally safe to not encode anything in requests to this url, but only percent encodings (e.g. using `%20` for spaces and `%2B` for plus signs) will be accepted and parsed correctly. For example, replacing spaces with plus signs (as is specified in [RFC1738](https://www.ietf.org/rfc/rfc1738.txt) will cause the string to be used raw, and none of the plus signs will be replaced with spaces.

There are five key/value pairs that can be sent to this URL, and it accepts multiple files as well. For the text to actually send, you must include the chat, and then either at least 1 file, or something that is more than 0 characters for one of the other parameters.

### Parameter key/value pairs

| Key | Required | Type | Description |
| - | - | - | - |
| text | No | String | Should include the body of the text you want to send. |
| subject | No | String | Should include the subject of the text you want to send. For it to actually be included with the text, it must be at least one character long (not just ""); if it is 0-length or you simply don't include this key/value pair, the text will still be sent but it won't have a subject. |
| chat | Yes | String | Should be the chat_id of the conversation which you want to send this text to. Should be formatted in the same format as the `person` parameter above, under the `/requests` requests subsection.
| photos | No | String | This should contain a list of the path of the photos (from the camera roll) that you want to send with this text, dlimited by colons and each without the `/var/mobile/Media/` prefix of their path. For example, if you wanted to send three photos with this text, this parameter may look something like `DCIM/100APPLE/IMG_0001.JPG:DCIM/100APPLE/IMG_0002.JPG:DCIM/100APPLE/IMG_0003.JPG`. |
| attachments | No | Files | All the files that you send with a text must be attached to the key `attachments`, and you can send multiple files. I have managed to send up to 45mb of files at a time, but anything upwards of ~75mb at a time will fail (in my experience).

## Example requests to send a text

### Python3

Sending a text with a subject and no attachments:
```python
from requests import post

# It's safest to explicitly encode spaces as `%20`, since python replaces all spaces with plus signs, 
# which are not filtered out. If your scripting language does not replace spaces with plus signs,
# you need not manually encode them.
vals = {'text': 'Hello%20world!', 'subject': 'This%20is%20a%20test', 'chat': 'email@email.org'}
url = 'https://192.168.0.127:8741/send'

# The server's certificate is self-signed, so make to include the `verify` parameter in the request
post(url, data=vals, verify=False)
```

Sending an attachment with no text:
```python
from requests import post

vals = {'chat': '+11231231234'}

# file is a tuple, with the first val being the file name, the second being an open operator on the file, and the third being the mimetype.
file = ('image.jpeg', open('/home/user/Pictures/image.jpeg', 'rb'), 'image/jpeg')
files_values = {'attachments': file}
url = 'https://192.168.0.127:8741/send'

# The server's certificate is self-signed, so make to include the `verify` parameter in the request
post(url, files=files_values, data=vals, verify=False)
```
I've read that the value for `attachments` in `files_values` could be a list of tuples (a list of variables like `file` in the example above), but doing that has caused python to fail to post the request every time I've tried it, so I would recommend just iterating over each attachment and sending them individually.

Sending a text with a subject and a photo from the camera roll:
```python
from requests import post

# Set the values
vals = {'chat': '+11231231234', 'text': 'This%20is%20the%20body!', 
	'subject': 'This%20is%20the%20subject!', 'photos': 'DCIM/100APPLE/IMG_0001.JPG'}
url = 'https://192.168.0.127:8741/send'

# Make the request
post(url, data=vals, verify=False)
```

### Curl
Sending a text with a body, subject, and attachments with curl
```bash
curl -k -F "attachments=@/home/user/Pictures/image1.png" \
        -F "attachments=@/home/user/Pictures/image2.png" \
        -F "text=Hello there" \
        -F "subject=Subject" \
        -F "chat=+11231231234" \
        "https://192.168.0.127:8741/send"
```
