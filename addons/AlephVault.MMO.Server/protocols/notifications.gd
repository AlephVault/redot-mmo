extends Node

## Routes protocol notifications and responses sent from the server to the client.
##
## It is highly recommended that subclasses declare all RPC methods with:
## @rpc("authority", "call_remote", "reliable")

## Sends a notification RPC to the client with the given connection id.
##
## method is the RPC method name to invoke on the client-side Notifications
## node. arguments contains the method arguments in order.
func notify(connection_id: int, method: String, arguments: Array = []) -> Variant:
	return rpc_id.callv([connection_id, method] + arguments)
