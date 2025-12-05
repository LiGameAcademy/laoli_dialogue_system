extends Resource
class_name DialogueHistoryEntry

## 对话历史条目
## 用于记录玩家看过的对话内容

## 对话节点ID
@export var node_id: String = ""

## 角色名称
@export var character_name: String = ""

## 对话文本
@export_multiline var dialogue_text: String = ""

## 时间戳（对话发生的时间）
@export var timestamp: float = 0.0

## 是否已读
@export var is_read: bool = false

## 对话选项（如果有）
@export var choices: Array[String] = []

## 玩家选择的选项（如果有）
@export var selected_choice: String = ""

## 序列化（用于存档）
## [return] 序列化后的字典
func serialize() -> Dictionary:
	return {
		"node_id": node_id,
		"character_name": character_name,
		"dialogue_text": dialogue_text,
		"timestamp": timestamp,
		"is_read": is_read,
		"choices": choices,
		"selected_choice": selected_choice
	}

## 反序列化（用于读档）
## [param data] 序列化后的字典
func deserialize(data: Dictionary) -> void:
	node_id = data.get("node_id", "")
	character_name = data.get("character_name", "")
	dialogue_text = data.get("dialogue_text", "")
	timestamp = data.get("timestamp", 0.0)
	is_read = data.get("is_read", false)
	
	# 处理协变数组问题：手动转换 Array 为 Array[String]
	var choices_data = data.get("choices", [])
	choices.clear()
	if choices_data is Array:
		for item in choices_data:
			if item is String:
				choices.append(item)
	
	selected_choice = data.get("selected_choice", "")
