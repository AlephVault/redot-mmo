extends AlephVault__MMO__Server.Protocols.Commands

@rpc("authority", "call_remote", "reliable")
func login(method: String, payload: Variant = null) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Server.Protocols.Authentication.Protocol
	var connection = connection_node()
	if protocol != null and connection != null:
		protocol.handle_login_requested(connection.id, method, payload)

@rpc("authority", "call_remote", "reliable")
func logout() -> void:
	var protocol = protocol_node() as AlephVault__MMO__Server.Protocols.Authentication.Protocol
	var connection = connection_node()
	if protocol != null and connection != null:
		protocol.handle_logout_requested(connection.id)
