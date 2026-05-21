extends Node

## Routes protocol commands sent from the client to the server.
##
## It is highly recommended that subclasses declare all RPC methods with:
## @rpc("authority", "call_remote", "reliable")

## Sends a command RPC to the server.
##
## method is the RPC method name to invoke on the server-side Commands node.
## arguments contains the method arguments in order.
func command(method: String, arguments: Array = []) -> Variant:
	return rpc_id.callv([1, method] + arguments)
