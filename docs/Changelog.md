# Changelog
0.7.2 &rightarrow; 0.7.3
 - Added support in search API for returning conversations as well as texts
 - Added API for matching partial address when typing into new conversation box
 - Added support for showing group chat pictures
 - Removed unnecessary specifications in some API endpoints
 - Filtered hidden characters from texts with attachments
 - Set texts to send attachments first, and then subject/body
 - Web interface now correctly shows tapbacks relative to specific attachments
 - CLI Version outputs more information about how to connect to the server
 - Text send with only subject, no body, will now send with subject text in body field and no text in subject field
 - Fixed issue in web server framework that would prevent device from connecting if the host header was sent in lowercase
 - Fixed styling issue by notifications button on web interface

0.7.1 &rightarrow; 0.7.2
 - Added ability to run SMServer as a commandline app or daemon
 - Allowed sending of texts when subject field has text but body field is empty
 - Added option to not load web interface when running from command line
 - Links automatically open in new tabs as opposed to the current tab
 - App is compiled with minified css/html now
 - Cleaned up unnecessary code in web interface
 - Fixed warning about custom css file when no custom css file existed
 - Fixed issue that would occasionally cause crash if libSMServer was being run on the main thread
 - Fixed some logic in parsing of rich links to hopefully prevent more crashes
 - Fixed issue that prevented loading of data for requests that had special characters (e.g. carets, backticks) in their URL.
 - Fixed issue with sender names being offset by group chat events
 - Fixed various styling issues on mobile view; it should work just fine now

0.7.0 &rightarrow; 0.7.1
 - Added ability to delete a conversation from the web interface
 - Added ability to easily export TLS certificate (e.g. to add to client device store)
 - Web interface now works much better with mobile devices
 - Certificates are now generated automatically when you install the app from the `.deb` file, making the TLS connection more likely to be secure.
 - Websocket now attempts to reconnect when it disconnects from the host device (fixes issue of web interface not receiving updates after a while)
 - Fixed issue that was preventing group chats from showing when they were pinned
 - Fixed issue that prevented read receipts from showing in the web interface
 - Fixed issue that prevented names from showing in notifications in the web interface
 - Fixed issue that could possibly cause infinite recursion when trying to retrieve group chat's recipients
 - Fixed issue that would prevent server from returning error messages with bad status codes
 - Fixed issue that would prevent tapbacks with a value of 0 or 5 from being parsed by the server
 - Fixed issue that prevented users from clicking on the buttons at the bottom of the settings view
 - Fixed issue that showed the incorrect websocket address in the web interface alert

0.6.3 &rightarrow; 0.7.0
 - Re-added option to start the server upon app launch
 - Added option to automatically restart server without de-authenticating any clients automatically when the host device's network changes
 - Added security improvements to prevent brute-forcing of password
 - Added significantly more error checking for private API functions
 - Added API Documentation & Donation link in Settings
 - Added support for running SMServer behind a reverse proxy where it does not reside at the root directory & documentation for how to easily do so
 - Added special view for Digital Touch Messages and Handwritten Messages to show that they cannot be displayed in the web interface
 - Significantly improved typing indicator detection method
 - Significantly improved speed of photo list retrieval (about 2.5x as fast now)
 - Optimized attachment data retrieval
 - Optimized sending texts
 - Completely overhauled API responses
 - Fixed security issues to prevent SQL Injection
 - Fixed issue where typing indicators would never disappear
 - Fixed issue that would cause reactions to duplicate instead of replace old ones
 - Fixed issue where tapbacks would not be sent if message was 1001+ messages in
 - Fixed issue with marking conversations as read when it shouldn't
 - Fixed an issue where Custom CSS wouldn't be cleared
 - Fixed issue that could cause crashes when parsing special messages (e.g. handwritten, digital touch, etc)
 - Commented all my code much more :)

