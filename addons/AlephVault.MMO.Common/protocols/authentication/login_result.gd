extends Object
## A login result tells whether a user login attempt is accepted (and tell
## the account id and the result) or failed (with the failure reason). The
## object is generated in server-side and checked in client-side.

static func accept(ok: Variant = null, account_id: Variant = null) -> Dictionary:
	return {
		"accepted": true,
		"ok": ok,
		"failed": null,
		"account_id": account_id,
	}

static func reject(failed: Variant = null) -> Dictionary:
	return {
		"accepted": false,
		"ok": null,
		"failed": failed,
		"account_id": null,
	}

static func is_accepted(result: Dictionary) -> bool:
	return bool(result.get("accepted", false))
