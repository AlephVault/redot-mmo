extends Node

## Routes protocol commands sent from the client to the server.
##
## It is highly recommended that subclasses declare all RPC methods with:
## @rpc("authority", "call_remote", "reliable")

## Sends a specific command to the server node. This command will contain
## the method and the arguments.
func command(method: String, arguments: Array = []):
	rpc_id.callv([1, method] + arguments)
