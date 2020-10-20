# API

All non-image get requests are made to \<ip>:\<port>/requests. Requests for attachments are made to /attachments, and requests for profile images are made to /profile.

All post requests are directed to /send. In the latest version, this is the only way to send texts and/or attachments.

All request parameters require a value, but only some of the values are consequential. However, the app will not interpret a parameter as a parameter unless it has an accompanying value -- For example, to retrieve the list of conversations, one must make a request to /requests with a parameter of 'chat', but 'GET /requests?chat' will return nothing. Something like 'GET /requests?chat=0' will return the correct information.

# `/requests` requests:

All requests to `/requests` return JSON information.

## `person`, `num`, `offset`

Retrieves the most recent $num messages to or from $person, offset by $offset.

- person: parameter is necessary, and value is consequential; must be chat_identifier of conversation. chat_identifier will be the email address or phone number of an individual, or 'chat' + $arbitrary_number for a group chat. chat_identifiers for group chats and email addresses must be exact, and phone numbers must be in the form of '+\<country code>\<area code>\<number>'. e.g. "+16378269173". Using parentheses or dashes will mess it up and return nothing.

- num: Parameter is not necessary, but value is consequential. The value of this parameter must be an integer, and will be the number of most recent messages that are returned from the app. If it is 0, it will return all the messages to or from this person, and if it is not specified, it will use the default number of messages on the app, which is currently 100 at the time of writing this.

- offset: Parameter is not necessary, but value is consequential. The value of this parameter must be an integer, and will be the offset off the messages that you want to receive. Say, for example, that you already retrieved the latest 100 messages, and wanted to receive the 100 before those, your offset would be 100. If unspecified, this value will default to 0.

- read: Parameter is not necessary, but value is consequential. The value of this parameter must be a string, either `true` or `false`. If it is `true`, or the parameter is not included but the 'mark conversation as read when viewed on web interface' option is checked in the app's settings, the conversation whose messages are being requested will be marked as read on the host device. 

Example queries:
- /requests?person=chat192370112946&num=500
- /requests?person=+15202621138
- /requests?person=email@icloud.com&num=50&offset=100&read=false
- /requests?person=person@gmail.com&offset=200

## `chat`, `num_chats`

Retrieves the latest $num_chats conversations

- chat: Parameter is necessary, and value is inconsequential. Calling the parameter 'chat' simply specifies that you are asking for a list of the conversations on the device.
  
- num_chats: Parameter is not necessary, and value is consequential. Value must be integer, and will specify how many conversations to get the information of. If unspecified, it will default to the device's default, which is, at the time of writing, 40. If it is 0, it will retrieve all chats.

Example queries:
- /requests?chat=0
- /requests?chat=0&num_chats=80

## `name`

Retrieves the contact name that accompanies chat_identifier $name

- name: Parameter is necessary, and value is consequential. Value must be the chat_identifier for the contact whose name you want. It can get the name if given an email address or phone number of an individual, but it cannot get a contact name for a group chat, since none such exist. Email must be given in the regular format, and phone number must be given in the format that the above 'person' section specifies.
  
Example queries:
- /requests?name=email@icloud.com
- /requests?name=+12761938272

## `search`, `case_sensitive`, `bridge_gaps`

This searches for the term $search in all your texts. `case_sensitive` and `bridge_gaps` are customization options.

- search: Parameter is necessary, and value is consequential. This must be the term you want to search for. Does not have to be surrounded by quotes. Case sensitivity is determined by the `case_sensitive` parameter.
- case_sensitive: Parameter is not necessary, and value is consequential; default is false. This determines whether or not you want the search to be case sensitive; a value of `true` make it sensitive, and `false` makes it insensitive
- bridge_gaps: Parameter is not necessary, and value is consequential; default is true. If set to true, this replaces all spaces with wildcard characters, allowing for the search term to be spaced out over a text. A value of `true` makes it true, and `false` makes it false

Example queries:
- /requests?search=hello%20world&case_sensitive=true&bridge_gaps=false
- /requests?search=hello_there

## `photos`, `offset`, `most_recent`

if most_recent == "true", this retrieves a list of information about the most recent $photos ($photos is an integer) photos, offset by \$offset ($offset is also an integer). If most_recent != "true", this retrieves a list of the oldest $photos photos, offset by $offset.