0.6.2 &rightarrow; 0.6.3
 - Added ability to delete texts in the web interface and through the API
 - Added ability to remove previously sent tapbacks
 - Added checking to ensure that the websocket and server are not run on the same port
 - Added support for GamePidgeon & Podcast Rich Links
 - Added extra error checking to prevent crashes on failed rich link parsings
 - Added offline usage of Font Awesome, for much faster loading times
 - Added information about which versions of libSMServer it supports
 - Optimized text retrieval for group chats
 - Removed unnecessary functions that run on load
 - Removed unnecessary functions from web interface
 - Fixed issue where tapbacks would not appear on the web interface because the message which they were reacting to had not been printed yet.
 - Fixed issue that would cause a time display to appear when it shouldn't
 - Fixed issues with placement of new text banner on pinned chats
 - Fixed small issues with display of body of texts

0.6.1 &rightarrow; 0.6.2
 - Added support for sending reactions in the web interface and through the API
 - Conversation profile pictures now show initials instead of default image if there's no profile for non-group chats
 - Modified attachments section of API to make it more robust
 - Significantly improved API documentation
 - Main view now shows device hostname when it can't get the IP Address
 - Removed unnecessary calls to API
 - Fixed issue where typing indicator would disappear when you sent a text
 - Fixed issue that would prevent document from loading if fontawesome script was sourced before inline javascript loaded in
 - Fixed issue where server would try to parse a digital touch message as a rich link and cause the app to crash

0.6.0 &rightarrow; 0.6.1
 - Added support for heic/heif images embedded in browser
 - May have actually fixed duplicating text issue
 - Fixed issue that would prevent loss of information when database was locked (mostly manifested in missing profile pictures)
 - Fixed issue that would offset sender names in `printListOfTexts` when `append` was false
 - Fixed font-weight display issues
 - Fixed issue that would incorrectly display texts that contained both attachments and a body or subject
 - Fixed issue that would prevent you from typing in the subject box
 - Fixed issue that would prevent sender name from appearing when you received a new text in a group chat

0.5.4 &rightarrow; 0.6.0
 - Made a new build script which makes it __much__ easier and faster to build SMServer from scratch
 - Added experimental option to combine conversations that belong to the same contact
 - Added Drag 'n' drop for attachments in the web interface
 - Added extra option in API to grab only texts to or from you in a certain conversation
 - Changed cert and hid new password to prevent people from stealing private key
 - Changed some glyphs in the web interface to look prettier
 - Web interface now checks to make sure there are more texts to be loaded before adding a 'more texts' button
 - Rewrote text-receiving backend to prevent race condition from duplicating texts in web interface
 - Downloaded attachments now have correct name and filetype
 - Web interface waits more accurately for attachments to fully upload before displaying the new text.
 - Fixed multiple issues with rich links displaying incorrectly or not at all
 - Fixed multiple issues with just-sent texts having incorrect attributes and thus causing weird graphical issues
 - Fixed issue with rich Links not showing reactions at all
 - Fixed issue with duplicate typing indicators appearing in web interface
 - Fixed issue with file descriptor not appearing in text description when file didn't have a specific mimetype.
 - Fixed issue with profile picture displays getting cut off
 - Fixed issue with sender names in group chats appearing above time displays
 - Fixed issues with unread indicator displays
 - Fixed many issues with sender and time display placement in group chats
 - Fixed issue with links redirecting to the wrong site if they didn't have `http(s)://` prefix
 - Fixed padding issue within texts on Firefox

0.5.3 &rightarrow; 0.5.4
 - Texts now have prettier bubble tails and no tails when sent close after each other
 - Texts also have proper spacing when sent far from each other to indicate the gaps in conversation
 - Added option in API to get chats from multiple addresses as if they were one conversation
 - Revamped settings view
 - Completely rewrote javascript that prints list of texts
 - Sending a text now creates a new time display when it's been more than an hour
 - Web interface is better at waiting for attachments to fully upload when sending a text before displaying the new text in the web interface
 - Web interface now only tries to mark a conversation as read when the window becomes focused if it was already unread
 - Unread indicators look much cleaner now
 - Texts wholly made of emojis now show without background and with a larger font
 - Fixed issue with z-indices on multiple overlayed reations
 - Fixed coloring issues with dark and light themes
 - Fixed spacing issues in text area
 - Fixed issue where order of texts would be messed up when reactions were inserted
 - Fixed issue where conversations would not appear as selected if they were not the top of the list when you sent a text to them
 - Fixed issue where textbox wouldn't properly resize when going from 2 lines to 1
 - Fixed issue where some memojis wouldn't load into the web interface
 - Fixed issue where sometimes chats without a contact would return an empty name, thus causing more issues
 - Fixed issue where sender name wouldn't appear in a group chat after a time display

