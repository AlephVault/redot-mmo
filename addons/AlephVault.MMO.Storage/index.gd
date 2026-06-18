extends Object

class_name AlephVault__MMO__Storage

## Public namespace for storage result types.
class Types:
	## Result code enum and constants.
	const ResultCode = preload("./types/results/result_code.gd")
	## Result object returned by resource operations.
	const Result = preload("./types/results/result.gd")

	## Compatibility namespace matching the result-type folder.
	class Results:
		## Result code enum and constants.
		const ResultCode = preload("./types/results/result_code.gd")
		## Result object returned by resource operations.
		const Result = preload("./types/results/result.gd")

const StandardHttp = preload("./standard_http/index.gd")
