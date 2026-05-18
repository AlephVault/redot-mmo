extends Object

## Helpers for protocol classes.

## Sorts protocol classes so each class appears after all of its dependencies.
##
## Returns an empty array and emits an error when a class does not extend
## parent_type, dependencies is not available as an Array, a referenced
## dependency is missing from dependencies, or the graph contains a cycle.
static func sort_by_dependencies(dependencies: Array[Script], parent_type: Script) -> Array[Script]:
	var result: Array[Script] = []
	if parent_type == null:
		push_error("ProtocolUtils.sort_by_dependencies: parent_type must not be null")
		return result
	if not _has_dependencies_property(parent_type):
		push_error("ProtocolUtils.sort_by_dependencies: parent_type must define dependencies")
		return result

	var known: Dictionary = {}
	for dependency in dependencies:
		if dependency == null:
			push_error("ProtocolUtils.sort_by_dependencies: dependencies must not contain null scripts")
			return []
		if known.has(dependency):
			push_error("ProtocolUtils.sort_by_dependencies: dependencies must not contain duplicate scripts")
			return []
		if dependency == parent_type or not _extends_script(dependency, parent_type):
			push_error("ProtocolUtils.sort_by_dependencies: every dependency must extend parent_type")
			return []
		known[dependency] = true

	var dependency_map: Dictionary = {}
	for dependency in dependencies:
		var class_dependencies = dependency.get("dependencies")
		if typeof(class_dependencies) != TYPE_ARRAY:
			push_error("ProtocolUtils.sort_by_dependencies: dependencies property must be an Array")
			return []

		var normalized_dependencies: Array[Script] = []
		for class_dependency in class_dependencies:
			if not (class_dependency is Script):
				push_error("ProtocolUtils.sort_by_dependencies: class dependencies must be scripts")
				return []
			if not known.has(class_dependency):
				push_error(
					"ProtocolUtils.sort_by_dependencies: class dependency is missing from the input list"
				)
				return []
			normalized_dependencies.append(class_dependency)
		dependency_map[dependency] = normalized_dependencies

	var resolved: Dictionary = {}
	var pending: Dictionary = known.duplicate()
	while not pending.is_empty():
		var added := false
		for dependency in dependencies:
			if not pending.has(dependency):
				continue
			if _are_dependencies_resolved(dependency_map[dependency], resolved):
				result.append(dependency)
				resolved[dependency] = true
				pending.erase(dependency)
				added = true

		if not added:
			push_error("ProtocolUtils.sort_by_dependencies: circular dependency detected")
			return []

	return result

static func _has_dependencies_property(script: Script) -> bool:
	return typeof(script.get("dependencies")) == TYPE_ARRAY

static func _extends_script(script: Script, parent_type: Script) -> bool:
	var current := script.get_base_script()
	while current != null:
		if current == parent_type:
			return true
		current = current.get_base_script()
	return false

static func _are_dependencies_resolved(dependencies: Array[Script], resolved: Dictionary) -> bool:
	for dependency in dependencies:
		if not resolved.has(dependency):
			return false
	return true
