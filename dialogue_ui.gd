extends CanvasLayer

# 使用@onready，确保在访问时节点已经准备就绪
@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var dialogue_panel: Panel = $Panel

func _ready():
	# 游戏开始时，订阅DialogueManager的信号
	# 这是全局的，所以可以直接用名字访问
	DialogueManager.text_updated.connect(on_text_updated)
	DialogueManager.dialogue_finished.connect(on_dialogue_finished)
	
	# 默认隐藏自己
	dialogue_panel.hide()

# 当收到"text_updated"信号时，这个函数会被自动调用
func on_text_updated(character_name, text):
	dialogue_panel.show()
	name_label.text = character_name
	text_label.text = text

# 当收到"dialogue_finished"信号时，这个函数会被自动调用
func on_dialogue_finished():
	dialogue_panel.hide()
