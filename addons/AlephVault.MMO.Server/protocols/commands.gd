extends Node

## Routes protocol commands sent from the client to the server.
##
## It is highly recommended that subclasses declare all RPC methods with:
## @rpc("authority", "call_remote", "reliable")

## Gets the server connection node this commands node belongs to.
func connection_node() -> AlephVault__MMO__Server.Connection:
	return $"../.." as AlephVault__MMO__Server.Connection

## Gets the protocol instance this commands node belongs to.
func protocol_node() -> AlephVault__MMO__Server.Protocols.Protocol:
	var protocol_name := str(get_parent().name)
	# Rationale: connection protocol -> protocols node -> connection -> server node -> protocols node -> the protocol.
	return get_node_or_null("../../../../Protocols/%s" % protocol_name) as AlephVault__MMO__Server.Protocols.Protocol
