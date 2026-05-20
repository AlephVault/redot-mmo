extends Node

## Routes protocol notifications and responses sent from the server to the client.
##
## It is highly recommended that subclasses declare all RPC methods with:
## @rpc("authority", "call_remote", "reliable")

## Gets the current client connection node.
func connection_node() -> AlephVault__MMO__Client.Connection:
	return $"../.." as AlephVault__MMO__Client.Connection

## Gets the protocol instance this notifications node belongs to.
func protocol_node() -> AlephVault__MMO__Client.Protocols.Protocol:
	var protocol_name := str(get_parent().name)
	# Rationale: connection protocol -> protocols node -> connection -> client node -> protocols node -> the protocol.
	return get_node_or_null("../../../../Protocols/%s" % protocol_name) as AlephVault__MMO__Client.Protocols.Protocol
