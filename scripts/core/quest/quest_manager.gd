extends Node

## --- 任务状态枚举 ---
enum QuestStatus { 
	CAN_ACCEPT,      	## 可以接取（在数据库中，但未接取）
	IN_PROGRESS,     	## 进行中（已接取，但未完成）
	READY_TO_TURN_IN, 	## 已完成，可以交任务
	FINISHED,         	## 已完成并已交任务
	UNAVAILABLE,        ## 不可接受（不在数据库中）
}

# --- 数据存储 ---
# 存储所有正在进行中的任务实例 (Quest Resource 实例)
var active_quests: Array[Quest] = [] ## 正在进行中的任务实例

# 存储已完成的任务ID (用于防止重复接取，或作为前置条件检查)
var completed_quest_ids: Array[String] = [] ## 已完成的任务ID

# --- 信号 ---
# UI系统会监听这些信号来更新界面
signal quest_accepted(quest : Quest)
signal quest_completed(quest : Quest)  # 任务完成（所有目标达成，但未交付）
signal quest_ready_to_turn_in(quest : Quest)  # 任务可以交付（新增）
signal quest_turned_in(quest : Quest)  # 任务已交付（新增）
signal quest_updated(quest : Quest) # 进度更新时（比如杀怪 1/5 -> 2/5）
signal quests_loaded()  # 任务加载完成（用于存档读档后刷新UI）

# --- 依赖注入（解耦业务层）---
## 游戏事件信号（由业务层注册）
var game_event_signal: Signal
## 任务数据库查询函数（由业务层注册）
var quest_database_provider: Callable
## 任务资源获取函数（由业务层注册）
var quest_resource_getter: Callable

## 注册游戏事件信号（由业务层调用）
## [param signal_instance] 游戏事件信号
func register_game_event_signal(signal_instance: Signal) -> void:
	if game_event_signal != null:
		push_warning("QuestManager: 游戏事件信号已注册，将被覆盖")
	game_event_signal = signal_instance
	if game_event_signal:
		game_event_signal.connect(_on_game_event)

## 注册任务数据库查询函数（由业务层调用）
## [param provider] 查询函数，接收 quest_id: String，返回 bool
func register_quest_database_provider(provider: Callable) -> void:
	quest_database_provider = provider

## 注册任务资源获取函数（由业务层调用）
## [param getter] 获取函数，接收 quest_id: String，返回 Quest 或 null
func register_quest_resource_getter(getter: Callable) -> void:
	quest_resource_getter = getter

func _ready() -> void:
	# 注意：不再直接连接 GameState，改为通过 register_game_event_signal 注册
	# 业务层需要在 _ready() 中调用：QuestManager.register_game_event_signal(GameState.game_event_occurred)
	VariableManager.register_variable_provider(_provide_quest_variables)

# --- 核心：事件分发 ---
func _on_game_event(type: String, data: Dictionary) -> void:
	# 遍历所有活跃任务
	# 注意：即使任务已完成，也继续处理事件（虽然通常不会触发，但为了安全）
	for quest in active_quests:
		# 只处理未完成的任务（已完成的任务不再需要更新进度）
		if not quest.is_completed:
			# 把事件传给任务，让任务自己去判断是否符合目标
			quest.notify_event(type, data)

## 手动触发游戏事件（用于测试或直接调用）
## [param type] 事件类型
## [param data] 事件数据
func trigger_game_event(type: String, data: Dictionary) -> void:
	_on_game_event(type, data)

# --- 公共接口：接取任务 ---
## 通过任务资源接取任务
## [param quest_res] 任务资源
func accept_quest(quest_res: Quest) -> void:
	# 1. 检查是否已经接过或已完成
	if has_quest(quest_res.id) or is_quest_completed(quest_res.id):
		print("任务已存在或已完成，无法接取：", quest_res.title)
		return
	
	# 2. 【关键】实例化资源 (Deep Duplicate)
	# 资源文件在磁盘上是只读模板，我们必须复制一份独立的实例来记录进度
	var new_quest = quest_res.duplicate(true)
	
	# 3. 初始化并连接内部信号
	new_quest.start()
	# 监听这个新任务实例的信号，以便转发给 UI
	new_quest.quest_updated.connect(func() -> void: quest_updated.emit(new_quest))
	new_quest.quest_completed.connect(func(_id: String) -> void: _on_quest_completed(new_quest))
	
	# 4. 加入列表
	active_quests.append(new_quest)
	quest_accepted.emit(new_quest)
	print("任务接取成功：", new_quest.title)

