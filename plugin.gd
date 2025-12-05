@tool
extends EditorPlugin

func _enter_tree() -> void:
	# 当插件在编辑器中被激活时，此函数会被调用
	add_autoload_singleton("DialogueManager", "scripts/core/dialogue/dialogue_manager.gd")
	add_autoload_singleton("VariableManager", "scripts/core/variable/variable_manager.gd")
	add_autoload_singleton("DialogueHistoryManager", "scripts/core/history/dialogue_history_manager.gd")
	print("老李的对话系统插件已激活！")

func _exit_tree() -> void:
	# 当插件被禁用时，此函数会被调用
	remove_autoload_singleton("DialogueManager")
	remove_autoload_singleton("VariableManager")
	remove_autoload_singleton("DialogueHistoryManager")
	print("老李的对话系统插件已禁用。")
