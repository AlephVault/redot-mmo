extends AlephVault__MMO__Client.Protocols.Authentication.Notifications

@rpc("authority", "call_remote", "reliable")
func profiles_list(list: Array[Variant]) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Simple.Protocol
	if protocol != null:
		protocol.handle_profiles_list(list)

@rpc("authority", "call_remote", "reliable")
func profile_invalid(reason: Variant) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Simple.Protocol
	if protocol != null:
		protocol.handle_profile_invalid(reason)

@rpc("authority", "call_remote", "reliable")
func profile_unavailable(reason: Variant) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Simple.Protocol
	if protocol != null:
		protocol.handle_profile_unavailable(reason)

@rpc("authority", "call_remote", "reliable")
func profile_selected(profile_id: Variant, profile: Variant) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Simple.Protocol
	if protocol != null:
		protocol.handle_profile_selected(profile_id, profile)

@rpc("authority", "call_remote", "reliable")
func profile_closed(reason: Variant = null) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Simple.Protocol
	if protocol != null:
		protocol.handle_profile_closed(reason)

@rpc("authority", "call_remote", "reliable")
func profile_not_selected(reason: Variant = null) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Simple.Protocol
	if protocol != null:
		protocol.handle_profile_not_selected(reason)

@rpc("authority", "call_remote", "reliable")
func profile_not_closeable(reason: Variant = null) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Simple.Protocol
	if protocol != null:
		protocol.handle_profile_not_closeable(reason)
