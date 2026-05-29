extends AlephVault__MMO__Server.Protocols.Commands

func _connection() -> AlephVault__MMO__Server.Connection:
	return $"../.." as AlephVault__MMO__Server.Connection

@rpc("authority", "call_remote", "reliable")
func move_to_scope(scope_number: int) -> void:
	var connection := _connection()
	if connection == null:
		print("[Scopes Sample:Server] Scope request ignored: missing connection.")
		return
	if scope_number < 1 or scope_number > 4:
		print("[Scopes Sample:Server] Invalid scope request from %d: %d" % [connection.id, scope_number])
		return

	var fq_scope_id := AlephVault__MMO__Common.Scopes.make_fq_default_scope_id(scope_number - 1)
	print("[Scopes Sample:Server] Moving connection %d to scope %d." % [connection.id, scope_number])
	connection.connections.set_connection_scope(connection.id, fq_scope_id)