- photos: Parameter is necessary, and value is consequential. This must be the number of photos that you want to receive information about, and if it is not an integer, it will be changed to the default number of photos (which is available to set in the settings of the app). Setting this to 0 will retrieve 0 photos, and the only way to retrieve all photos would be to set to $photos to an absurdly large number, such as 999999999. 
- offset: Parameter is not necessary, and value is consequential. This must be the offset for the list of photos that you want to retrieve. For example, if you already retrieved the most recent 100 photos, but want to retrieve info about the next 100 images, you would set offset to 100, and photos to 100 as well. This must be an integer, or else it will default to 0. 
- most_recent: Parameter is not necessary, and value is consequential. This must be either "true" or "false". If it is neither, it will default to true. Setting this to false will query the oldest pictures first, and setting it to true or not settings it at all will retrieve the most recent images first.

Example queries:
- /requests?photos=100
- /requests?photos=40&offset=120&most_recent=false
- /requests?photos=1&most_recent=false

# `/data` requests

Requests to this URL return image data, which is why they have to be sent to a different url from /requests

## `path`

This simply contains the path, excluding the attachments base URL ('/private/var/mobile/Library/SMS/Attachments/') of the attachment that is requested. It should return all attachment types, and will be handled by the browser just like any other file of its type.

- path: Parameter is necessary, and value is consequential. Value needs to be a string containing the path of the file to get, minus the attachments base URL (mentioned above). It also filters out "../" to prevent LFI through this method, so any instances of '../' in the path will be filtered out.

Example queries:
- /data?path=00/D8/172BC809-BA7A-118D-18BCF0DEF/IMG_9841.JPEG

## `chat_id`

This contains the chat_id of the person that the request is trying to get the profile picture for. The chat_id should be in the same format as is specified in the `person` parameter above.

- chat_id: Parameter is necessary, and value is consequential. As stated above, it has a specified format that it should be in. 

Example queries:

- /data?chat_id=+15204458272

## `photo`

This will return an image from the image library, specifically from the `/var/mobile/Media/` folder. It it protected against LFI, just like `path` above. It will return whatever is at that address, whether it be a video or image.

- photo: Parameter is necessary, and value is consequential. It should be the raw path, excluding the prefix of `/var/mobile/Media/`, of the image that you want to retrieve.

Example queries:

- /data?photo=DCIM/109APPLE/IMG_8273.JPEG

# `/send` requests

Requests to this url are all sent using `POST`, are what are used to send texts and attachments. There are two arguments that can be sent to this, and it accepts multiple files as well. 

As with all other requests (besides to the gatekeeper), you must authenticate before sending any requests to this url, or else nothing will happen.

## Arguments

## text

This argument contains the body of the text you want to send. This parameter is not necessary for every request

## chat

This argument contains the chat_identifier of the recipient, specified as in the `person` parameter above. Before 0.1.0+debug77, these could only be an address for an existing conversation, but with version 0.1.0+debug77 of SMServer (and 0.1.0-85+debug of libsmserver), you can post requests for new conversations; new conversations do not yet support attachments, though.

This parameter is necessary for every request, or else the app won't know who to send the text to. Also, plus signs should not be replaced with an escape character for these requests; they should stay plus signs.

## files

These need to be sent with the key 'attachments'. Other than that, just send them as normal. It does support sending multiple attachments, but (obviously), the more attachments you send, the longer it'll take, and the higher likelihood it'll fail along the way. 

## Example requests

### Python3 &mdash;

Sending a text with no attachments:
```python
from requests import post

# It's safest to explicitly replace spaces with `%20`, since (last time I tested) python replaced 
# all spaces with plus signs, which are not filtered out.
vals = {'text': 'Hello%20world!', 'subject': 'This%20is%20a%20test', 'chat': 'email@email.org'}
url = 'http://192.168.0.127:8741/send'

# The server's certificate is self-signed, so make to include the `verify` parameter in the request
post(url, data=vals, verify=False)
```

Sending an attachment with no text:
```python
from requests import post

vals = {'chat': '+13020499949'}

# file is a tuple, with the first val being the file name, the second being an open operator on the file, and the third being the mimetype.
file = ('image.jpeg', open('/home/user/Pictures/image.jpeg', 'rb'), 'image/jpeg')
files_values = {'attachments': file}
url = 'http://192.168.0.127:8741/send'

# The server's certificate is self-signed, so make to include the `verify` parameter in the request
post(url, files=files_values, data=vals, verify=False)
```

To be able to send a text with a subject, the `subject` variable in `vals` must not be empty, and you must have the option `Enable subject functionality` toggled on in the app

I've read that the value for `attachments` in `files_values` could be a list of tuples (a list of variables like `file`), but doing that has caused python to fail every time I've tried it, so I would recommend just iterating over each attachment and sending them individually. 
