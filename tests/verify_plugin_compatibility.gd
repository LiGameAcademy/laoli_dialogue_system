extends Node
const UI: PackedScene = preload("res://addons/laoli_dialogue_system/ui/dialogue_ui.tscn")
const DialogueUI = preload("res://addons/laoli_dialogue_system/ui/dialogue_ui.gd")
const FILE: String = "res://addons/laoli_dialogue_system/tests/compatibility_dialogue.json"
var _session: int = -1
var _texts: Array[String] = []

func _ready() -> void:
	DialogueManager.dialogue_session_started.connect(_on_session)
	DialogueManager.text_updated.connect(_on_text)
	call_deferred("_run")

func _run() -> void:
	var player: Node = Node.new()
	add_child(player)
	DialogueManager.register_player_getter(func() -> Node: return player)
	assert(DialogueManager._get_player_node() == player, "Legacy getter compatibility failed")
	VariableManager.set_variable("player_name", "测试玩家")
	DialogueManager.load_dialogue_file(FILE, false)
	assert(DialogueManager.loaded_files == [FILE])
	DialogueManager.load_dialogue_file(FILE, true)
	assert(DialogueManager.dialogue_file_cache.has(FILE))
	var ui: DialogueUI = UI.instantiate() as DialogueUI
	ui.typing_sound_enabled = false
	add_child(ui)
	DialogueManager.start_dialogue("source_compat")
	await get_tree().process_frame
	await get_tree().process_frame
	assert(DialogueManager.is_active and ui.dialogue_panel.visible)
	assert(DialogueHistoryManager.is_node_read("source_compat"))
	assert(_texts.back().contains("测试玩家"), "Variable expansion failed")
	assert(ui.theme != null)
	DialogueManager.advance_dialogue_session(_session)
	assert(not DialogueManager.is_active and ui.typing_timer.is_stopped())
	assert(not ui.dialogue_panel.visible)
	var first: int = DialogueManager.start_dialogue_session("source_compat")
	DialogueManager.cancel_dialogue_session(first)
	var second: int = DialogueManager.start_dialogue_session("source_compat")
	await get_tree().process_frame
	await get_tree().process_frame
	DialogueManager.advance_dialogue_session(first)
	assert(DialogueManager.is_session_current(second), "Stale UI callback advanced a new session")
	DialogueManager.clear_all_dialogues()
	assert(not DialogueManager.is_active and ui.typing_timer.is_stopped())
	DialogueManager.load_dialogue_file(FILE, false)
	assert(DialogueManager.dialogue_graph.has("source_compat"))
	DialogueManager.unload_dialogue_file(FILE)
	assert(not DialogueManager.dialogue_graph.has("source_compat"))
	assert(DialogueManager.save_manager != null and DialogueManager.performance_profiler != null)
	var choices: DialogueNode = DialogueNode.new()
	choices.node_id = "choice_contract"
	var valid_option: DialogueOption = DialogueOption.new()
	valid_option.text_key = "继续"
	valid_option.next_node_id = "END"
	choices.options.append(valid_option)
	DialogueManager.dialogue_graph[choices.node_id] = choices
	var choice_session: int = DialogueManager.start_dialogue_session(choices.node_id)
	await get_tree().process_frame
	await get_tree().process_frame
	var invalid_option: DialogueOption = DialogueOption.new()
	invalid_option.next_node_id = "END"
	DialogueManager.make_session_choice(choice_session, {"text": "错误", "option_resource": invalid_option})
	assert(DialogueManager.is_session_current(choice_session))
	assert(DialogueHistoryManager.history.back().selected_choice.is_empty())
	var button: Button = ui.choices_container.get_child(0) as Button
	button.pressed.emit()
	assert(not DialogueManager.is_active)
	assert(DialogueHistoryManager.history.back().selected_choice == "继续")
	ui.queue_free()
	player.queue_free()
	DialogueManager.register_player_getter(Callable())
	await get_tree().process_frame
	print("PASS: standalone UI/theme, legacy getter/start, variables/history, cache/merge/unload, stale session and cancellation")
	get_tree().quit()

func _on_session(session_id: int) -> void:
	_session = session_id

func _on_text(_character: String, text: String) -> void:
	_texts.append(text)
