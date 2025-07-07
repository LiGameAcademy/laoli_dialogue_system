extends CanvasLayer

# 使用@onready，确保在访问时节点已经准备就绪
@onready var name_label: Label = %NameLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var dialogue_panel: Panel = %Panel

func _ready() -> void:
	# 游戏开始时，订阅DialogueManager的信号
	# 这是全局的，所以可以直接用名字访问
	DialogueManager.text_updated.connect(_on_text_updated)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.choices_updated.connect(_on_choices_updated)

	# 默认隐藏自己
	dialogue_panel.hide()

# 处理线性对话的“继续”逻辑
func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_accept"):
		# 确保对话正在进行，且当前没有选项需要玩家选择
		if not DialogueManager.is_active or choices_container.get_child_count() > 0:
			return

		var current_node_data = DialogueManager.dialogue_data[DialogueManager.current_node_id]
		# 如果当前对话有 "next_node"，则继续
		if current_node_data.has("next_node"):
			DialogueManager._process_node(current_node_data["next_node"])
		# 避免重复触发
		get_viewport().set_input_as_handled()

# 当收到"text_updated"信号时，这个函数会被自动调用
func _on_text_updated(character_name: String, text: String) -> void:
	dialogue_panel.show()
	name_label.text = character_name
	text_label.text = text

# 当收到"dialogue_finished"信号时，这个函数会被自动调用
func _on_dialogue_finished() -> void:
	dialogue_panel.hide()
	# 同样清空可能残留的选项
	for child in choices_container.get_children():
		child.queue_free()

# 当收到选项数据时，动态创建按钮
func _on_choices_updated(choices: Array) -> void:
	for choice_data in choices:
		var button = Button.new()
		button.text = choice_data["text"]
		# 这是最关键的一步：
		# 我们将按钮的 "pressed" 信号连接到一个处理函数，
		# 并使用 .bind() 方法，将该选项的完整数据(choice_data)作为参数传递过去。
		button.pressed.connect(_on_choice_pressed.bind(choice_data))
		choices_container.add_child(button)

# 当玩家点击某个选项按钮时
func _on_choice_pressed(choice_data: Dictionary) -> void:
	# 清空所有选项按钮，防止重复点击
	for child in choices_container.get_children():
		child.queue_free()
	# 通知 DialogueManager，玩家做出了选择
	DialogueManager.make_choice(choice_data)