## 通过任务ID接取任务（便捷方法）
## [param quest_id] 任务ID
## [return] 是否成功接取
func accept_quest_by_id(quest_id: String) -> bool:
	if quest_id.is_empty():
		push_error("QuestManager: accept_quest_by_id quest_id为空")
		return false
	
	# 通过注册的资源获取函数获取任务资源
	if not quest_resource_getter.is_valid():
		push_error("QuestManager: 未注册任务资源获取函数，无法接取任务 '%s'" % quest_id)
		return false
	
	var quest_res = quest_resource_getter.call(quest_id)
	if not quest_res:
		push_error("QuestManager: 找不到任务资源 '%s'" % quest_id)
		return false
	
	accept_quest(quest_res)
	return true

## 交付任务（玩家与NPC对话后选择"交任务"）
## [param quest_id] 任务ID
## [return] 是否成功交付
func turn_in_quest(quest_id: String) -> bool:
	if quest_id.is_empty():
		push_error("QuestManager: turn_in_quest quest_id为空")
		return false
	
	# 查找任务实例
	var quest: Quest = null
	for q in active_quests:
		if q.id == quest_id:
			quest = q
			break
	
	if not quest:
		push_error("QuestManager: 找不到任务 '%s'，无法交付" % quest_id)
		return false
	
	# 检查任务是否已完成（所有目标都达成）
	if not quest.is_completed:
		push_warning("QuestManager: 任务 '%s' 尚未完成，无法交付" % quest_id)
		return false
	
	# 移出活跃列表
	active_quests.erase(quest)
	# 加入历史记录（标记为已交付）
	completed_quest_ids.append(quest.id)
	
	# 发出信号通知 UI 任务已交付
	quest_turned_in.emit(quest)
	print("任务已交付：", quest.title)
	
	# 这里可以触发后续逻辑，比如发放奖励 (RewardManager)
	# 或者自动接取下一个任务
	
	return true

# --- 辅助查询接口 ---
func has_quest(quest_id: String) -> bool:
	for q in active_quests:
		if q.id == quest_id:
			return true
	return false

func is_quest_completed(quest_id: String) -> bool:
	return completed_quest_ids.has(quest_id)

## 获取任务当前状态
## [param quest_id] 任务ID
## [return] QuestStatus 枚举值
func get_quest_status(quest_id: String) -> QuestStatus:
	if quest_id.is_empty():
		return QuestStatus.UNAVAILABLE
	
	if is_quest_completed(quest_id):
		return QuestStatus.FINISHED
	
	if has_quest(quest_id):
		# 查找任务实例，检查是否所有目标都完成
		for q in active_quests:
			if q.id == quest_id:
				if q.is_completed:
					return QuestStatus.READY_TO_TURN_IN
				else:
					return QuestStatus.IN_PROGRESS
	
	# 任务未接取，检查是否在数据库中（可以接取）
	# 使用注册的查询函数，避免直接依赖业务层
	if quest_database_provider.is_valid():
		var has_in_database = quest_database_provider.call(quest_id)
		if has_in_database:
			return QuestStatus.CAN_ACCEPT
	else:
		# 如果没有注册查询函数，发出警告但继续执行
		push_warning("QuestManager: 未注册任务数据库查询函数，无法判断任务是否可接取")
	
	return QuestStatus.UNAVAILABLE  # 默认返回不可接取

# --- 内部逻辑：任务完成（所有目标达成，但未交付）---
func _on_quest_completed(quest: Quest) -> void:
	print("任务目标全部完成，可以交付：", quest.title)
	
	# 【关键修改】任务完成时，不要立即移出 active_quests
	# 而是保持在列表中，等待玩家交付
	# 这样 get_quest_status 才能正确返回 READY_TO_TURN_IN
	
	# 发出信号通知 UI 任务已完成，可以交付
	quest_completed.emit(quest)
	quest_ready_to_turn_in.emit(quest)
	
	# 注意：此时任务仍在 active_quests 中，状态为 READY_TO_TURN_IN
	# 只有当玩家交付任务后，才会移出 active_quests 并加入 completed_quest_ids

## 提供任务变量
## [return] 任务变量字典
func _provide_quest_variables() -> Dictionary:
	var vars = {}
	
	# 为每个活跃任务创建变量
	for quest in active_quests:
		var quest_var_name = "quest_" + quest.id + "_status"
		var status = get_quest_status(quest.id)
		vars[quest_var_name] = _quest_status_to_string(status)
	
	return vars

## 将任务状态转换为字符串
func _quest_status_to_string(status: QuestStatus) -> String:
	match status:
		QuestStatus.CAN_ACCEPT:
			return "可接取"
		QuestStatus.IN_PROGRESS:
			return "进行中"
		QuestStatus.READY_TO_TURN_IN:
			return "可交付"
		QuestStatus.FINISHED:
			return "已完成"
		_:
			return "未知"
