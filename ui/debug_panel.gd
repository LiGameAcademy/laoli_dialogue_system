extends CanvasLayer
class_name DebugPanel

## 调试面板
## 实时显示对话系统、任务系统、变量系统和性能信息

@onready var dialogue_info_label: Label = %DialogueInfoLabel
@onready var quest_info_label: Label = %QuestInfoLabel
@onready var variable_info_label: Label = %VariableInfoLabel
@onready var performance_info_label: Label = %PerformanceInfoLabel

var update_timer: float = 0.0
const UPDATE_INTERVAL = 0.5  # 每0.5秒更新一次

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		_update_info()
		update_timer = 0.0

## 更新所有调试信息
func _update_info() -> void:
	_update_dialogue_info()
	_update_quest_info()
	_update_variable_info()
	_update_performance_info()

## 更新对话信息
func _update_dialogue_info() -> void:
	var info = "=== 对话系统 ===\n"
	info += "活跃: %s\n" % ("是" if DialogueManager.is_active else "否")
	
	if DialogueManager.current_node:
		info += "当前节点: %s\n" % DialogueManager.current_node.node_id
	else:
		info += "当前节点: 无\n"
	
	info += "对话图大小: %d\n" % DialogueManager.dialogue_graph.size()
	info += "已加载文件: %d\n" % DialogueManager.loaded_files.size()
	info += "缓存文件数: %d\n" % DialogueManager.dialogue_file_cache.size()
	
	dialogue_info_label.text = info

## 更新任务信息
func _update_quest_info() -> void:
	var info = "=== 任务系统 ===\n"
	info += "活跃任务: %d\n" % QuestManager.active_quests.size()
	info += "已完成任务: %d\n" % QuestManager.completed_quest_ids.size()
	info += "\n"
	
	# 显示前5个活跃任务
	var count = 0
	for quest in QuestManager.active_quests:
		if count >= 5:
			break
		var status = QuestManager.get_quest_status(quest.id)
		info += "  - %s: %s\n" % [quest.title, _quest_status_to_string(status)]
		count += 1
	
	if QuestManager.active_quests.size() > 5:
		info += "  ... (还有 %d 个任务)\n" % (QuestManager.active_quests.size() - 5)
	
	quest_info_label.text = info

## 更新变量信息
func _update_variable_info() -> void:
	var info = "=== 变量系统 ===\n"
	var all_vars = VariableManager.get_all_variables()
	info += "变量数量: %d\n" % all_vars.size()
	info += "\n"
	
	# 显示前10个变量
	var count = 0
	for var_name in all_vars:
		if count >= 10:
			break
		var value = all_vars[var_name]
		var value_str = _format_value(value)
		info += "  %s = %s\n" % [var_name, value_str]
		count += 1
	
	if all_vars.size() > 10:
		info += "  ... (还有 %d 个变量)\n" % (all_vars.size() - 10)
	
	# 显示解析器缓存统计
	if VariableManager.parser:
		var cache_size = VariableManager.parser.precompile_cache.size()
		info += "\n预编译缓存: %d 项\n" % cache_size
	
	variable_info_label.text = info

## 更新性能信息
func _update_performance_info() -> void:
	var info = "=== 性能信息 ===\n"
	info += "FPS: %d\n" % Engine.get_frames_per_second()
	
	# 内存使用（MB）
	var memory_mb = OS.get_static_memory_usage() / 1024.0 / 1024.0
	info += "内存使用: %.2f MB\n" % memory_mb
	
	# 性能分析器统计（从 DialogueManager 获取）
	if DialogueManager.performance_profiler:
		var stats = DialogueManager.performance_profiler.get_stats()
		if not stats.is_empty():
			info += "\n性能分析:\n"
			var count = 0
			for label in stats:
				if count >= 3:
					break
				var stat = stats[label]
				info += "  %s: %.2f ms (avg)\n" % [label, stat.avg_time]
				count += 1
	
	performance_info_label.text = info

## 任务状态转字符串
func _quest_status_to_string(status: QuestManager.QuestStatus) -> String:
	match status:
		QuestManager.QuestStatus.CAN_ACCEPT:
			return "可接取"
		QuestManager.QuestStatus.IN_PROGRESS:
			return "进行中"
		QuestManager.QuestStatus.READY_TO_TURN_IN:
			return "可交付"
		QuestManager.QuestStatus.FINISHED:
			return "已完成"
		QuestManager.QuestStatus.UNAVAILABLE:
			return "不可用"
		_:
			return "未知"

## 格式化值（用于显示）
func _format_value(value: Variant) -> String:
	if value == null:
		return "null"
	
	match typeof(value):
		TYPE_STRING:
			return value
		TYPE_INT, TYPE_FLOAT:
			return str(value)
		TYPE_BOOL:
			return "是" if value else "否"
		TYPE_ARRAY:
			return "数组[%d]" % value.size()
		TYPE_DICTIONARY:
			return "字典[%d]" % value.size()
		_:
			return str(value)

## 切换显示
func toggle() -> void:
	visible = not visible
	if visible:
		_update_info()

## 处理输入（用于快捷键切换）
## 注意：输入处理由 main.gd 统一管理，这里不需要处理
## 如果需要独立处理，可以取消注释下面的代码
# func _unhandled_input(event: InputEvent) -> void:
# 	# 支持 F3 键直接切换
# 	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
# 		toggle()
