extends AlephVault__MMO__Server.Protocols.Authentication.Commands

@rpc("authority", "call_remote", "reliable")
func list_profiles() -> void:
	var protocol = protocol_node() as AlephVault__MMO__Server.Protocols.Authentication.Simple.Protocol
	var connection = connection_node()
	if protocol != null and connection != null:
		protocol.handle_list_profiles_requested(connection.id)

@rpc("authority", "call_remote", "reliable")
func select_profile(profile_id: Variant) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Server.Protocols.Authentication.Simple.Protocol
	var connection = connection_node()
	if protocol != null and connection != null:
		protocol.handle_select_profile_requested(connection.id, profile_id)

@rpc("authority", "call_remote", "reliable")
func close_profile() -> void:
	var protocol = protocol_node() as AlephVault__MMO__Server.Protocols.Authentication.Simple.Protocol
	var connection = connection_node()
	if protocol != null and connection != null:
		protocol.handle_close_profile_requested(connection.id)
