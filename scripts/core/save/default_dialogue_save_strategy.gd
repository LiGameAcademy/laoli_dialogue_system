extends DialogueSaveStrategy
class_name DefaultDialogueSaveStrategy

## 默认对话存档策略
## 使用本地文件存储对话历史数据

## 存档文件路径
var save_file_path: String = "user://dialogue_history.dat"

## 存档版本（用于兼容性检查）
const SAVE_VERSION = "1.0"

## 初始化
## [param file_path] 存档文件路径（可选，默认使用 user://dialogue_history.dat）
func _init(p_file_path: String = "user://dialogue_history.dat") -> void:
	save_file_path = p_file_path

## 保存对话历史数据
## [param history_data] 对话历史数据字典
## [return] 是否成功
func save_dialogue_history(history_data: Dictionary) -> bool:
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"dialogue_history": history_data
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if not file:
		push_error("DefaultDialogueSaveStrategy: 无法创建存档文件 '%s'" % save_file_path)
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("对话历史已保存：%s" % save_file_path)
	return true

## 加载对话历史数据
## [return] 对话历史数据字典，失败返回空字典
func load_dialogue_history() -> Dictionary:
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		push_warning("DefaultDialogueSaveStrategy: 存档文件不存在 '%s'" % save_file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("DefaultDialogueSaveStrategy: JSON解析失败 '%s'" % save_file_path)
		return {}
	
	var save_data = json.data as Dictionary
	
	# 检查版本兼容性
	var version = save_data.get("version", "")
	if version != SAVE_VERSION:
		push_warning("DefaultDialogueSaveStrategy: 存档版本不匹配（当前：%s，存档：%s）" % [SAVE_VERSION, version])
	
	var history_data = save_data.get("dialogue_history", {})
	print("对话历史已加载：%s" % save_file_path)
	return history_data

## 保存任务状态数据
## [param quest_data] 任务状态数据字典
## [return] 是否成功
func save_quest_data(quest_data: Dictionary) -> bool:
	# 读取现有存档（如果存在）
	var save_data = {}
	var file_read = FileAccess.open(save_file_path, FileAccess.READ)
	if file_read:
		var json_string = file_read.get_as_text()
		file_read.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			save_data = json.data as Dictionary
	
	# 更新任务数据
	save_data["quest_data"] = quest_data
	save_data["version"] = SAVE_VERSION
	save_data["timestamp"] = Time.get_ticks_msec() / 1000.0
	
	# 保存到文件
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if not file:
		push_error("DefaultDialogueSaveStrategy: 无法创建存档文件 '%s'" % save_file_path)
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("任务状态已保存：%s" % save_file_path)
	return true

## 加载任务状态数据
## [return] 任务状态数据字典，失败返回空字典
func load_quest_data() -> Dictionary:
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		push_warning("DefaultDialogueSaveStrategy: 存档文件不存在 '%s'" % save_file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("DefaultDialogueSaveStrategy: JSON解析失败 '%s'" % save_file_path)
		return {}
	
	var save_data = json.data as Dictionary
	
	# 检查版本兼容性
	var version = save_data.get("version", "")
	if version != SAVE_VERSION:
		push_warning("DefaultDialogueSaveStrategy: 存档版本不匹配（当前：%s，存档：%s）" % [SAVE_VERSION, version])
	
	var quest_data = save_data.get("quest_data", {})
	print("任务状态已加载：%s" % save_file_path)
	return quest_data

