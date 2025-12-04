extends GameAction
class_name ActionStartDialogue

## 对话节点ID
@export var dialogue_node_id: String = ""

## 如果对话节点不存在，是否静默跳过（不报错，用于回退到下一个动作）
@export var silent_fallback: bool = false

func init_from_data(data: Dictionary) -> void:
	dialogue_node_id = data.get("id", data.get("dialogue_node_id", ""))
	silent_fallback = data.get("silent_fallback", false)
	# 如果有条件数据，创建条件（使用基类的 condition 属性）
	if data.has("condition"):
		var condition_data = data["condition"]
		if condition_data is Dictionary:
			condition = DialogueManager.condition_factory.create_condition_from_data(condition_data)

## 执行动作的具体逻辑（条件检查已在基类中处理）
## [param initiator] 发起者（通常是玩家）
## [param target] 目标（通常是交互组件）
## [return] 是否成功执行（false 表示跳过，用于回退到下一个动作）
func _execute_internal(initiator: Node, target: Node) -> bool:
	# 检查对话节点是否存在
	if not DialogueManager.dialogue_graph.has(dialogue_node_id):
		if silent_fallback:
			# 静默跳过，不报错
			return false
		else:
			# 报错
			push_error("ActionStartDialogue: 对话节点不存在 '%s'" % dialogue_node_id)
			return false
	
	# 启动对话
	DialogueManager.start_dialogue(dialogue_node_id)
	return true