0.5.2 &rightarrow; 0.5.3
 - Added inline audio displays
 - Images and attachments now appear more similar to stock iMessage
 - Reactions now appear correctly in group chats
 - Added functionality to select the "SMServer" title and de-select the currently selected conversation
 - Expanded chat preview text to 2 lines to be more like stock
 - Minor optimizations in html on web interface
 - Fixed issue where browser wouldn't correctly return if it was focused or not (which, in turn, fixes many other issues).
 - Fixed style issues with incorrect text spacing
 - Fixed issue where no new chats would load

0.5.1 &rightarrow; 0.5.2
 - Added support for inline video displays
 - Improved attachment displays in conversations
 - Fixed issue where chats would be treated as empty if they held a subject but no text
 - Significantly decreased html code footprint by combining all uses of the `fetch` api into one function
 - Fixed issue where chat would not be set as unread when window was not focused
 - Fixed issue where tapbacks would not disappear when they were removed
 - Fixed some small spacing issues

0.5.0 &rightarrow; 0.5.1
 - Added more customization options to search API
 - Added subject line option to web interface
 - Added icon to show if device is charging or not
 - Added partial functionality for search bar; doesn't show graphic display yet but redirects to JSON API page
 - Significantly improved documentation on API and websocket

0.4.3 &rightarrow; 0.5.0
 - Added full suport for iOS 14+
 - Added support for displaying pinned conversations
 - Added support for group chat names in `/requests?name` API
 - Added typing indicators when other party starts typing
 - Added support for sending typing indicators when you start typing (and settings to disable)
 - Added icons for music links
 - Added extensive documentation about how to use IMCore and ChatKit
 - App now dies in background if Server is off or backgrounding is disabled
 - Completely rewrote libSMServer for better performance and to be more future-proof
 - Improved logging system to significantly decrease code footprint
 - Improved quality of information on notifications for group chats
 - Significant optimizations in retrieving messages for group chats
 - Changed gatekeeper to take input as password
 - Fixed issues with notifications not showing in web interface
 - Fixed styling issues with fonts sometimes being too small or the incorrect color
 - Fixed issues with no conversations being marked as read
 - Fixed issue with blank texts appearing in web interface when `submit` hit while no text was set or attachments were selected
 - Fixed displays of smaller rich links
 - Fixed issue with some links not showing correct subtitles
 - Fixed issue where notifications would show no text if message was an attachment
 - Fixed issue with textbox overflowing messages area when typing a long message
 - Fixed issue with wrong conversation showing at top
 - Changed some glyphs in web interface

0.4.2 &rightarrow; 0.4.3
 - Fixed issue with new texts in group chats sometimes not showing immediately
 - Fixed issue where text box in web interface would not automatically resize after text was sent
 - Texts sent with images now show images immediately after being sent
 - Texts with no images and no text no longer appear to send in the web interface
 - Prevented conversations from being marked as read when webpage/conversation was not selected
 - Added option to manually (not) mark conversation as read through API

0.4.1 &rightarrow; 0.4.2
 - Rich Links look very nice now
 - Added support for battery percentage display
 - Fixed issue with notification button placement
 - Removed unnecessary background functions
 - Added extra error checking to prevent crashing when retrieving photo list
 - Added subject functionality to API (+ setting to toggle on/off)
 - Added support for viewing text subjects in web interface

0.4.0 &rightarrow; 0.4.1
 - Fixed up displays of Rich Links to look okay
 - Fixed issue with document not scrolling to bottom if all texts.date_read attributes === "0".
 - Added graphical display for reactions
 - Fixed issue with user's texts not displaying in group chats
 - Fixed issue with attachments & camera roll images not sending
 - Laid groundwork for sending reactions
 - Removed unnecessary restarting functions

