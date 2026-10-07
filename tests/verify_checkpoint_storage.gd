extends Node
const Store = preload("res://addons/laoli_dialogue_system/scripts/core/save/checkpoint_store.gd")
const Codec = preload("res://addons/laoli_dialogue_system/scripts/core/save/quest_snapshot.gd")
func _ready() -> void:
	var template: Quest = Quest.new()
	template.id = "probe"
	var goal: ObjectiveKill = ObjectiveKill.new()
	goal.target_enemy_id = "clone"
	goal.required_amount = 2
	template.objectives.append(goal)
	var database: Dictionary[String, Quest] = {"probe": template}
	var active: Array[Quest] = [template.duplicate(true) as Quest]
	(active[0].objectives[0] as ObjectiveKill).current_amount = 1
	var completed: Array[String] = []
	var data: Dictionary = Codec.capture(active, completed)
	var path: String = "user://checkpoint_probe_%d.json" % Time.get_ticks_usec()
	var store: Store = Store.new(path)
	assert(store.save_snapshot(data))
	var codec: Codec = Codec.new()
	assert(codec.prepare(store.load_snapshot(), database))
	var restored: ObjectiveKill = codec.prepared_quests[0].objectives[0] as ObjectiveKill
	assert(restored.current_amount == 1 and restored != goal)
	restored.current_amount = 2
	assert(goal.current_amount == 0 and (active[0].objectives[0] as ObjectiveKill).current_amount == 1)
	data["active"][0]["id"] = "missing"
	assert(not codec.prepare(data, database) and codec.prepared_quests.is_empty())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	assert(store.load_snapshot().is_empty() and not store.last_error.is_empty())
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
	print("PASS: standalone checkpoint storage, validation and quest resource isolation")
	get_tree().quit()
