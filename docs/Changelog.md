# Changelog

0.2.0+debug5 -> 0.2.0+debug
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