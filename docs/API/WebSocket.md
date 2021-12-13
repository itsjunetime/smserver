# WebSocket (API)

All messages sent through the websocket follow the same JSON object format as specified in the [Remote.md](./Remote.md) document in this same directory; please consult that for these details.

When using the REST Client, all messages in the `commands` table (in the Remote.md document linked above) are sent through the REST API except for the ones which have no corresponding REST API function (and `attachment-data`, as it says).

Honestly, I feel like the information included in the Remote.md should be able to provide everything you need to know about the information sent through the websocket when using the REST API. Create an issue or let me know if there's any other information that I need to include here.
