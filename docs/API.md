# API

All non-image get requests are made to \<ip>:\<port>/requests. Requests for attachments are made to /attachments, and requests for profile images are made to /profile.

All post requests are directed to /uploads. In the latest version, this is the only way to send texts and/or attachments.

All request parameters require a value, but only some of the values are consequential. However, the app will not interpret a parameter as a parameter unless it has an accompanying value -- For example, to retrieve the list of conversations, one must make a request to /requests with a parameter of 'chat', but 'GET /requests?chat' will return nothing. Something like 'GET /requests?chat=0' will return the correct information.

Lastly, every time you see a plus ('+'), it needs to be replaced with a '%2B'. The server won't handle it correctly if it is a plus.

# `/requests` requests:

All requests to `/requests` return JSON information.

## `person`, `num`, `offset`

Retrieves the most recent $num messages to or from $person, offset by $offset.

- person: parameter is necessary, and value is consequential; must be chat_identifier of conversation. chat_identifier will be the email address or phone number of an individual, or 'chat' + $arbitrary_number for a group chat. chat_identifiers for group chats and email addresses must be exact, and phone numbers must be in the form of '+\<country code>\<area code>\<number>'. e.g. "+16378269173". Using parantheses or dashes will mess it up and return nothing.

- num: Parameter is not necessary, but value is consequential. The value of this parameter must be an integer, and will be the number of most recent messages that are returned from the app. If it is 0, it will return all the messages to or from this person, and if it is not specified, it will use the default number of messages on the app, which is currently 100 at the time of writing this.

- offset: Parameter is not necessary, but value is consequential. The value of this parameter must be an integer, and will be the offset off the messages that you want to receive. Say, for example, that you already retrieved the latest 100 messages, and wnated to receive the 100 before those, your offset would be 100. If unspecified, this value will default to 0.

Example queries:
- /requests?person=chat192370112946&num=500
- /requests?person=%2B15202621138
- /requests?person=email@icloud.com&num=50&offset=100
- /requests?person=person@gmail.com&offset=200

## `chat`, `num_chats`

Retrieves the latest $num_chats conversations

- chat: Parameter is necessary, and value is inconsequential. calling the parameter 'chat' simply specifies that you are asking for a list of the conversations on the device.
  
- num_chats: Parameter is not ncessary, and value is consequential. Value must be integer, and will specify how many conversations to get the information of. If unspecified, it will default to the device's default, which is, at the time of writing, 40. If it is 0, it will retrieve all chats.

Example queries:
- /requests?chat=0
- /requests?chat=0&num_chats=80

## `name`

Retrieves the contact name that accompanies chat_identifier $name

- name: Parameter is necessary, and value is consequential. Value must be the chat_identifier for the contact whose name you want. It can get the name if given an email address or phone number of an individual, but it cannot get a contact name for a group chat, since none such exist. Email must be given in the regular format, and phone number must be given in the format that the above 'person' section specifies.
  
Example queries:
- /requests?name=email@icloud.com
- /requests?name=%2B12761938272

## `send`, `to` -- THIS IS DEPRECATED IN THE LATEST VERSION.

**See the /uploads requests section for information on how to send a text now**

Sends a text/iMessage with a body of $send to $to

- send: Parameter is necessary, and value is consequential. This will be the body of the text, as a string. It requires no quotes to encapsulate it.

- to: Parameter is necessary, and value is consequential. This will be the recipient of the text, as a string. It requires a number or iMessage address, and cannot be a contact name.

Example queries:
- /requests?send=hello there!&to=%2B18479276635
- /requests?send=This is a test:))&to=email@icloud.com

## `check`

Simply checks if any new texts have arrived since either 'chats' or 'check' was last called. Will return an array of all conversation chat_identifiers with new texts, or an empty array if there are no new texts.

- check: Parameter is necessary, and value is inconsequential. Simply needs to be sent.

Example queries:
- /requests?check=0

# `/attachments` requests

Requests to this URL return image data, which is why they have to be sent to a different url from /requests

## `path`

This simply contains the path, excluding the attachments base URL ('/private/var/mobile/Library/SMS/Attachments/') of the attachment that is requested. It will only return image files, not any other format. So far, I have tested .gif, .png, and .jpeg, so I can only definitely confirm that it will work with those.

- path: Parameter is necessary, and value is consequential. Value needs to be a string containing the path of the file to get, minus the attachments base URL (mentioned above). This should (theoretically) work with the raw path, but just to be safe, please replace all forward slashes ('/') with period, underscore, then another period ('._.'), since that is more sure to parse correctly. It also filters out "../" to prevent LFI through this method.

Example queries:
- /attachments?path=00.\_.D8.\_.172BC809-BA7A-118D-18BCF0DEF._.IMG_9841.JPEG

# `/profile` requests

Requests to this URL return image data, which is why they have to be sent to a different URL from `/requests`

## `chat_id`

This contains the chat_id of the person that the request is trying to get the profile picture for. The chat_id should be in the same format as is specified in the `person` parameter above.

- chat_id: Parameter is necessary, and value is consequential. As stated above, it has a specified format that it should be in. 

Example queries:

- /profile?chat_id=%2B15204458272

# `/uploads` requests

Requests to this url are all sent using `POST`, are what are used to send texts and attachments. There are two arguments that can be sent to this, and it accepts multiple files as well. 

At least one file needs to be sent with each request, or the app crashes. This is simply due to the nature of the web framework that I use; I'm looking into getting it resolved. However, this file can be 0-size, `/dev/null`, `None` (in python), or whever you can use to signify a null file. If the file is one of these, or 0 bytes long, it will not be sent with the message. 

## Arguments

### text

This argument contains the body of the text you want to send, with the string 'text:' prepended onto it. For example, if you wanted to send 'Hello world!', you'd need to make this value of this argument be 'text:Hello world!'

This parameter is not necessary for every request

## chat

This argument contains the chat_identifier of the recipient, specified as in the `person` parameter above, with the string 'chat:' prepended onto it. For example, if I wanted to send a text to the phone number '+15001001000', the value for this parameter would need to be 'chat:+15001001000'. 

This parameter is necessary for every request, or else the app won't know who to send the text to. Also, plus signs should not be replaced with an escape character for these requests; they should stay plus signs.

## files

These need to be sent with the key 'attachments'. Other than that, just send them as normal. It does support sending multiple attachments, but (obviously), the more attachments you send, the longer it'll take, and the higher likelihood it'll fail along the way. 

## Example requests

### Python3 --

Sending a text with no attachments:
```python
from requests import post

vals = {'text': 'text:Hello world!', 'chat': 'chat:email@email.org'}
url = 'http://192.168.0.127:8741/uploads'

# The files is still included in the next line 'cause the app crashes if the files parameter is null/empty. No files are actually sent with this example, though.
post(url, files={'attachments': (None, '0')}, data=vals)
```

Sending an attachment with no text:
```python
from requests import post

vals = {'chat': 'chat:+13020499949'}
# file is a tuple, with the first val being the file name, the second being an open operator on the file, and the third being the mimetype.
file = ('image.jpeg', open('/home/user/Pictures/image.jpeg', 'rb'), 'image/jpeg')
files_values = {'attachments': file}
url = 'http://192.168.0.127:8741/uploads'

post(url, files=files_values, data=vals)
```

I've read that the value for `attachments` in `files_values` could be a list of tuples (a list of variables like `file`), but doing that has cause python to fail every time I've tried it, so I would recommend just iterating over each attachment and sending them individually.