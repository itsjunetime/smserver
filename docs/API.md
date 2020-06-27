# API

All non-image requests and profile image requests are made to \<ip>:\<port>/requests. Requests for attachment images are made to /attachments.

All request parameters require a value, but only some of the values are consequential. However, the app will not interpret a parameter as a parameter unless it has an accompanying value -- For example, to retrieve the list of conversations, one must make a request to /requests with a parameter of 'chat', but 'GET /requests?chat' will return nothing. Something like 'GET /requests?chat=0' will return the correct information.

# /requests requests:

All requests to /requests (besides 'image') return JSON information. Image returns a base64-encoded image string.

### person, num, offset

Retrieves the most recent $num messages to or from $person, offset by $offset.

- person: parameter is necessary, and value is consequential; must be chat_identifier of conversation. chat_id will be the email address or phone number of an individual, or 'chat' + $arbitrary_number for a group chat. chat_identifiers for group chats and email addresses must be exact, and phone numbers must be in the form of '+\<country code>
\<area code>\<number>'. e.g. "+16378269173". Using parantheses or dashes will mess it up and return nothing.

- num: Parameter is not necessary, but value is consequential. The value of this parameter must be an integer, and will be the number of most recent messages that are returned from the app. If it is 0, it will return all the messages to or from this person, and if it is not specified, it will use the default number of messages on the app, which is currently 100 at the time of writing this.

- offset: Parameter is not necessary, but value is consequential. The value of this parameter must be an integer, and will be the offset off the messages that you want to receive. Say, for example, that you already retrieved the latest 100 messages, and wnated to receive the 100 before those, your offset would be 100. If unspecified, this value will default to 0.

Example queries:
- /requests?person=chat192370112946&num=500
- /requests?person=+15202621138
- /requests?person=email@icloud.com&num=50&offset=100
- /requests?person=person@gmail.com&offset=200

### chat, num_chats

Retrieves the latest $num_chats conversations

- chat: Parameter is necessary, and value is inconsequential. calling the parameter 'chat' simply specifies that you are asking for a list of the conversations on the device.
  
- num_chats: Parameter is not ncessary, and value is consequential. Value must be integer, and will specify how many conversations to get the information of. If unspecified, it will default to the device's default, which is, at the time of writing, 40. If it is 0, it will retrieve all chats.

Example queries:
- /requests?chat=0
- /requests?chat=0&num_chats=80

## name

Retrieves the contact name that accompanies chat_identifier $name

- name: Parameter is necessary, and value is consequential. Value must be the chat_identifier for the contact whose name you want. It can get the name if given an email address or phone number of an individual, but it cannot get a contact name for a group chat, since none such exist. Email must be given in the regular format, and phone number must be given in the format that the above 'person' section specifies.
  
Example queries:
- /requests?name=email@icloud.com
- /requests?name=+12761938272

## image

Retrieves the profile image that accompanies chat_identifier $image as a base64-encoded string. Soon, this will be shifted to a non-/requests URL, so that it can return pure image data, as opposed to encoded text (image data is parsed much quicker)

- image: Parameter is necessary, and value is consequential. Value must be the chat_identifier for the contact whose image you want. Referense the 'name' field above on how to request it. 
  
Example queries:
- /requests?image=email@icloud.com
- /requests?image=+12761938272

## send, to

Sends a text/iMessage with a body of $send to $to

- send: Parameter is necessary, and value is consequential. This will be the body of the text, as a string. It requires no quotes to encapsulate it.

- to: Parameter is necessary, and value is consequential. This will be the recipient of the text, as a string. It requires a number or iMessage address, and cannot be a contact name.

Example queries:
- /requests?send=hello there!&to=+18479276635
- /requests?send=This is a test:))&to=email@icloud.com

## check

Simply checks if any new texts have arrived since either 'chats' or 'check' was last called. Will return an array of all conversation chat_identifiers with new texts, or an empty array if there are no new texts.

- check: Parameter is necessary, and value is inconsequential. Simply needs to be sent.

Example queries:
- /requests?check=0

# /attachments requests

Requests to this URL return image data, which is why they have to be sent to a different url from the rest of the requests. 

## path

This simply contains the path, excluding the attachments base URL ('/private/var/mobile/Library/SMS/Attachments/') of the attachment that is requested. It will only return image files, not any other format. So far, I have tested .gif, .png, and .jpeg, so I can only definitely confirm that it will work with those.

-path: Parameter is necessary, and value is consequential. Value needs to be a string containing the path of the file to get, minus the attachments base URL (mentioned above). This should (theoretically) work with the raw path, but just to be safe, please replace all forward slashes ('/') with period, underscore, then another period ('._.'), since that is more sure to parse correctly. 

Example queries:
- /attachments?path=00.\_.D8.\_.172BC809-BA7A-118D-18BCF0DEF._.IMG_9841.JPEG