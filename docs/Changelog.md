# Changelog

0.5.0 -> 0.5.1
 - Added more customization options to search API
 - Added subject line option to web interface

0.4.3 -> 0.5.0
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

0.4.2 -> 0.4.3
 - Fixed issue with new texts in group chats sometimes not showing immediately
 - Fixed issue where text box in web interface would not automatically resize after text was sent
 - Texts sent with images now show images immediately after being sent
 - Texts with no images and no text no longer appear to send in the web interface
 - Prevented conversations from being marked as read when webpage/conversation was not selected
 - Added option to manually (not) mark conversation as read through API

0.4.1 -> 0.4.2
 - Rich Links look very nice now
 - Added support for battery percentage display
 - Fixed issue with notification button placement
 - Removed unnecessary background functions
 - Added extra error checking to prevent crashing when retrieving photo list
 - Added subject functionality to API (+ setting to toggle on/off)
 - Added support for viewing text subjects in web interface 

0.4.0 -> 0.4.1
 - Fixed up displays of Rich Links to look okay
 - Fixed issue with document not scrolling to bottom if all texts.date_read attributes === "0".
 - Added graphical display for reactions
 - Fixed issue with user's texts not displaying in group chats
 - Fixed issue with attachments & camera roll images not sending
 - Laid groundwork for sending reactions
 - Removed unnecessary restarting functions

0.3.8 -> 0.4.0
 - Added extra UIBackgroundModes to app `Info.plist` to allow for truly unlimited background time (screen on/off)
 - Fixed countless styling issues on all themes
 - Rewrote light theme
 - Removed XMLHTTP requests from web interface
 - Fixed issue with not all chats being returned
 - (Probably) fixed issue with wrong chat button displaying on top of list in web interface

0.3.7 -> 0.3.8
 - Fixed multiple issues with images from camera roll not displaying correctly
 - Fixed issue with camera roll favorite hearts not showing
 - Made css routes more dynamic
 - Added nord web interface theme
 - Fixed issue with marking conversations as read causing a crash
 - Added override for if phone doesn't recognize that it is connected to wifi
 - Almost fixed background issue (it won't crash in the background now, but still doesn't receive connections)
 - Improved web interface styling

0.3.6 -> 0.3.7
 - Introduced general optimizations
 - Specifically optimized message and searching retrieval functions
 - Introduced viewing of read receipts
 - Fixed issues of plus signs being filtered out with query parsing
 - Removed postinst script
 - Decreased code footprint

0.3.5 -> 0.3.6
 - Maybe fixed Cydia never-ending update issue?
 - Fixed styling issues with css grid noncompatible browsers
 - Fixed weird colors on light theme
 - Fixed crashing issue when marking conversation as read
 - Optimized chat retrieval SQL Query

0.3.4 -> 0.3.5
 - Added support for marking conversations as read when viewed in web interface
 - Added support for relative date displays
 - Removed unnecessary functions
 - Added option to change how many photos display by default

0.3.3 -> 0.3.4
 - Rewrote function to fetch texts to use sql joins instead of multiple queries; is significantly faster now
 - Almost now shows favorite images in interface
 - Fixed issue #14 (correctly parses `chat_id`s when retrieving messages)
 - Improved name retrieval to match SMS Sender IDs

