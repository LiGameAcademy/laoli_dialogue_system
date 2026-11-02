extends Resource
class_name Quest
## Read-only quest configuration is duplicated by QuestManager for runtime progress.

signal quest_completed(quest_id: String)
signal quest_updated()

@export var id: String
@export var title: String
@export_multiline var description: String
@export var objectives: Array[QuestObjective] = []

var is_completed: bool = false

## Connects objective notifications without closures that retain the quest itself.
func start() -> void:
	for objective: QuestObjective in objectives:
		if not objective.completed.is_connected(_on_objective_completed):
			objective.completed.connect(_on_objective_completed)
		if not objective.updated.is_connected(_on_objective_updated):
			objective.updated.connect(_on_objective_updated)

func complete() -> void:
	if is_completed:
		return
	is_completed = true
	quest_completed.emit(id)

func notify_event(event_type: String, data: Dictionary) -> void:
	if is_completed:
		return
	for objective: QuestObjective in objectives:
		if not objective.is_completed:
			objective.on_game_event(event_type, data)

func _check_completion() -> void:
	for objective: QuestObjective in objectives:
		if not objective.is_completed:
			return
	complete()

func _on_objective_completed(_description: String) -> void:
	_check_completion()

func _on_objective_updated(_current: int, _required: int) -> void:
	quest_updated.emit()