0.3.8 &rightarrow; 0.4.0
 - Added extra UIBackgroundModes to app `Info.plist` to allow for truly unlimited background time (screen on/off)
 - Fixed countless styling issues on all themes
 - Rewrote light theme
 - Removed XMLHTTP requests from web interface
 - Fixed issue with not all chats being returned
 - (Probably) fixed issue with wrong chat button displaying on top of list in web interface

0.3.7 &rightarrow; 0.3.8
 - Fixed multiple issues with images from camera roll not displaying correctly
 - Fixed issue with camera roll favorite hearts not showing
 - Made css routes more dynamic
 - Added nord web interface theme
 - Fixed issue with marking conversations as read causing a crash
 - Added override for if phone doesn't recognize that it is connected to wifi
 - Almost fixed background issue (it won't crash in the background now, but still doesn't receive connections)
 - Improved web interface styling

0.3.6 &rightarrow; 0.3.7
 - Introduced general optimizations
 - Specifically optimized message and searching retrieval functions
 - Introduced viewing of read receipts
 - Fixed issues of plus signs being filtered out with query parsing
 - Removed postinst script
 - Decreased code footprint

0.3.5 &rightarrow; 0.3.6
 - Maybe fixed Cydia never-ending update issue?
 - Fixed styling issues with css grid noncompatible browsers
 - Fixed weird colors on light theme
 - Fixed crashing issue when marking conversation as read
 - Optimized chat retrieval SQL Query

0.3.4 &rightarrow; 0.3.5
 - Added support for marking conversations as read when viewed in web interface
 - Added support for relative date displays
 - Removed unnecessary functions
 - Added option to change how many photos display by default

0.3.3 &rightarrow; 0.3.4
 - Rewrote function to fetch texts to use sql joins instead of multiple queries; is significantly faster now
 - Almost now shows favorite images in interface
 - Fixed issue #14 (correctly parses `chat_id`s when retrieving messages)
 - Improved name retrieval to match SMS Sender IDs

