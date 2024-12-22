class_name AVMMOClasses


## Tells whether a class script inherits a globally named class.
func inherits_native_class(script: Script, native_class_name: String) -> bool:
	# If the script's top-level extends statement is "extends Node",
	# script.native_class == "Node"
	if script.native_class == native_class_name:
		return true
	var parent = script.get_base_script()
	if parent:
		return inherits_native_class(parent, native_class_name)
	return false
