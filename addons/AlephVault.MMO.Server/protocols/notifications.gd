extends Node

## Routes protocol notifications and responses sent from the server to the client.
##
## It is highly recommended that subclasses declare all RPC methods with:
## @rpc("authority", "call_remote", "reliable")