0.3.2 -> 0.3.3
 - Implemented better `chat_identifier` parsing to get name & image (see issue #9);
 - Enabled interacting with and selecting photos from the camera roll in the web interface
 - Remove unnecessary `parsePhoneNum()` function
 - Fixed issue with images failing to load
 - Introduced custom query parsing to allow for plus signs (or replacements like `%2B`) in the URL
 - Fixed issues with app crashing if a text was received before the server had started

0.3.1 -> 0.3.2
 - Updated notifications to show more information
 - Fixed issue with favicon not showing
 - Fixed issue with app still requiring one to enter phone number
 - Updated Content-type of CSS pages to `text/css`
 - Fixed issue with new texts not displaying properly

0.3.0-1+debug -> 0.3.1
 - Change api specifications for sending text
 - Removed requirement for inputting phone numbers
 - Added option to disable SSL/HTTPS
 - Better parsing of phone numbers for sending and checking texts

0.2.0-20+debug -> 0.3.0-1+debug
 - Changed from GCDWebServer framework to my forked branch of Criollo
 - Implemented HTTPS
 - Implemented Desktop Notifications

0.2.0+debug19 -> 0.2.0-20+debug
 - Changed how version numbers are named
 - Fixed issue with new text content not appearing on web interface conversation button if it was currently selected and top conversation
 - Web interface now shows attachment description in place of latest text content when latest text had no body but had an attachment
 - Removed deprecated functions
 - Added error checking for when the database fails to open
 - Updated method of opening database for possibly better compatibility

0.2.0+debug18 -> 0.2.0+debug19
 - Improved phone number parsing
 - Improved bounds checking on arrays
 - Fixed minor css styling issues
 - Fixed issue with default chats/messages numbers being switched

0.2.0+debug17 -> 0.2.0+debug18
 - Fixed issue with port not changing
 - Fixed issue with force unwrapping ip address
 - Now calls mryipc methods asynchronously so that app does not crash if they fail

0.2.0+debug15 -> 0.2.0+debug17
 - Updated libmryipc.dylib to newest version
 - Set libmryipc.dylib to embed & sign, not neither.
 - Removed option to start server on load
 - Added new information about entering phone number
 - Added postinst script to recommend ldrestarting

0.2.0+debug14 -> 0.2.0+debug15
 - Fixed dependency issues
 - Laid groundwork for showing camera roll images in browser interface

0.2.0+debug13 -> 0.2.0+debug14
 - Added app icon on home screen
 - Added app icon to website

0.2.0+debug11 -> 0.2.0+debug13
 - Fixed issue with styling of profile pictures and more texts button
 - Added easy access to light theme
 - Fixed styling issues on light theme
 - Removed server_ping setting

0.2.0+debug10 -> 0.2.0+debug11
 - Fixed issue with new texts showing slowly
 - No longer updates when user sends text from another device
 - Fixed issue with new texts not appearing under conversation in chats list
 - Will have issues with new texts doubling if you use libsmserver < 0.2.0+debug20

0.2.0+debug9 -> 0.2.0+debug10
- Fixed styling issues in web interface
- Added dynamic colors for sms vs imessages

0.2.0+debug8 -> 0.2.0+debug9
- Added view for time & most recent text on chat list in web interface
- Refactored JS in web interface
- Fixed styling issues in web interface

0.2.0+debug7 -> 0.2.0+debug8
- Changed profile & attachment request directory from `profile` and `attachments` to `data` (for both)
- Fixed issue with parsing attachment path
- Added support for retrieving a list of photos from photo library through API
- Added support for retrieving specific item from photo library through API

0.2.0+debug6 -> 0.2.0+debug7
- Fixed issue with IPv6 address incorrectly showing
- Fixed issue with keyboard covering textfields when entering name
- Disabled long-polling by default on web interface; however, the code is still there and the call func is simply commented out. Easy to revert if you so wish
- Removed unnecessary messages reloading in web interface

0.2.0+debug5 -> 0.2.0+debug6
- Added extra address handing to support more types of address formatting (e.g. with/without area code, country code, etc.)
- Added options to reset defaults
- Fixed bug with popup form sending even when 'cancel' was clicked instead of 'sent'
- Fixed small css styling issues

0.2.0+debug3 -> 0.2.0+debug5
- Merged PR to fix extra line issue when sending text in web interface
- Merged PR to allow extra line creation on web interface with Shift+Enter
- Fixed spacing issue on main app view
- Optimized new text retrieval

0.2.0+debug2 -> 0.2.0+debug3
- Added protections for unwanted webSocket connections
- Added settings for changing webSocket port
- Laid groundwork for battery/wifi stats on webpage
- Laid groundwork for new texts retrieval method customization

+debug80 -> 0.2.0+debug2
- Added support for websockets (instant notification on web client when new texts are received on host)
- Fixed issue with defaults
- Fixed issue with unread conversations not showing

+debug77 -> +debug80
- Added basic search API
- Fixed CSS issues in web interface

+debug76 -> +debug77
- Added support within libsmserver for sending texts to previously nonexistent conversations
- Added support in web interface for sending texts to previously nonexistent conversations

+debug72 -> +debug76
- Fixed issue with unc0ver devices being unable to send attachments or set custom CSS
- Fixed entitlements
- Implemented correct codesigning
- Removed postinst Script

0.1.0+debug68 -> +debug72
- Changed upload/POST directory to /send instead of /uploads
- Whenever new texts arrive, the web interface conditionally reloads the Chats & only adds new texts instead of reloading all texts
- New texts appear as soon as they're sent in the web interface
- Probably a few small bug fixes
