extends Resource
class_name DialogueNode

# --- 基础信息 ---
@export var node_id: String = ""  # 节点唯一标识
@export var character_key: String = ""  # 角色名称的本地化键（如 "CHARACTER_VILLAGE_CHIEF"）
@export_multiline var text_key: String = ""  # 对话文本的本地化键（单个）
@export var text_keys: Array[String] = []  # 对话文本的本地化键数组（随机选择）
@export var text_weights: Array[float] = []  # 文本权重（用于加权随机，可选）

# --- 选项列表 ---
@export var options: Array[DialogueOption] = []

# --- 动作列表（当节点被处理时执行）---
@export var actions: Array[GameAction] = []

# --- 流程控制 ---
@export var next_node_id: String = ""  # 单线对话的下一节点（如果没有选项）

# --- 元数据（可选，用于扩展）---
@export var metadata: Dictionary = {}  # 可以存储音效、动画、表情等额外信息

# --- 内部状态 ---
var last_selected_index: int = -1  # 最近选择的文本索引（避免重复）

# --- 便捷方法：获取本地化后的文本 ---
func get_character_name() -> String:
	return tr(character_key) if not character_key.is_empty() else ""

## 获取本地化后的文本（支持随机选择）
## 优先使用随机文本数组，如果没有则使用单个文本
func get_text() -> String:
	# 优先使用随机文本数组
	if not text_keys.is_empty():
		var selected_key = _select_random_text()
		return tr(selected_key) if not selected_key.is_empty() else ""
	
	# 回退到单个文本
	return tr(text_key) if not text_key.is_empty() else ""

## 随机选择文本（支持加权随机和非重复选择）
## [return] 选中的文本键
func _select_random_text() -> String:
	if text_keys.is_empty():
		return ""
	
	# 如果有权重且数量匹配，使用加权随机
	if not text_weights.is_empty() and text_weights.size() == text_keys.size():
		return _weighted_random_select()
	
	# 否则使用非重复随机选择
	return _non_repeating_random_select()

## 加权随机选择
## [return] 选中的文本键
func _weighted_random_select() -> String:
	if text_keys.is_empty():
		return ""
	
	# 计算总权重
	var total_weight = 0.0
	for weight in text_weights:
		total_weight += weight
	
	if total_weight <= 0.0:
		# 权重无效，回退到均匀随机
		return text_keys[randi() % text_keys.size()]
	
	# 随机选择
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for i in range(text_keys.size()):
		current_weight += text_weights[i]
		if random_value <= current_weight:
			last_selected_index = i
			return text_keys[i]
	
	# 回退到最后一个
	last_selected_index = text_keys.size() - 1
	return text_keys[-1]

## 非重复随机选择（避免连续选择相同的文本）
## [return] 选中的文本键
func _non_repeating_random_select() -> String:
	if text_keys.size() <= 1:
		return text_keys[0] if text_keys.size() > 0 else ""
	
	# 如果有多个选项，避免选择上次的
	var available_indices: Array[int] = []
	for i in range(text_keys.size()):
		if i != last_selected_index:
			available_indices.append(i)
	
	if available_indices.is_empty():
		# 如果所有选项都被排除，回退到全部选项
		for i in range(text_keys.size()):
			available_indices.append(i)
	
	var selected_index = available_indices[randi() % available_indices.size()]
	last_selected_index = selected_index
	return text_keys[selected_index]

# --- 检查是否有选项 ---
func has_choices() -> bool:
	return not options.is_empty()

# --- 获取可用的选项（过滤掉条件不满足的）---
func get_available_options(activator: Node) -> Array[DialogueOption]:
	var available: Array[DialogueOption] = []
	for option in options:
		if option.is_available(activator):
			available.append(option)
	return available
