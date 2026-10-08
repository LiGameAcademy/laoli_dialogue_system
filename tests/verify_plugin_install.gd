@tool
extends EditorPlugin
## 仅在隔离宿主中作为测试插件启用；测试会切换目标插件与改写宿主设置。
@export var _addon_path: String = "res://addons/laoli_dialogue_system"
var _plugin_name: String = "laoli_dialogue_system"
func _enter_tree() -> void:
	call_deferred("_run")
func _run() -> void:
	var services: Array[String] = ["DialogueHistoryManager", "VariableManager", "QuestManager", "DialogueManager"]
	for service: String in services:
		assert(ProjectSettings.has_setting("autoload/" + service))
		assert(String(ProjectSettings.get_setting("autoload/" + service)).begins_with("*" + _addon_path + "/"))
	# Force reconstruction, as if the editor reopened the plugin.
	var plugin: EditorPlugin = load(_addon_path + "/plugin.gd").new() as EditorPlugin
	plugin._disable_plugin()
	for service: String in services:
		assert(not ProjectSettings.has_setting("autoload/" + service))
	plugin.free()
	EditorInterface.set_plugin_enabled(_plugin_name, false)
	ProjectSettings.set_setting("autoload/DialogueManager", "*" + _addon_path + "/scripts/core/dialogue/dialogue_manager.gd")
	EditorInterface.set_plugin_enabled(_plugin_name, true)
	EditorInterface.set_plugin_enabled(_plugin_name, false)
	assert(ProjectSettings.has_setting("autoload/DialogueManager"), "Host-owned autoload removed")
	for service: String in services:
		if service != "DialogueManager":
			assert(not ProjectSettings.has_setting("autoload/" + service))
	EditorInterface.set_plugin_enabled(_plugin_name, true)
	print("PASS: plugin installation settings, disable after reload, host-owned autoload preservation")
	get_tree().quit()
