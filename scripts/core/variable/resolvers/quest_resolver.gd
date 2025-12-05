extends ConditionalVariableResolver
class_name QuestResolver

## 解析任务相关的条件变量（如 {has_quest:quest_01} 或 {quest_status:quest_01}）
func resolve(condition_type: String, value: String) -> Variant:
	match condition_type:
		"has_quest":
			return "是" if QuestManager.has_quest(value) else "否"
		"quest_status":
			return _get_quest_status(value)
		_:
			return null

## 获取任务状态文本
func _get_quest_status(quest_id: String) -> String:
	var status = QuestManager.get_quest_status(quest_id)
	match status:
		QuestManager.QuestStatus.CAN_ACCEPT:
			return "可接取"
		QuestManager.QuestStatus.IN_PROGRESS:
			return "进行中"
		QuestManager.QuestStatus.READY_TO_TURN_IN:
			return "可交付"
		QuestManager.QuestStatus.FINISHED:
			return "已完成"
		_:
			return "未知"

