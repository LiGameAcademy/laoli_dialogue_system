extends CanvasLayer
class_name QuestLogUI

const QuestStatus = QuestManager.QuestStatus
const QUEST_ENTRY = preload("uid://buxpglhrujy2")
@onready var quest_container: VBoxContainer = %QuestContainer

var quest_entries: Dictionary[Quest, QuestEntry] = {}

## 批量更新队列
var update_queue: Array[Quest] = []
var update_timer: float = 0.0
const UPDATE_INTERVAL = 0.1  # 每0.1秒批量更新一次

func _ready() -> void:
	# 核心：连接 QuestManager 的信号
	QuestManager.quest_accepted.connect(_on_quest_accepted)
	QuestManager.quest_updated.connect(_on_quest_updated)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quests_loaded.connect(_on_quests_loaded)
	
	# 初始化时刷新所有任务（用于显示已存在的任务）
	refresh_all_quests()

func _process(delta: float) -> void:
	if update_queue.is_empty():
		return
	
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		_process_update_queue()
		update_timer = 0.0

## 处理更新队列（批量更新，去重）
func _process_update_queue() -> void:
	if update_queue.is_empty():
		return
	
	# 去重（使用字典）
	var unique_quests: Dictionary[Quest, bool] = {}
	for quest in update_queue:
		unique_quests[quest] = true
	
	# 批量更新
	for quest in unique_quests.keys():
		_update_quest_entry(quest)
	
	# 清空队列
	update_queue.clear()

## 更新任务条目（实际更新逻辑）
func _update_quest_entry(quest: Quest) -> void:
	var entry: QuestEntry = quest_entries.get(quest, null)
	if entry:
		entry.update_display(_get_quest_text(quest), quest.description)

func _get_quest_text(quest: Quest) -> String:
	var txt = quest.title + " " + _get_quest_status_text(quest) + "\n"
	for obj in quest.objectives:
		txt += "- " + obj.get_progress_text() + "\n"
	return txt

func _get_quest_status_text(quest: Quest) -> String:
	var status = QuestManager.get_quest_status(quest.id)
	match status:
		QuestStatus.UNAVAILABLE:
			return "未接取"
		QuestStatus.IN_PROGRESS:
			return "进行中"
		QuestStatus.READY_TO_TURN_IN:
			return "可交付"
		QuestStatus.FINISHED:
			return "已完成"
	return ""

## 刷新所有任务显示（用于加载存档后更新UI）
func refresh_all_quests() -> void:
	# 清空现有条目
	for child in quest_container.get_children():
		child.queue_free()
	quest_entries.clear()
	
	# 重新添加所有活跃任务
	for quest in QuestManager.active_quests:
		_on_quest_accepted(quest)

func _on_quest_accepted(quest: Quest) -> void:
	var entry : QuestEntry = QUEST_ENTRY.instantiate()
	quest_container.add_child(entry)
	entry.update_display(_get_quest_text(quest), quest.description)
	quest_entries[quest] = entry

func _on_quest_updated(quest: Quest) -> void:
	# 加入更新队列（批量更新）
	update_queue.append(quest)

func _on_quest_completed(quest: Quest) -> void:
	var entry : QuestEntry = quest_entries.get(quest, null)
	if entry:
		entry.update_display(_get_quest_text(quest), quest.description)
		entry.disabled = true

## 任务加载完成时调用（由信号触发）
func _on_quests_loaded() -> void:
	refresh_all_quests()
