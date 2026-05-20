extends Object

const GHOSTED := "ghosted"
const ACCOUNT_LOAD_ERROR := "account_load_error"
const LOGIN_TIMEOUT := "login_timeout"
const NON_GRACEFUL_DISCONNECTION := "non_graceful_disconnection"
const SESSION_INITIALIZATION_ERROR := "session_initialization_error"
const SERVER_KICK := "server_kick"

static func ghosted() -> Dictionary:
	return {"reason": GHOSTED}

static func account_load_error() -> Dictionary:
	return {"reason": ACCOUNT_LOAD_ERROR}

static func login_timeout() -> Dictionary:
	return {"reason": LOGIN_TIMEOUT}

static func non_graceful_disconnection(error: Variant = null) -> Dictionary:
	return {"reason": NON_GRACEFUL_DISCONNECTION, "error": error}

static func session_initialization_error() -> Dictionary:
	return {"reason": SESSION_INITIALIZATION_ERROR}

static func server_kick(reason: Variant = null) -> Dictionary:
	return {"reason": SERVER_KICK, "detail": reason}
