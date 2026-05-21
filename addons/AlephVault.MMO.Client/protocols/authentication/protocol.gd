extends AlephVault__MMO__Client.Protocols.Protocol

## Emitted after the server accepts a login attempt.
##
## payload is the value returned in the "ok" field of the server-side
## AlephVault__MMO__Common.Protocols.Authentication.LoginResult.accept()
## result.
signal login_ok(payload: Variant)

## Emitted after the server rejects a login attempt.
##
## payload is the value returned in the "failed" field of the server-side
## AlephVault__MMO__Common.Protocols.Authentication.LoginResult.reject()
## result. The client leaves the server after this signal is emitted.
signal login_failed(payload: Variant)

## Emitted after the server kicks this client from an authenticated session.
##
## payload is the reason sent by the server. The client leaves the server after
## this signal is emitted.
signal kicked(payload: Variant)

## Emitted after the server confirms a logout request.
##
## The client leaves the server after this signal is emitted.
signal logged_out

## Emitted when an authenticated operation is attempted while the client is not
## logged in.
signal not_logged_in

## Emitted when the server rejects a login because the account is already in
## use. The client leaves the server after this signal is emitted.
signal account_already_in_use

## Emitted when the server rejects a login-only operation because this client
## already has an authenticated session.
signal already_logged_in

## Emitted when the server rejects an authenticated operation because the client
## does not have permission to perform it.
signal forbidden

## Whether the client currently has an accepted authentication session.
var _logged_in := false

## Read-only authentication state for this client.
##
## This value becomes true when login_ok is handled, and false when login
## failure, kick, logout, or local logout handling clears the session state.
var logged_in: bool:
	get:
		return _logged_in
	set(value):
		assert(false, "The authentication login state cannot be set this way")

## Creates the client commands RPC node used to send authentication requests to
## the server.
func _create_commands_node() -> AlephVault__MMO__Client.Protocols.Commands:
	return AlephVault__MMO__Client.Protocols.Authentication.Commands.new()

## Creates the client notifications RPC node used to receive authentication
## responses from the server.
func _create_notifications_node() -> AlephVault__MMO__Client.Protocols.Notifications:
	return AlephVault__MMO__Client.Protocols.Authentication.Notifications.new()

## Sends a login request to the server.
##
## method identifies the authentication method the server implementation should
## use, and payload carries method-specific data. Returns false when the
## commands node is not available, usually because the client is not connected
## or the protocol has not been installed in the current connection.
func login(method: String, payload: Variant = null) -> bool:
	return command("login", [method, payload])

## Sends a logout request to the server and clears the local logged-in flag.
##
## Returns false when the commands node is not available, usually because the
## client is not connected or the protocol has not been installed in the current
## connection.
func logout() -> bool:
	if not command("logout"):
		return false
	_logged_in = false
	return true

## Wraps action so it only runs while the client is logged in.
##
## The returned callable accepts an optional Array of arguments and forwards
## them to action with callv(). If the client is not logged in, it returns null
## and optionally emits not_logged_in.
func make_login_required(action: Callable, emit_on_failure: bool = true) -> Callable:
	return func(args: Array = []):
		if _logged_in:
			return action.callv(args)
		if emit_on_failure:
			not_logged_in.emit()
		return null

## Handles a successful login notification from the server.
##
## Sets logged_in to true and emits login_ok with the server payload.
func handle_login_ok(payload: Variant = null) -> void:
	_logged_in = true
	login_ok.emit(payload)

## Handles a failed login notification from the server.
##
## Clears logged_in, emits login_failed, and leaves the server when this
## protocol is installed under a client Main node.
func handle_login_failed(payload: Variant = null) -> void:
	_logged_in = false
	login_failed.emit(payload)
	var main = get_parent().get_parent() as AlephVault__MMO__Client.Main
	if main != null:
		main.leave_server()

## Handles a kick notification from the server.
##
## Clears logged_in, emits kicked, and leaves the server when this protocol is
## installed under a client Main node.
func handle_kicked(payload: Variant = null) -> void:
	_logged_in = false
	kicked.emit(payload)
	var main = get_parent().get_parent() as AlephVault__MMO__Client.Main
	if main != null:
		main.leave_server()

## Handles a logout confirmation notification from the server.
##
## Clears logged_in, emits logged_out, and leaves the server when this protocol
## is installed under a client Main node.
func handle_logged_out() -> void:
	_logged_in = false
	logged_out.emit()
	var main = get_parent().get_parent() as AlephVault__MMO__Client.Main
	if main != null:
		main.leave_server()

## Handles a notification that an operation requires authentication.
func handle_not_logged_in() -> void:
	not_logged_in.emit()

## Handles a notification that the requested account is already logged in.
##
## Emits account_already_in_use and leaves the server when this protocol is
## installed under a client Main node.
func handle_account_already_in_use() -> void:
	account_already_in_use.emit()
	var main = get_parent().get_parent() as AlephVault__MMO__Client.Main
	if main != null:
		main.leave_server()

## Handles a notification that this client is already logged in.
func handle_already_logged_in() -> void:
	already_logged_in.emit()

## Handles a notification that an authenticated operation is forbidden.
func handle_forbidden() -> void:
	forbidden.emit()