0.3.2 &rightarrow; 0.3.3
 - Implemented better `chat_identifier` parsing to get name & image (see issue #9);
 - Enabled interacting with and selecting photos from the camera roll in the web interface
 - Remove unnecessary `parsePhoneNum()` function
 - Fixed issue with images failing to load
 - Introduced custom query parsing to allow for plus signs (or replacements like `%2B`) in the URL
 - Fixed issues with app crashing if a text was received before the server had started

0.3.1 &rightarrow; 0.3.2
 - Updated notifications to show more information
 - Fixed issue with favicon not showing
 - Fixed issue with app still requiring one to enter phone number
 - Updated Content-type of CSS pages to `text/css`
 - Fixed issue with new texts not displaying properly

0.3.0-1+debug &rightarrow; 0.3.1
 - Change api specifications for sending text
 - Removed requirement for inputting phone numbers
 - Added option to disable SSL/HTTPS
 - Better parsing of phone numbers for sending and checking texts

0.2.0-20+debug &rightarrow; 0.3.0-1+debug
 - Changed from GCDWebServer framework to my forked branch of Criollo
 - Implemented HTTPS
 - Implemented Desktop Notifications

0.2.0+debug19 &rightarrow; 0.2.0-20+debug
 - Changed how version numbers are named
 - Fixed issue with new text content not appearing on web interface conversation button if it was currently selected and top conversation
 - Web interface now shows attachment description in place of latest text content when latest text had no body but had an attachment
 - Removed deprecated functions
 - Added error checking for when the database fails to open
 - Updated method of opening database for possibly better compatibility

0.2.0+debug18 &rightarrow; 0.2.0+debug19
 - Improved phone number parsing
 - Improved bounds checking on arrays
 - Fixed minor css styling issues
 - Fixed issue with default chats/messages numbers being switched

0.2.0+debug17 &rightarrow; 0.2.0+debug18
 - Fixed issue with port not changing
 - Fixed issue with force unwrapping ip address
 - Now calls mryipc methods asynchronously so that app does not crash if they fail

0.2.0+debug15 &rightarrow; 0.2.0+debug17
 - Updated libmryipc.dylib to newest version
 - Set libmryipc.dylib to embed & sign, not neither.
 - Removed option to start server on load
 - Added new information about entering phone number
 - Added postinst script to recommend ldrestarting

0.2.0+debug14 &rightarrow; 0.2.0+debug15
 - Fixed dependency issues
 - Laid groundwork for showing camera roll images in browser interface

0.2.0+debug13 &rightarrow; 0.2.0+debug14
 - Added app icon on home screen
 - Added app icon to website

0.2.0+debug11 &rightarrow; 0.2.0+debug13
 - Fixed issue with styling of profile pictures and more texts button
 - Added easy access to light theme
 - Fixed styling issues on light theme
 - Removed server_ping setting

0.2.0+debug10 &rightarrow; 0.2.0+debug11
 - Fixed issue with new texts showing slowly
 - No longer updates when user sends text from another device
 - Fixed issue with new texts not appearing under conversation in chats list
 - Will have issues with new texts doubling if you use libsmserver < 0.2.0+debug20

0.2.0+debug9 &rightarrow; 0.2.0+debug10
- Fixed styling issues in web interface
- Added dynamic colors for sms vs imessages

0.2.0+debug8 &rightarrow; 0.2.0+debug9
- Added view for time & most recent text on chat list in web interface
- Refactored JS in web interface
- Fixed styling issues in web interface

0.2.0+debug7 &rightarrow; 0.2.0+debug8
- Changed profile & attachment request directory from `profile` and `attachments` to `data` (for both)
- Fixed issue with parsing attachment path
- Added support for retrieving a list of photos from photo library through API
- Added support for retrieving specific item from photo library through API

0.2.0+debug6 &rightarrow; 0.2.0+debug7
- Fixed issue with IPv6 address incorrectly showing
- Fixed issue with keyboard covering textfields when entering name
- Disabled long-polling by default on web interface; however, the code is still there and the call func is simply commented out. Easy to revert if you so wish
- Removed unnecessary messages reloading in web interface

0.2.0+debug5 &rightarrow; 0.2.0+debug6
- Added extra address handing to support more types of address formatting (e.g. with/without area code, country code, etc.)
- Added options to reset defaults
- Fixed bug with popup form sending even when 'cancel' was clicked instead of 'sent'
- Fixed small css styling issues

0.2.0+debug3 &rightarrow; 0.2.0+debug5
- Merged PR to fix extra line issue when sending text in web interface
- Merged PR to allow extra line creation on web interface with Shift+Enter
- Fixed spacing issue on main app view
- Optimized new text retrieval

0.2.0+debug2 &rightarrow; 0.2.0+debug3
- Added protections for unwanted webSocket connections
- Added settings for changing webSocket port
- Laid groundwork for battery/wifi stats on webpage
- Laid groundwork for new texts retrieval method customization

+debug80 &rightarrow; 0.2.0+debug2
- Added support for websockets (instant notification on web client when new texts are received on host)
- Fixed issue with defaults
- Fixed issue with unread conversations not showing

+debug77 &rightarrow; +debug80
- Added basic search API
- Fixed CSS issues in web interface

+debug76 &rightarrow; +debug77
- Added support within libsmserver for sending texts to previously nonexistent conversations
- Added support in web interface for sending texts to previously nonexistent conversations

+debug72 &rightarrow; +debug76
- Fixed issue with unc0ver devices being unable to send attachments or set custom CSS
- Fixed entitlements
- Implemented correct codesigning
- Removed postinst Script

0.1.0+debug68 &rightarrow; +debug72
- Changed upload/POST directory to /send instead of /uploads
- Whenever new texts arrive, the web interface conditionally reloads the Chats & only adds new texts instead of reloading all texts
- New texts appear as soon as they're sent in the web interface
- Probably a few small bug fixes
