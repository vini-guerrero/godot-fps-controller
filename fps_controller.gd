tool

extends EditorPlugin

var nodeName : String = "FPSController"
const scriptPath = "res://addons/fps_controller/scripts/FPSController.gd"
const iconPath = "res://addons/fps_controller/icons/icon.png"

func _enter_tree(): add_custom_type(nodeName, "KinematicBody", preload(scriptPath), preload(iconPath))
func _exit_tree(): remove_custom_type(nodeName)
