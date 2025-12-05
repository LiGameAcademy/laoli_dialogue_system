extends RefCounted
class_name DialogueSaveStrategy

## 对话存档策略接口
## 允许插件用户扩展自己的存档策略，实现自定义的存档/读档逻辑

## 保存对话历史数据
## [param history_data] 对话历史数据字典
## [return] 是否成功
func save_dialogue_history(history_data: Dictionary) -> bool:
	push_error("DialogueSaveStrategy: save_dialogue_history() 未实现")
	return false

## 加载对话历史数据
## [return] 对话历史数据字典，失败返回空字典
func load_dialogue_history() -> Dictionary:
	push_error("DialogueSaveStrategy: load_dialogue_history() 未实现")
	return {}

## 保存任务状态数据
## [param quest_data] 任务状态数据字典
## [return] 是否成功
func save_quest_data(quest_data: Dictionary) -> bool:
	push_error("DialogueSaveStrategy: save_quest_data() 未实现")
	return false

## 加载任务状态数据
## [return] 任务状态数据字典，失败返回空字典
func load_quest_data() -> Dictionary:
	push_error("DialogueSaveStrategy: load_quest_data() 未实现")
	return {}
