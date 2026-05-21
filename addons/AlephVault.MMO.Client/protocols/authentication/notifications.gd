extends AlephVault__MMO__Client.Protocols.Notifications

@rpc("authority", "call_remote", "reliable")
func login_ok(payload: Variant = null) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Protocol
	if protocol != null:
		protocol.handle_login_ok(payload)

@rpc("authority", "call_remote", "reliable")
func login_failed(payload: Variant = null) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Protocol
	if protocol != null:
		protocol.handle_login_failed(payload)

@rpc("authority", "call_remote", "reliable")
func kicked(payload: Variant = null) -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Protocol
	if protocol != null:
		protocol.handle_kicked(payload)

@rpc("authority", "call_remote", "reliable")
func logged_out() -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Protocol
	if protocol != null:
		protocol.handle_logged_out()

@rpc("authority", "call_remote", "reliable")
func not_logged_in() -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Protocol
	if protocol != null:
		protocol.handle_not_logged_in()

@rpc("authority", "call_remote", "reliable")
func account_already_in_use() -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Protocol
	if protocol != null:
		protocol.handle_account_already_in_use()

@rpc("authority", "call_remote", "reliable")
func already_logged_in() -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Protocol
	if protocol != null:
		protocol.handle_already_logged_in()

@rpc("authority", "call_remote", "reliable")
func forbidden() -> void:
	var protocol = protocol_node() as AlephVault__MMO__Client.Protocols.Authentication.Protocol
	if protocol != null:
		protocol.handle_forbidden()
