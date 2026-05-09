extends Object

enum Code {
	UNAUTHORIZED,
	FORBIDDEN,
	UNSUPPORTED,
	DOES_NOT_EXIST,
	ALREADY_EXISTS,
	VALIDATION_ERROR,
	DUPLICATE_KEY,
	IN_USE,
	CONFLICT,
	FORMAT_ERROR,
	BAD_REQUEST,
	CLIENT_ERROR,
	UNREACHABLE,
	SERVICE_UNAVAILABLE,
	TIMEOUT,
	SERVER_ERROR,
	INTERNAL_ERROR,
	CREATED,
	UPDATED,
	REPLACED,
	DELETED,
	OK,
}

const Unauthorized = Code.UNAUTHORIZED
const Forbidden = Code.FORBIDDEN
const Unsupported = Code.UNSUPPORTED
const DoesNotExist = Code.DOES_NOT_EXIST
const AlreadyExists = Code.ALREADY_EXISTS
const ValidationError = Code.VALIDATION_ERROR
const DuplicateKey = Code.DUPLICATE_KEY
const InUse = Code.IN_USE
const Conflict = Code.CONFLICT
const FormatError = Code.FORMAT_ERROR
const BadRequest = Code.BAD_REQUEST
const ClientError = Code.CLIENT_ERROR
const Unreachable = Code.UNREACHABLE
const ServiceUnavailable = Code.SERVICE_UNAVAILABLE
const Timeout = Code.TIMEOUT
const ServerError = Code.SERVER_ERROR
const InternalError = Code.INTERNAL_ERROR
const Created = Code.CREATED
const Updated = Code.UPDATED
const Replaced = Code.REPLACED
const Deleted = Code.DELETED
const Ok = Code.OK

