extends GameAction
class_name ActionStartQuest

@export var quest_id: String = ""

func init_from_data(action_data: Dictionary) -> void:
	quest_id = action_data.get("id", "")

func _execute_internal(initiator: Node, _target: Node) -> bool:
	if quest_id.is_empty():
		push_error("ActionStartQuest: quest_id为空")
		return false
	
	# 直接调用 QuestManager 的方法（QuestManager 是插件的一部分）
	var success = QuestManager.accept_quest_by_id(quest_id)
	if success:
		print("任务接取：", quest_id)
	return success
